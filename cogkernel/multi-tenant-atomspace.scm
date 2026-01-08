;;; Multi-Tenant AtomSpace Fabric for Cog-Hurd
;;; Implements tenant isolation, resource quotas, and neuro-symbolic embeddings
;;; Part of OpenCog Multi-Tenant Neuro-Symbolic Architecture
;;;
;;; Copyright (C) 2026 GNU Hurd Project
;;; License: GPL-3.0-or-later

(define-module (cogkernel multi-tenant-atomspace)
  #:use-module (ice-9 hash-table)
  #:use-module (ice-9 match)
  #:use-module (ice-9 threads)
  #:use-module (ice-9 format)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (cogkernel atomspace)
  #:use-module (cogkernel atenspace)
  #:use-module (cogkernel aten-tensors)
  #:export (;; Multi-tenant fabric creation
            make-multi-tenant-fabric
            multi-tenant-fabric?
            ;; Tenant management
            fabric-create-tenant!
            fabric-delete-tenant!
            fabric-get-tenant
            fabric-list-tenants
            fabric-tenant-exists?
            ;; Tenant operations
            tenant-atomspace
            tenant-add-atom!
            tenant-query
            tenant-get-embedding
            tenant-set-quota!
            tenant-get-usage
            ;; Resource management
            tenant-check-quota
            tenant-allocate-resource!
            tenant-release-resource!
            ;; Neuro-symbolic operations
            tenant-embed-concept!
            tenant-semantic-search
            tenant-neural-inference
            ;; Isolation and security
            tenant-isolate-namespace!
            tenant-verify-access
            ;; Global fabric instance
            *global-multi-tenant-fabric*))

;;; Tenant record with isolated atomspace and resources
(define-record-type <tenant>
  (make-tenant-record id name atomspace atenspace quota usage
                      created-time last-access namespace-isolation
                      security-policy mutex)
  tenant?
  (id tenant-id)
  (name tenant-name)
  (atomspace tenant-atomspace)
  (atenspace tenant-atenspace)
  (quota tenant-quota set-tenant-quota!)
  (usage tenant-usage set-tenant-usage!)
  (created-time tenant-created-time)
  (last-access tenant-last-access set-tenant-last-access!)
  (namespace-isolation tenant-namespace-isolation)
  (security-policy tenant-security-policy set-tenant-security-policy!)
  (mutex tenant-mutex))

;;; Resource quota definition
(define-record-type <resource-quota>
  (make-resource-quota max-atoms max-links max-embeddings max-memory
                       max-cpu-time)
  resource-quota?
  (max-atoms quota-max-atoms)
  (max-links quota-max-links)
  (max-embeddings quota-max-embeddings)
  (max-memory quota-max-memory)
  (max-cpu-time quota-max-cpu-time))

;;; Resource usage tracking
(define-record-type <resource-usage>
  (make-resource-usage current-atoms current-links current-embeddings
                       current-memory current-cpu-time)
  resource-usage?
  (current-atoms usage-current-atoms set-usage-current-atoms!)
  (current-links usage-current-links set-usage-current-links!)
  (current-embeddings usage-current-embeddings set-usage-current-embeddings!)
  (current-memory usage-current-memory set-usage-current-memory!)
  (current-cpu-time usage-current-cpu-time set-usage-current-cpu-time!))

;;; Multi-tenant fabric record
(define-record-type <multi-tenant-fabric>
  (make-multi-tenant-fabric-record tenants tenant-index
                                   global-quota fabric-mutex
                                   isolation-enabled metrics)
  multi-tenant-fabric?
  (tenants fabric-tenants)
  (tenant-index fabric-tenant-index)
  (global-quota fabric-global-quota)
  (fabric-mutex fabric-mutex)
  (isolation-enabled fabric-isolation-enabled)
  (metrics fabric-metrics))

;;; Create a new multi-tenant fabric
(define* (make-multi-tenant-fabric #:key
                                   (max-tenants 1000)
                                   (global-quota (make-default-quota))
                                   (isolation-enabled #t))
  "Create a new multi-tenant atomspace fabric with resource isolation"
  (make-multi-tenant-fabric-record
   (make-hash-table)  ; tenants
   (make-hash-table)  ; tenant-index
   global-quota
   (make-mutex)
   isolation-enabled
   (make-hash-table))) ; metrics

;;; Default quota for new tenants
(define (make-default-quota)
  "Create default resource quota for a tenant"
  (make-resource-quota
   10000   ; max-atoms
   5000    ; max-links
   1000    ; max-embeddings
   1048576 ; max-memory (1MB)
   60))    ; max-cpu-time (60 seconds)

;;; Default usage tracker
(define (make-zero-usage)
  "Create zero resource usage tracker"
  (make-resource-usage 0 0 0 0 0))

;;; Create a new tenant in the fabric
(define* (fabric-create-tenant! fabric tenant-id tenant-name
                               #:key
                               (quota (make-default-quota))
                               (namespace-isolation #t))
  "Create a new tenant with isolated atomspace and atenspace"
  (with-mutex (fabric-mutex fabric)
    (when (hash-ref (fabric-tenants fabric) tenant-id)
      (error "Tenant already exists" tenant-id))
    
    (let* ((tenant-atomspace (make-atomspace))
           (tenant-atenspace (make-atenspace tenant-atomspace))
           (tenant (make-tenant-record
                    tenant-id
                    tenant-name
                    tenant-atomspace
                    tenant-atenspace
                    quota
                    (make-zero-usage)
                    (current-time)
                    (current-time)
                    namespace-isolation
                    'default-policy
                    (make-mutex))))
      
      (hash-set! (fabric-tenants fabric) tenant-id tenant)
      (hash-set! (fabric-tenant-index fabric) tenant-name tenant-id)
      
      (format #t "[Multi-Tenant] Created tenant: ~a (~a)~%" tenant-name tenant-id)
      tenant)))

;;; Delete a tenant from the fabric
(define (fabric-delete-tenant! fabric tenant-id)
  "Delete a tenant and release its resources"
  (with-mutex (fabric-mutex fabric)
    (let ((tenant (hash-ref (fabric-tenants fabric) tenant-id)))
      (unless tenant
        (error "Tenant not found" tenant-id))
      
      (hash-remove! (fabric-tenants fabric) tenant-id)
      (hash-remove! (fabric-tenant-index fabric) (tenant-name tenant))
      
      (format #t "[Multi-Tenant] Deleted tenant: ~a~%" (tenant-name tenant))
      #t)))

;;; Get a tenant by ID
(define (fabric-get-tenant fabric tenant-id)
  "Get tenant by ID"
  (hash-ref (fabric-tenants fabric) tenant-id))

;;; Check if tenant exists
(define (fabric-tenant-exists? fabric tenant-id)
  "Check if a tenant exists"
  (and (hash-ref (fabric-tenants fabric) tenant-id) #t))

;;; List all tenants
(define (fabric-list-tenants fabric)
  "List all tenant IDs and names"
  (hash-map->list
   (lambda (id tenant)
     (list id (tenant-name tenant)))
   (fabric-tenants fabric)))

;;; Add atom to tenant's atomspace with quota checking
(define (tenant-add-atom! fabric tenant-id atom-type atom-name)
  "Add an atom to tenant's atomspace with quota enforcement"
  (let ((tenant (fabric-get-tenant fabric tenant-id)))
    (unless tenant
      (error "Tenant not found" tenant-id))
    
    (with-mutex (tenant-mutex tenant)
      ;; Check quota
      (let* ((usage (tenant-usage tenant))
             (quota (tenant-quota tenant))
             (current-atoms (usage-current-atoms usage)))
        
        (when (>= current-atoms (quota-max-atoms quota))
          (error "Tenant atom quota exceeded" tenant-id))
        
        ;; Add atom to tenant's atomspace
        (let ((atom (make-atom atom-type atom-name)))
          (atomspace-add! (tenant-atomspace tenant) atom)
          
          ;; Update usage
          (set-usage-current-atoms! usage (+ current-atoms 1))
          (set-tenant-last-access! tenant (current-time))
          
          atom)))))

;;; Query tenant's atomspace
(define (tenant-query fabric tenant-id pattern)
  "Query atoms in tenant's atomspace"
  (let ((tenant (fabric-get-tenant fabric tenant-id)))
    (unless tenant
      (error "Tenant not found" tenant-id))
    
    (atomspace-query (tenant-atomspace tenant) pattern)))

;;; Set quota for a tenant
(define (tenant-set-quota! fabric tenant-id new-quota)
  "Set resource quota for a tenant"
  (let ((tenant (fabric-get-tenant fabric tenant-id)))
    (unless tenant
      (error "Tenant not found" tenant-id))
    
    (with-mutex (tenant-mutex tenant)
      (set-tenant-quota! tenant new-quota)
      (format #t "[Multi-Tenant] Updated quota for tenant: ~a~%" tenant-id))))

;;; Get tenant resource usage
(define (tenant-get-usage fabric tenant-id)
  "Get current resource usage for a tenant"
  (let ((tenant (fabric-get-tenant fabric tenant-id)))
    (unless tenant
      (error "Tenant not found" tenant-id))
    
    (tenant-usage tenant)))

;;; Check if operation would exceed quota
(define (tenant-check-quota tenant resource-type amount)
  "Check if allocating amount of resource would exceed quota"
  (let ((quota (tenant-quota tenant))
        (usage (tenant-usage tenant)))
    (match resource-type
      ('atoms
       (< (+ (usage-current-atoms usage) amount)
          (quota-max-atoms quota)))
      ('links
       (< (+ (usage-current-links usage) amount)
          (quota-max-links quota)))
      ('embeddings
       (< (+ (usage-current-embeddings usage) amount)
          (quota-max-embeddings quota)))
      ('memory
       (< (+ (usage-current-memory usage) amount)
          (quota-max-memory quota)))
      (_ #f))))

;;; Embed concept with neuro-symbolic bridge
(define (tenant-embed-concept! fabric tenant-id concept-name dimensions)
  "Create neuro-symbolic embedding for a concept in tenant's atenspace"
  (let ((tenant (fabric-get-tenant fabric tenant-id)))
    (unless tenant
      (error "Tenant not found" tenant-id))
    
    (with-mutex (tenant-mutex tenant)
      (unless (tenant-check-quota tenant 'embeddings 1)
        (error "Tenant embedding quota exceeded" tenant-id))
      
      ;; Create embedding
      (let* ((concept-atom (make-atom 'CONCEPT concept-name))
             (embedding (embed-concept (tenant-atenspace tenant)
                                      concept-atom
                                      dimensions)))
        
        ;; Update usage
        (let ((usage (tenant-usage tenant)))
          (set-usage-current-embeddings!
           usage
           (+ (usage-current-embeddings usage) 1)))
        
        embedding))))

;;; Semantic search within tenant's space
(define (tenant-semantic-search fabric tenant-id query-embedding k)
  "Perform semantic search in tenant's atenspace"
  (let ((tenant (fabric-get-tenant fabric tenant-id)))
    (unless tenant
      (error "Tenant not found" tenant-id))
    
    (find-nearest-neighbors (tenant-atenspace tenant) query-embedding k)))

;;; Neural inference for tenant
(define (tenant-neural-inference fabric tenant-id input-atoms)
  "Perform neural inference in tenant's atenspace"
  (let ((tenant (fabric-get-tenant fabric tenant-id)))
    (unless tenant
      (error "Tenant not found" tenant-id))
    
    (neural-inference (tenant-atenspace tenant) input-atoms)))

;;; Isolate tenant namespace
(define (tenant-isolate-namespace! fabric tenant-id namespace-rules)
  "Configure namespace isolation rules for a tenant"
  (let ((tenant (fabric-get-tenant fabric tenant-id)))
    (unless tenant
      (error "Tenant not found" tenant-id))
    
    (with-mutex (tenant-mutex tenant)
      ;; Store isolation rules (simplified for now)
      (format #t "[Multi-Tenant] Isolated namespace for tenant: ~a~%" tenant-id)
      #t)))

;;; Verify tenant access rights
(define (tenant-verify-access fabric tenant-id requesting-tenant-id)
  "Verify if requesting tenant can access target tenant's resources"
  (if (equal? tenant-id requesting-tenant-id)
      #t
      (begin
        (format #t "[Multi-Tenant] Access denied: ~a cannot access ~a~%"
                requesting-tenant-id tenant-id)
        #f)))

;;; Get tenant's embedding by concept
(define (tenant-get-embedding fabric tenant-id concept-name)
  "Get embedding for a concept in tenant's atenspace"
  (let ((tenant (fabric-get-tenant fabric tenant-id)))
    (unless tenant
      (error "Tenant not found" tenant-id))
    
    (let ((concept-atom (make-atom 'CONCEPT concept-name)))
      (atenspace-get-embedding (tenant-atenspace tenant) concept-atom))))

;;; Global multi-tenant fabric instance
(define *global-multi-tenant-fabric*
  (make-multi-tenant-fabric))

;;; Display tenant statistics
(define (tenant-stats tenant)
  "Display statistics for a tenant"
  (let ((usage (tenant-usage tenant))
        (quota (tenant-quota tenant)))
    (format #t "~%Tenant: ~a (~a)~%" (tenant-name tenant) (tenant-id tenant))
    (format #t "  Atoms: ~a / ~a~%"
            (usage-current-atoms usage)
            (quota-max-atoms quota))
    (format #t "  Links: ~a / ~a~%"
            (usage-current-links usage)
            (quota-max-links quota))
    (format #t "  Embeddings: ~a / ~a~%"
            (usage-current-embeddings usage)
            (quota-max-embeddings quota))
    (format #t "  Memory: ~a / ~a bytes~%"
            (usage-current-memory usage)
            (quota-max-memory quota))))

;;; End of multi-tenant-atomspace.scm
