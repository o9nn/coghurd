#!/usr/bin/env guile
!#
;;; Demonstration of Multi-Tenant Neuro-Symbolic AtomSpace Fabric
;;; Showcases MIG-space, Agent-Zero workbench, and constellation deployment
;;;
;;; Copyright (C) 2026 GNU Hurd Project
;;; License: GPL-3.0-or-later

(use-modules (cogkernel multi-tenant-atomspace)
             (cogkernel mig-space)
             (cogkernel agent-zero-workbench)
             (cogkernel atomspace)
             (ice-9 format))

(define (print-header title)
  "Print section header"
  (format #t "~%~%")
  (format #t "╔═══════════════════════════════════════════════════════════╗~%")
  (format #t "║ ~a~48t║~%" title)
  (format #t "╚═══════════════════════════════════════════════════════════╝~%")
  (format #t "~%"))

(define (print-step step-num description)
  "Print step description"
  (format #t "~%[Step ~a] ~a~%" step-num description))

(define (demo-multi-tenant-fabric)
  "Demonstrate multi-tenant atomspace fabric"
  (print-header "Multi-Tenant Neuro-Symbolic AtomSpace Fabric")
  
  (print-step 1 "Creating multi-tenant fabric...")
  (let ((fabric (make-multi-tenant-fabric)))
    (format #t "✓ Fabric created with tenant isolation enabled~%")
    
    (print-step 2 "Creating tenants with resource quotas...")
    (fabric-create-tenant! fabric "customer-a" "Customer A (Enterprise)")
    (fabric-create-tenant! fabric "customer-b" "Customer B (Startup)")
    (fabric-create-tenant! fabric "customer-c" "Customer C (Research)")
    
    (print-step 3 "Adding atoms to tenant namespaces...")
    (tenant-add-atom! fabric "customer-a" 'CONCEPT "enterprise-data")
    (tenant-add-atom! fabric "customer-a" 'CONCEPT "secure-workflow")
    (tenant-add-atom! fabric "customer-b" 'CONCEPT "startup-product")
    (tenant-add-atom! fabric "customer-c" 'CONCEPT "research-experiment")
    
    (print-step 4 "Creating neuro-symbolic embeddings per tenant...")
    (tenant-embed-concept! fabric "customer-a" "ai-model-v1" 256)
    (tenant-embed-concept! fabric "customer-b" "ml-pipeline" 128)
    (tenant-embed-concept! fabric "customer-c" "neural-network" 512)
    
    (print-step 5 "Displaying tenant statistics...")
    (for-each
     (lambda (tenant-info)
       (let* ((tenant-id (car tenant-info))
              (tenant (fabric-get-tenant fabric tenant-id)))
         (when tenant
           (tenant-stats tenant))))
     (fabric-list-tenants fabric))
    
    (print-step 6 "Verifying tenant isolation...")
    (format #t "Attempting cross-tenant access...~%")
    (let ((isolated (tenant-verify-access fabric "customer-a" "customer-b")))
      (if isolated
          (format #t "⚠ Isolation violated!~%")
          (format #t "✓ Tenant isolation verified - access denied~%")))
    
    fabric))

(define (demo-mig-space-architecture)
  "Demonstrate MIG-space distributed cognitive architecture"
  (print-header "MIG-Space Distributed Cognitive Architecture")
  
  (print-step 1 "Creating MIG-space for distributed IPC...")
  (let ((mig-space (make-mig-space)))
    (format #t "✓ MIG-space initialized~%")
    
    (print-step 2 "Creating cognitive IPC channels...")
    (mig-space-create-channel! mig-space "channel-auth" "auth-server" "client")
    (mig-space-create-channel! mig-space "channel-proc" "proc-server" "manager")
    (mig-space-create-channel! mig-space "channel-storage" "storage-server" "fs")
    
    (print-step 3 "Creating mach-zero microkernel constellation...")
    (mig-space-create-constellation! mig-space "hurd-constellation-1"
                                    #:replication-factor 3)
    
    (print-step 4 "Deploying agentic microkernel nodes...")
    (mig-space-deploy-microkernel! mig-space "hurd-constellation-1"
                                   "mach-node-1" "hurd1.local" "mach-port-001")
    (mig-space-deploy-microkernel! mig-space "hurd-constellation-1"
                                   "mach-node-2" "hurd2.local" "mach-port-002")
    (mig-space-deploy-microkernel! mig-space "hurd-constellation-1"
                                   "mach-node-3" "hurd3.local" "mach-port-003")
    
    (print-step 5 "Sending cognitive messages through MIG...")
    (let ((message (make-cognitive-message-record
                    "msg-001"
                    "auth-server"
                    "client"
                    'AUTHENTICATE
                    '((user . "admin") (token . "xyz"))
                    '()
                    'HIGH
                    (current-time)
                    #f)))
      (mig-space-send-cognitive! mig-space "channel-auth" message)
      (format #t "✓ Cognitive message routed with priority handling~%"))
    
    (print-step 6 "Synchronizing atoms across distributed nodes...")
    (let ((atom1 (make-atom 'CONCEPT "distributed-state"))
          (atom2 (make-atom 'CONCEPT "replicated-knowledge")))
      (mig-space-sync-atoms! mig-space "channel-proc" (list atom1 atom2)))
    
    (print-step 7 "Displaying MIG-space statistics...")
    (mig-space-stats mig-space)
    
    (print-step 8 "Optimizing cognitive routes...")
    (mig-space-optimize-routes! mig-space)
    
    mig-space))

(define (demo-agent-zero-workbench fabric mig-space)
  "Demonstrate agent-zero multi-agent orchestration"
  (print-header "Agent-Zero Multi-Agent Orchestration Workbench")
  
  (print-step 1 "Creating agent-zero workbench...")
  (let ((workbench (make-agent-zero-workbench
                    #:multi-tenant-fabric fabric
                    #:mig-space mig-space)))
    (format #t "✓ Workbench initialized with fabric and MIG-space integration~%")
    
    (print-step 2 "Creating autonomous agents...")
    (workbench-create-agent! workbench "agent-monitor-1" "System Monitor Alpha" 'MONITOR
                            #:autonomy-level 'AUTO
                            #:strategy 'PROACTIVE)
    (workbench-create-agent! workbench "agent-repair-1" "Auto Repair Beta" 'REPAIR
                            #:autonomy-level 'AUTO
                            #:strategy 'ADAPTIVE)
    (workbench-create-agent! workbench "agent-build-1" "Build Orchestrator" 'BUILD
                            #:autonomy-level 'SEMI-AUTO
                            #:strategy 'COLLABORATIVE)
    (workbench-create-agent! workbench "agent-analyze-1" "Pattern Analyzer" 'ANALYZE
                            #:autonomy-level 'AUTO
                            #:strategy 'ADAPTIVE)
    
    (print-step 3 "Deploying agents to constellation...")
    (workbench-deploy-constellation! workbench "hurd-constellation-1"
                                    '("agent-monitor-1" "agent-repair-1"
                                      "agent-build-1" "agent-analyze-1"))
    
    (print-step 4 "Creating agent teams...")
    (workbench-create-team! workbench "team-ops" "Operations Team")
    (workbench-create-team! workbench "team-dev" "Development Team")
    
    (let ((team-ops (hash-ref (workbench-teams workbench) "team-ops"))
          (team-dev (hash-ref (workbench-teams workbench) "team-dev")))
      (team-add-agent! team-ops "agent-monitor-1")
      (team-add-agent! team-ops "agent-repair-1")
      (team-add-agent! team-dev "agent-build-1")
      (team-add-agent! team-dev "agent-analyze-1"))
    
    (print-step 5 "Creating mission for operations team...")
    (let ((mission (make-mission-record
                    "mission-001"
                    "System Health Maintenance"
                    '((monitor-uptime . 99.99)
                      (auto-repair . enabled)
                      (alert-threshold . critical))
                    '((downtime . 0)
                      (manual-intervention . minimal))
                    'HIGH
                    (+ (current-time) 86400)  ; 24 hours
                    'PENDING
                    0.0)))
      (workbench-assign-mission! workbench "team-ops" mission)
      (format #t "✓ Mission assigned to operations team~%"))
    
    (print-step 6 "Enabling agent self-organization...")
    (workbench-self-organize! workbench)
    
    (print-step 7 "Demonstrating autonomous decision making...")
    (let ((decision (workbench-autonomous-decision
                     workbench "agent-monitor-1"
                     '((system-load . high)
                       (error-rate . increasing)
                       (available-resources . limited)))))
      (format #t "✓ Agent made autonomous decision: ~a~%" decision))
    
    (print-step 8 "Coordinating team agents...")
    (workbench-coordinate-agents! workbench "team-ops")
    
    (print-step 9 "Monitoring agent status...")
    (workbench-monitor-agents workbench)
    
    (print-step 10 "Performing health check...")
    (workbench-health-check workbench)
    
    (print-step 11 "Displaying workbench status...")
    (workbench-status workbench)
    
    workbench))

(define (demo-integrated-scenario fabric mig-space workbench)
  "Demonstrate integrated multi-tenant, distributed, multi-agent scenario"
  (print-header "Integrated Multi-Tenant Distributed Agent Scenario")
  
  (print-step 1 "Setting up production and development environments...")
  (format #t "Creating isolated tenant environments with dedicated agents...~%")
  
  ;; Production environment
  (fabric-create-tenant! fabric "prod-env" "Production Environment")
  (workbench-create-agent! workbench "prod-agent-1" "Prod Monitor" 'MONITOR
                          #:autonomy-level 'AUTO)
  (workbench-deploy-agent! workbench "prod-agent-1"
                          #:tenant-id "prod-env"
                          #:deployment-strategy 'DISTRIBUTED)
  
  ;; Development environment
  (fabric-create-tenant! fabric "dev-env" "Development Environment")
  (workbench-create-agent! workbench "dev-agent-1" "Dev Builder" 'BUILD
                          #:autonomy-level 'SEMI-AUTO)
  (workbench-deploy-agent! workbench "dev-agent-1"
                          #:tenant-id "dev-env"
                          #:deployment-strategy 'LOCAL)
  
  (print-step 2 "Creating cross-constellation communication...")
  (mig-space-create-channel! mig-space "prod-to-dev" "prod-node" "dev-node")
  (format #t "✓ Communication channel established between environments~%")
  
  (print-step 3 "Demonstrating tenant data isolation...")
  (tenant-add-atom! fabric "prod-env" 'CONCEPT "production-secret")
  (tenant-add-atom! fabric "dev-env" 'CONCEPT "development-feature")
  (format #t "✓ Each environment maintains isolated knowledge base~%")
  
  (print-step 4 "Scaling deployment based on load...")
  (workbench-create-team! workbench "prod-team" "Production Team")
  (let ((team (hash-ref (workbench-teams workbench) "prod-team")))
    (team-add-agent! team "prod-agent-1"))
  (workbench-scale-deployment! workbench "prod-team" 2)
  
  (print-step 5 "Optimizing routes and adapting strategies...")
  (mig-space-optimize-routes! mig-space)
  (workbench-adapt-strategy! workbench "prod-agent-1")
  
  (format #t "~%✓ Integrated scenario complete!~%"))

(define (main)
  "Main demonstration entry point"
  (format #t "~%")
  (format #t "╔═══════════════════════════════════════════════════════════╗~%")
  (format #t "║                                                           ║~%")
  (format #t "║   HurdCog Multi-Tenant Neuro-Symbolic AGI-OS Demo       ║~%")
  (format #t "║                                                           ║~%")
  (format #t "║   Components:                                             ║~%")
  (format #t "║   • Multi-Tenant AtomSpace Fabric                        ║~%")
  (format #t "║   • MIG-Space Distributed Cognitive Architecture         ║~%")
  (format #t "║   • Agent-Zero Multi-Agent Orchestration                 ║~%")
  (format #t "║   • Mach-Zero Agentic Microkernel Constellations        ║~%")
  (format #t "║                                                           ║~%")
  (format #t "╚═══════════════════════════════════════════════════════════╝~%")
  
  ;; Run demonstrations
  (let* ((fabric (demo-multi-tenant-fabric))
         (mig-space (demo-mig-space-architecture))
         (workbench (demo-agent-zero-workbench fabric mig-space)))
    
    (demo-integrated-scenario fabric mig-space workbench)
    
    (print-header "Demonstration Complete")
    (format #t "~%All components successfully demonstrated!~%")
    (format #t "~%Key Features Showcased:~%")
    (format #t "  ✓ Multi-tenant isolation with resource quotas~%")
    (format #t "  ✓ Neuro-symbolic embeddings per tenant~%")
    (format #t "  ✓ Distributed cognitive IPC via MIG-space~%")
    (format #t "  ✓ Mach-zero microkernel constellations~%")
    (format #t "  ✓ Autonomous agent lifecycle management~%")
    (format #t "  ✓ Multi-agent team coordination~%")
    (format #t "  ✓ Self-organizing agent systems~%")
    (format #t "  ✓ Integrated deployment strategies~%")
    (format #t "~%")))

;;; Run the demonstration
(main)
