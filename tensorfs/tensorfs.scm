;;; TensorFS - Multi-Entity & Multi-Scale Network-Aware Tensor-Enhanced Hurd FileSystem
;;; Combines AtomSpace hypergraph with ATen tensor embeddings for intelligent file management
;;;
;;; Copyright (C) 2025 GNU Hurd Project
;;; License: GPL-3.0-or-later
;;;
;;; Architecture:
;;; - Files and directories are represented as nodes in AtomSpace
;;; - Each node has tensor embeddings for semantic search
;;; - Multi-scale representation enables coarse-to-fine navigation
;;; - Network-aware operations support distributed filesystems
;;; - Attention mechanisms prioritize frequently accessed content

(define-module (tensorfs tensorfs)
  #:use-module (ice-9 hash-table)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-19)
  #:use-module (cogkernel atomspace)
  #:use-module (cogkernel aten-tensors)
  #:use-module (cogkernel atenspace)
  #:export (;; TensorFS creation
            make-tensorfs
            tensorfs?
            tensorfs-root
            tensorfs-atenspace
            ;; File system operations
            tensorfs-create-file!
            tensorfs-create-directory!
            tensorfs-read-file
            tensorfs-write-file!
            tensorfs-delete!
            tensorfs-list-directory
            tensorfs-stat
            tensorfs-exists?
            ;; Semantic operations
            tensorfs-semantic-search
            tensorfs-find-similar
            tensorfs-embed-content!
            tensorfs-auto-tag!
            ;; Multi-scale operations
            tensorfs-browse-scale
            tensorfs-zoom-in
            tensorfs-zoom-out
            tensorfs-hierarchical-view
            ;; Multi-entity operations
            tensorfs-share-with-entity!
            tensorfs-entity-permissions
            tensorfs-collaborative-edit!
            tensorfs-entity-activity
            ;; Network-aware operations
            tensorfs-replicate!
            tensorfs-sync-remote!
            tensorfs-partition-locate
            tensorfs-distributed-search
            ;; Attention operations
            tensorfs-boost-attention!
            tensorfs-decay-attention!
            tensorfs-attention-ranked-list
            tensorfs-prefetch-predicted
            ;; Cognitive operations
            tensorfs-reason-about
            tensorfs-infer-relationships
            tensorfs-suggest-organization))

;;; ---------- Data Structures ----------

;;; TensorFS node types
(define tensorfs-node-types '(FILE DIRECTORY SYMLINK DEVICE SOCKET))

;;; File node record
(define-record-type <tensorfs-node>
  (make-tensorfs-node-record type name path content
                             embedding attention metadata
                             parent children
                             entity-permissions scale-level)
  tensorfs-node?
  (type tensorfs-node-type)
  (name tensorfs-node-name)
  (path tensorfs-node-path)
  (content tensorfs-node-content tensorfs-node-set-content!)
  (embedding tensorfs-node-embedding tensorfs-node-set-embedding!)
  (attention tensorfs-node-attention tensorfs-node-set-attention!)
  (metadata tensorfs-node-metadata tensorfs-node-set-metadata!)
  (parent tensorfs-node-parent tensorfs-node-set-parent!)
  (children tensorfs-node-children tensorfs-node-set-children!)
  (entity-permissions tensorfs-node-entity-permissions tensorfs-node-set-entity-permissions!)
  (scale-level tensorfs-node-scale-level))

;;; TensorFS root record
(define-record-type <tensorfs>
  (make-tensorfs-record root atenspace node-index
                        attention-heap scale-tree
                        entity-registry network-topology)
  tensorfs?
  (root tensorfs-root)
  (atenspace tensorfs-atenspace)
  (node-index tensorfs-node-index)      ; path -> node hash
  (attention-heap tensorfs-attention-heap)  ; priority queue for attention
  (scale-tree tensorfs-scale-tree)      ; multi-scale tree representation
  (entity-registry tensorfs-entity-registry)  ; entity -> permissions
  (network-topology tensorfs-network-topology))  ; network partition info

;;; ---------- TensorFS Creation ----------

(define* (make-tensorfs #:key
                        (embedding-dim 128)
                        (num-scales 4)
                        (partition-id 0))
  "Create a new TensorFS instance"
  (let* ((atenspace (make-atenspace #:embedding-dim embedding-dim
                                    #:num-scales num-scales))
         (root-embedding (randn (list embedding-dim)))
         (root-node (make-tensorfs-node-record
                     'DIRECTORY
                     "/"
                     "/"
                     #f                    ; no content for directory
                     root-embedding
                     1.0                   ; max attention for root
                     (make-hash-table)     ; metadata
                     #f                    ; no parent
                     (make-hash-table)     ; children
                     (make-hash-table)     ; entity permissions
                     0)))                  ; scale level 0 (coarsest)
    ;; Add root to atenspace
    (let ((root-atom (make-atom 'NODE "/")))
      (atenspace-add-embedded! atenspace root-atom root-embedding))
    ;; Create tensorfs
    (make-tensorfs-record
     root-node
     atenspace
     (let ((idx (make-hash-table)))
       (hash-set! idx "/" root-node)
       idx)
     (make-hash-table)     ; attention heap
     (make-vector num-scales '())  ; scale tree
     (make-hash-table)     ; entity registry
     (let ((topo (make-hash-table)))
       (hash-set! topo 'partition-id partition-id)
       topo))))

;;; ---------- Path Utilities ----------

(define (path-join parent child)
  "Join parent and child paths"
  (if (string=? parent "/")
      (string-append "/" child)
      (string-append parent "/" child)))

(define (path-parent path)
  "Get parent path"
  (let ((parts (string-split path #\/)))
    (if (<= (length parts) 2)
        "/"
        (string-join (drop-right parts 1) "/"))))

(define (path-basename path)
  "Get basename from path"
  (car (reverse (string-split path #\/))))

;;; ---------- Basic File Operations ----------

(define* (tensorfs-create-file! tfs path #:key
                                (content "")
                                (auto-embed? #t)
                                (embedding-dim 128))
  "Create a new file in TensorFS"
  (let* ((parent-path (path-parent path))
         (parent-node (hash-ref (tensorfs-node-index tfs) parent-path)))
    (unless parent-node
      (error "Parent directory does not exist:" parent-path))
    (unless (eq? (tensorfs-node-type parent-node) 'DIRECTORY)
      (error "Parent is not a directory:" parent-path))
    ;; Create embedding from content if auto-embed
    (let* ((embedding (if auto-embed?
                          (content->embedding content embedding-dim)
                          (randn (list embedding-dim))))
           (name (path-basename path))
           (node (make-tensorfs-node-record
                  'FILE
                  name
                  path
                  content
                  embedding
                  0.5                ; initial attention
                  (let ((meta (make-hash-table)))
                    (hash-set! meta 'created (current-time))
                    (hash-set! meta 'modified (current-time))
                    (hash-set! meta 'size (string-length content))
                    meta)
                  parent-node
                  #f                ; files have no children
                  (make-hash-table)
                  (+ 1 (tensorfs-node-scale-level parent-node)))))
      ;; Add to parent's children
      (hash-set! (tensorfs-node-children parent-node) name node)
      ;; Add to node index
      (hash-set! (tensorfs-node-index tfs) path node)
      ;; Add to atenspace
      (let ((atom (make-atom 'NODE path)))
        (atenspace-add-embedded! (tensorfs-atenspace tfs) atom embedding))
      node)))

(define* (tensorfs-create-directory! tfs path #:key (embedding-dim 128))
  "Create a new directory in TensorFS"
  (let* ((parent-path (path-parent path))
         (parent-node (hash-ref (tensorfs-node-index tfs) parent-path)))
    (unless parent-node
      (error "Parent directory does not exist:" parent-path))
    (let* ((embedding (randn (list embedding-dim)))
           (name (path-basename path))
           (node (make-tensorfs-node-record
                  'DIRECTORY
                  name
                  path
                  #f
                  embedding
                  0.5
                  (let ((meta (make-hash-table)))
                    (hash-set! meta 'created (current-time))
                    meta)
                  parent-node
                  (make-hash-table)
                  (make-hash-table)
                  (+ 1 (tensorfs-node-scale-level parent-node)))))
      ;; Add to parent's children
      (hash-set! (tensorfs-node-children parent-node) name node)
      ;; Add to node index
      (hash-set! (tensorfs-node-index tfs) path node)
      ;; Add to atenspace
      (let ((atom (make-atom 'NODE path)))
        (atenspace-add-embedded! (tensorfs-atenspace tfs) atom embedding))
      node)))

(define (tensorfs-read-file tfs path)
  "Read file content from TensorFS"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "File not found:" path))
    (unless (eq? (tensorfs-node-type node) 'FILE)
      (error "Not a file:" path))
    ;; Boost attention on access
    (tensorfs-boost-attention! tfs path 0.1)
    (tensorfs-node-content node)))

(define* (tensorfs-write-file! tfs path content #:key (auto-embed? #t))
  "Write content to a file in TensorFS"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "File not found:" path))
    (unless (eq? (tensorfs-node-type node) 'FILE)
      (error "Not a file:" path))
    ;; Update content
    (tensorfs-node-set-content! node content)
    ;; Update metadata
    (hash-set! (tensorfs-node-metadata node) 'modified (current-time))
    (hash-set! (tensorfs-node-metadata node) 'size (string-length content))
    ;; Update embedding if auto-embed
    (when auto-embed?
      (let ((new-embedding (content->embedding content
                                               (first (tensor-shape (tensorfs-node-embedding node))))))
        (tensorfs-node-set-embedding! node new-embedding)
        (atenspace-update-embedding! (tensorfs-atenspace tfs) path new-embedding)))
    ;; Boost attention
    (tensorfs-boost-attention! tfs path 0.2)
    node))

(define (tensorfs-delete! tfs path)
  "Delete a file or empty directory from TensorFS"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "Path not found:" path))
    (when (and (eq? (tensorfs-node-type node) 'DIRECTORY)
               (> (hash-count (const #t) (tensorfs-node-children node)) 0))
      (error "Directory not empty:" path))
    ;; Remove from parent
    (let ((parent (tensorfs-node-parent node)))
      (when parent
        (hash-remove! (tensorfs-node-children parent) (tensorfs-node-name node))))
    ;; Remove from index
    (hash-remove! (tensorfs-node-index tfs) path)
    #t))

(define (tensorfs-list-directory tfs path)
  "List contents of a directory"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "Path not found:" path))
    (unless (eq? (tensorfs-node-type node) 'DIRECTORY)
      (error "Not a directory:" path))
    (hash-map->list (lambda (name child)
                      (list name
                            (tensorfs-node-type child)
                            (tensorfs-node-attention child)))
                    (tensorfs-node-children node))))

(define (tensorfs-stat tfs path)
  "Get file/directory statistics"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "Path not found:" path))
    (let ((meta (tensorfs-node-metadata node)))
      `((type . ,(tensorfs-node-type node))
        (name . ,(tensorfs-node-name node))
        (path . ,(tensorfs-node-path node))
        (attention . ,(tensorfs-node-attention node))
        (scale-level . ,(tensorfs-node-scale-level node))
        (created . ,(hash-ref meta 'created))
        (modified . ,(hash-ref meta 'modified))
        (size . ,(or (hash-ref meta 'size) 0))))))

(define (tensorfs-exists? tfs path)
  "Check if path exists in TensorFS"
  (hash-ref (tensorfs-node-index tfs) path))

;;; ---------- Content Embedding ----------

(define (content->embedding content dim)
  "Convert text content to embedding vector"
  ;; Simple bag-of-words style embedding
  (let* ((words (string-split (string-downcase content) char-set:whitespace))
         (embedding (make-vector dim 0.0)))
    ;; Hash words to embedding dimensions
    (for-each (lambda (word)
                (when (> (string-length word) 0)
                  (let ((idx (modulo (string-hash word) dim)))
                    (vector-set! embedding idx
                                 (+ (vector-ref embedding idx) 1.0)))))
              words)
    ;; Normalize
    (let ((norm (sqrt (let loop ((i 0) (sum 0.0))
                        (if (< i dim)
                            (loop (+ i 1) (+ sum (expt (vector-ref embedding i) 2)))
                            sum)))))
      (when (> norm 0)
        (let loop ((i 0))
          (when (< i dim)
            (vector-set! embedding i (/ (vector-ref embedding i) norm))
            (loop (+ i 1))))))
    (make-tensor (list dim) #:data embedding)))

;;; ---------- Semantic Operations ----------

(define* (tensorfs-semantic-search tfs query #:key (k 10) (threshold 0.3))
  "Search files semantically by content similarity"
  (let* ((query-embedding (if (tensor? query)
                              query
                              (content->embedding query 128)))
         (results (query-similar (tensorfs-atenspace tfs)
                                 query-embedding
                                 #:k k
                                 #:threshold threshold)))
    ;; Return file info for results
    (filter-map (lambda (pair)
                  (let ((node (hash-ref (tensorfs-node-index tfs) (car pair))))
                    (and node
                         (list (tensorfs-node-path node)
                               (tensorfs-node-type node)
                               (cdr pair)  ; similarity
                               (tensorfs-node-attention node)))))
                results)))

(define* (tensorfs-find-similar tfs path #:key (k 5))
  "Find files similar to the given file"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "Path not found:" path))
    (let ((embedding (tensorfs-node-embedding node)))
      (filter (lambda (r) (not (string=? (first r) path)))
              (tensorfs-semantic-search tfs embedding #:k (+ k 1))))))

(define (tensorfs-embed-content! tfs path)
  "Re-embed file content (useful after external changes)"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "Path not found:" path))
    (when (eq? (tensorfs-node-type node) 'FILE)
      (let* ((content (tensorfs-node-content node))
             (dim (first (tensor-shape (tensorfs-node-embedding node))))
             (new-embedding (content->embedding content dim)))
        (tensorfs-node-set-embedding! node new-embedding)
        (atenspace-update-embedding! (tensorfs-atenspace tfs) path new-embedding)))))

(define* (tensorfs-auto-tag! tfs path #:key (num-tags 5))
  "Automatically generate tags for a file based on its embedding"
  (let* ((similar (tensorfs-find-similar tfs path #:k 20))
         ;; Extract common words from similar files
         (words (apply append
                       (map (lambda (s)
                              (let ((node (hash-ref (tensorfs-node-index tfs) (first s))))
                                (if (and node (tensorfs-node-content node))
                                    (string-split
                                     (string-downcase (tensorfs-node-content node))
                                     char-set:whitespace)
                                    '())))
                            similar)))
         ;; Count word frequencies
         (word-counts (make-hash-table)))
    (for-each (lambda (w)
                (when (> (string-length w) 3)
                  (hash-set! word-counts w (+ 1 (or (hash-ref word-counts w) 0)))))
              words)
    ;; Return top tags
    (take (sort (hash-map->list cons word-counts)
                (lambda (a b) (> (cdr a) (cdr b))))
          (min num-tags (hash-count (const #t) word-counts)))))

;;; ---------- Multi-Scale Operations ----------

(define (tensorfs-browse-scale tfs scale-level)
  "Browse filesystem at a specific scale level (0=coarsest)"
  (let ((results '()))
    (hash-for-each
     (lambda (path node)
       (when (= (tensorfs-node-scale-level node) scale-level)
         (set! results (cons (list path
                                   (tensorfs-node-type node)
                                   (tensorfs-node-attention node))
                             results))))
     (tensorfs-node-index tfs))
    results))

(define (tensorfs-zoom-in tfs path)
  "Zoom into a directory, showing children at finer scale"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "Path not found:" path))
    (if (eq? (tensorfs-node-type node) 'DIRECTORY)
        (hash-map->list (lambda (name child)
                          (list (tensorfs-node-path child)
                                (tensorfs-node-type child)
                                (tensorfs-node-scale-level child)
                                (tensorfs-node-attention child)))
                        (tensorfs-node-children node))
        (error "Cannot zoom into non-directory:" path))))

(define (tensorfs-zoom-out tfs path)
  "Zoom out to parent directory at coarser scale"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "Path not found:" path))
    (let ((parent (tensorfs-node-parent node)))
      (if parent
          (list (tensorfs-node-path parent)
                (tensorfs-node-type parent)
                (tensorfs-node-scale-level parent))
          (error "Already at root")))))

(define* (tensorfs-hierarchical-view tfs #:key (max-depth 3))
  "Get hierarchical view of filesystem"
  (define (traverse node depth)
    (if (> depth max-depth)
        '()
        (cons (list (make-string (* 2 depth) #\space)
                    (tensorfs-node-name node)
                    (tensorfs-node-type node))
              (if (eq? (tensorfs-node-type node) 'DIRECTORY)
                  (apply append
                         (hash-map->list
                          (lambda (name child)
                            (traverse child (+ depth 1)))
                          (tensorfs-node-children node)))
                  '()))))
  (traverse (tensorfs-root tfs) 0))

;;; ---------- Multi-Entity Operations ----------

(define* (tensorfs-share-with-entity! tfs path entity-id #:key (permissions '(read)))
  "Share a file/directory with another entity"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "Path not found:" path))
    (hash-set! (tensorfs-node-entity-permissions node) entity-id permissions)
    ;; Register entity if new
    (unless (hash-ref (tensorfs-entity-registry tfs) entity-id)
      (hash-set! (tensorfs-entity-registry tfs) entity-id
                 (make-hash-table)))
    ;; Track entity's accessible paths
    (hash-set! (hash-ref (tensorfs-entity-registry tfs) entity-id)
               path permissions)))

(define (tensorfs-entity-permissions tfs path entity-id)
  "Check entity's permissions on a path"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (if node
        (or (hash-ref (tensorfs-node-entity-permissions node) entity-id)
            '())
        '())))

(define* (tensorfs-collaborative-edit! tfs path entity-id content
                                       #:key (merge-strategy 'append))
  "Allow collaborative editing with conflict resolution"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "Path not found:" path))
    (let ((perms (tensorfs-entity-permissions tfs path entity-id)))
      (unless (member 'write perms)
        (error "Entity lacks write permission:" entity-id))
      ;; Apply merge strategy
      (let ((current (tensorfs-node-content node)))
        (case merge-strategy
          ((append) (tensorfs-write-file! tfs path
                                          (string-append current "\n" content)))
          ((replace) (tensorfs-write-file! tfs path content))
          ((merge) (tensorfs-write-file! tfs path
                                         (string-append current "\n---\n" content)))
          (else (error "Unknown merge strategy:" merge-strategy)))))))

(define (tensorfs-entity-activity tfs entity-id)
  "Get list of paths accessible to an entity"
  (let ((entity-paths (hash-ref (tensorfs-entity-registry tfs) entity-id)))
    (if entity-paths
        (hash-map->list cons entity-paths)
        '())))

;;; ---------- Network-Aware Operations ----------

(define* (tensorfs-replicate! tfs path target-partition)
  "Mark file for replication to another partition"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "Path not found:" path))
    (let ((replicas (or (hash-ref (tensorfs-node-metadata node) 'replicas)
                        '())))
      (hash-set! (tensorfs-node-metadata node) 'replicas
                 (cons target-partition replicas)))))

(define (tensorfs-sync-remote! tfs path remote-content)
  "Sync content with remote version"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "Path not found:" path))
    ;; Compare embeddings to detect conflict
    (let* ((remote-embedding (content->embedding remote-content
                                                 (first (tensor-shape (tensorfs-node-embedding node)))))
           (local-embedding (tensorfs-node-embedding node))
           (similarity (cosine-similarity remote-embedding local-embedding)))
      (if (< similarity 0.9)
          ;; Significant difference - return conflict info
          `((conflict . #t)
            (similarity . ,similarity)
            (local-size . ,(string-length (tensorfs-node-content node)))
            (remote-size . ,(string-length remote-content)))
          ;; Similar - safe to sync
          (begin
            (tensorfs-write-file! tfs path remote-content)
            `((conflict . #f) (synced . #t)))))))

(define (tensorfs-partition-locate tfs path)
  "Determine which partition contains a path"
  (let ((partition-id (hash-ref (tensorfs-network-topology tfs) 'partition-id)))
    `((path . ,path)
      (partition . ,partition-id)
      (local . #t))))

(define* (tensorfs-distributed-search tfs query #:key (partitions '(0 1 2 3)))
  "Search across multiple partitions (returns local results with partition info)"
  (let ((local-results (tensorfs-semantic-search tfs query))
        (partition-id (hash-ref (tensorfs-network-topology tfs) 'partition-id)))
    ;; Return local results with partition annotation
    (map (lambda (r)
           (append r (list (cons 'partition partition-id))))
         local-results)))

;;; ---------- Attention Operations ----------

(define* (tensorfs-boost-attention! tfs path #:key (amount 0.1))
  "Increase attention on a path (called on access)"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (when node
      (let ((new-attention (min 1.0
                                (+ (tensorfs-node-attention node) amount))))
        (tensorfs-node-set-attention! node new-attention)))))

(define* (tensorfs-decay-attention! tfs #:key (decay-rate 0.01))
  "Decay attention on all nodes (called periodically)"
  (hash-for-each
   (lambda (path node)
     (let ((new-attention (* (tensorfs-node-attention node)
                             (- 1.0 decay-rate))))
       (tensorfs-node-set-attention! node new-attention)))
   (tensorfs-node-index tfs)))

(define* (tensorfs-attention-ranked-list tfs #:key (k 10))
  "Get top-k paths by attention"
  (let ((all-nodes '()))
    (hash-for-each
     (lambda (path node)
       (set! all-nodes (cons (cons path (tensorfs-node-attention node))
                             all-nodes)))
     (tensorfs-node-index tfs))
    (take (sort all-nodes (lambda (a b) (> (cdr a) (cdr b))))
          (min k (length all-nodes)))))

(define* (tensorfs-prefetch-predicted tfs path #:key (k 3))
  "Predict and return paths likely to be accessed next"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "Path not found:" path))
    ;; Use embedding similarity and attention to predict
    (let* ((similar (tensorfs-find-similar tfs path #:k 10))
           ;; Weight by attention
           (weighted (map (lambda (s)
                            (cons (first s)
                                  (* (third s)  ; similarity
                                     (fourth s)))) ; attention
                          similar)))
      (take (sort weighted (lambda (a b) (> (cdr a) (cdr b))))
            (min k (length weighted))))))

;;; ---------- Cognitive Operations ----------

(define (tensorfs-reason-about tfs path)
  "Use neural inference to reason about a file's relationships"
  (let ((node (hash-ref (tensorfs-node-index tfs) path)))
    (unless node
      (error "Path not found:" path))
    (let* ((similar (tensorfs-find-similar tfs path #:k 10))
           (parent (tensorfs-node-parent node))
           (siblings (if parent
                         (hash-map->list
                          (lambda (name child)
                            (tensorfs-node-path child))
                          (tensorfs-node-children parent))
                         '())))
      `((path . ,path)
        (similar-files . ,(map first similar))
        (siblings . ,siblings)
        (attention-rank . ,(tensorfs-node-attention node))
        (scale-level . ,(tensorfs-node-scale-level node))))))

(define (tensorfs-infer-relationships tfs path1 path2)
  "Infer relationship between two paths"
  (let ((node1 (hash-ref (tensorfs-node-index tfs) path1))
        (node2 (hash-ref (tensorfs-node-index tfs) path2)))
    (unless (and node1 node2)
      (error "Path not found"))
    (let ((similarity (cosine-similarity
                       (tensorfs-node-embedding node1)
                       (tensorfs-node-embedding node2))))
      `((similarity . ,similarity)
        (same-parent . ,(equal? (tensorfs-node-parent node1)
                                (tensorfs-node-parent node2)))
        (scale-difference . ,(abs (- (tensorfs-node-scale-level node1)
                                     (tensorfs-node-scale-level node2))))
        (relationship . ,(cond
                          ((> similarity 0.8) 'very-similar)
                          ((> similarity 0.5) 'related)
                          ((> similarity 0.2) 'loosely-related)
                          (else 'unrelated)))))))

(define* (tensorfs-suggest-organization tfs #:key (num-suggestions 5))
  "Suggest file organization based on embeddings"
  (let* ((clusters (cluster-entities
                    (tensorfs-atenspace tfs)
                    (hash-map->list (lambda (k v) k) (tensorfs-node-index tfs))
                    #:num-clusters (min 5 (hash-count (const #t) (tensorfs-node-index tfs)))))
         ;; Find files in wrong clusters based on path
         (suggestions '()))
    ;; Analyze each cluster
    (for-each
     (lambda (cluster)
       (let ((paths (filter string? cluster)))
         (when (> (length paths) 1)
           ;; Check if paths are in different directories
           (let ((dirs (delete-duplicates (map path-parent paths))))
             (when (> (length dirs) 1)
               (set! suggestions
                     (cons `(cluster ,paths
                                     suggestion "Consider grouping these related files")
                           suggestions)))))))
     clusters)
    (take suggestions (min num-suggestions (length suggestions)))))
