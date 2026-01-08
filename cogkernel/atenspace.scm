;;; ATenSpace - Neural-Symbolic Bridge for AtomSpace with Tensor Embeddings
;;; Inspired by ATenSpace (https://github.com/o9nn/ATenSpace)
;;; Bridges symbolic AI (AtomSpace) with neural tensor embeddings
;;;
;;; Copyright (C) 2025 GNU Hurd Project
;;; License: GPL-3.0-or-later

(define-module (cogkernel atenspace)
  #:use-module (ice-9 hash-table)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (cogkernel atomspace)
  #:use-module (cogkernel aten-tensors)
  #:export (;; ATenSpace creation
            make-atenspace
            atenspace?
            atenspace-atomspace
            atenspace-embeddings
            ;; Embedded atom operations
            make-embedded-atom
            embedded-atom?
            embedded-atom-atom
            embedded-atom-embedding
            ;; ATenSpace operations
            atenspace-add-atom!
            atenspace-add-embedded!
            atenspace-get-atom
            atenspace-get-embedding
            atenspace-update-embedding!
            ;; Semantic search
            query-similar
            query-by-embedding
            semantic-similarity
            find-nearest-neighbors
            ;; Neural-symbolic operations
            embed-concept
            embed-relationship
            propagate-attention
            neural-inference
            ;; Truth value operations
            tensor-truth-value
            truth-value-confidence
            tensor-strength
            ;; Multi-entity operations
            create-entity-embedding
            entity-similarity-matrix
            cluster-entities
            ;; Multi-scale operations
            create-scale-hierarchy
            cross-scale-attention
            hierarchical-embedding
            ;; Network-aware operations
            network-proximity-tensor
            distributed-embedding-sync
            partition-aware-query))

;;; ATenSpace record - combines AtomSpace with embedding storage
(define-record-type <atenspace>
  (make-atenspace-record atomspace embeddings entity-index scale-hierarchy)
  atenspace?
  (atomspace atenspace-atomspace)
  (embeddings atenspace-embeddings)  ; hash: atom-name -> tensor
  (entity-index atenspace-entity-index)  ; reverse index for similarity search
  (scale-hierarchy atenspace-scale-hierarchy))

;;; Embedded atom - combines symbolic atom with neural embedding
(define-record-type <embedded-atom>
  (make-embedded-atom-record atom embedding truth-value metadata)
  embedded-atom?
  (atom embedded-atom-atom)
  (embedding embedded-atom-embedding embedded-atom-set-embedding!)
  (truth-value embedded-atom-truth-value embedded-atom-set-truth-value!)
  (metadata embedded-atom-metadata))

;;; Tensor-based truth value
(define-record-type <tensor-truth-value>
  (make-tensor-truth-value-record strength confidence tensor-components)
  tensor-truth-value?
  (strength truth-value-strength)
  (confidence truth-value-confidence)
  (tensor-components truth-value-tensor))

;;; Create a new ATenSpace
(define* (make-atenspace #:key
                         (atomspace #f)
                         (embedding-dim 128)
                         (num-scales 4))
  "Create a new ATenSpace combining AtomSpace with tensor embeddings"
  (let ((as (or atomspace (make-atomspace))))
    (make-atenspace-record
     as
     (make-hash-table)
     (make-hash-table)
     (make-vector num-scales '()))))

;;; Add a symbolic atom to ATenSpace
(define (atenspace-add-atom! atenspace atom)
  "Add a symbolic atom to ATenSpace without embedding"
  (atomspace-add! (atenspace-atomspace atenspace) atom)
  atom)

;;; Add an atom with embedding to ATenSpace
(define* (atenspace-add-embedded! atenspace atom embedding #:key (metadata '()))
  "Add an atom with its neural embedding to ATenSpace"
  ;; Add to underlying AtomSpace
  (atomspace-add! (atenspace-atomspace atenspace) atom)
  ;; Store embedding
  (hash-set! (atenspace-embeddings atenspace) (atom-name atom) embedding)
  ;; Create embedded atom record
  (let* ((strength (tensor-mean embedding))
         (confidence (/ 1.0 (+ 1.0 (tensor-norm embedding))))
         (truth-val (make-tensor-truth-value-record strength confidence embedding)))
    (make-embedded-atom-record atom embedding truth-val metadata)))

;;; Retrieve atom from ATenSpace
(define (atenspace-get-atom atenspace name)
  "Retrieve atom by name from ATenSpace"
  (atomspace-get (atenspace-atomspace atenspace) name))

;;; Retrieve embedding for an atom
(define (atenspace-get-embedding atenspace name)
  "Retrieve embedding tensor for an atom by name"
  (hash-ref (atenspace-embeddings atenspace) name))

;;; Update embedding for an atom
(define (atenspace-update-embedding! atenspace name new-embedding)
  "Update the embedding for an existing atom"
  (hash-set! (atenspace-embeddings atenspace) name new-embedding))

;;; Query atoms similar to a target tensor
(define* (query-similar atenspace query-tensor #:key (k 5) (threshold 0.5))
  "Find k most similar atoms by embedding cosine similarity"
  (let ((similarities '()))
    ;; Compute similarity with all embeddings
    (hash-for-each
     (lambda (name embedding)
       (let ((sim (cosine-similarity query-tensor embedding)))
         (when (>= sim threshold)
           (set! similarities (cons (cons name sim) similarities)))))
     (atenspace-embeddings atenspace))
    ;; Sort by similarity and take top k
    (take (sort similarities (lambda (a b) (> (cdr a) (cdr b))))
          (min k (length similarities)))))

;;; Query by combining embedding similarity with graph structure
(define* (query-by-embedding atenspace query-tensor predicate #:key (k 5))
  "Query atoms matching both embedding similarity and symbolic predicate"
  (let ((similar (query-similar atenspace query-tensor #:k (* k 3))))
    ;; Filter by predicate
    (let ((filtered
           (filter (lambda (pair)
                     (let ((atom (atenspace-get-atom atenspace (car pair))))
                       (and atom (predicate atom))))
                   similar)))
      (take filtered (min k (length filtered))))))

;;; Compute semantic similarity between two atoms
(define (semantic-similarity atenspace name1 name2)
  "Compute semantic similarity between two atoms using embeddings"
  (let ((emb1 (atenspace-get-embedding atenspace name1))
        (emb2 (atenspace-get-embedding atenspace name2)))
    (if (and emb1 emb2)
        (cosine-similarity emb1 emb2)
        0.0)))

;;; Find k nearest neighbors to an atom
(define* (find-nearest-neighbors atenspace atom-name #:key (k 5))
  "Find k nearest neighbors to an atom by embedding similarity"
  (let ((query-emb (atenspace-get-embedding atenspace atom-name)))
    (if query-emb
        (filter (lambda (pair) (not (equal? (car pair) atom-name)))
                (query-similar atenspace query-emb #:k (+ k 1)))
        '())))

;;; Create embedding for a concept
(define* (embed-concept atenspace concept-name #:key (embedding-dim 128))
  "Create or retrieve embedding for a concept"
  (or (atenspace-get-embedding atenspace concept-name)
      (let* ((embedding (randn (list embedding-dim)))
             (atom (make-atom 'CONCEPT concept-name)))
        (atenspace-add-embedded! atenspace atom embedding)
        embedding)))

;;; Create embedding for a relationship
(define* (embed-relationship atenspace rel-type source target #:key (embedding-dim 128))
  "Create embedding for a relationship combining source, target, and relation type"
  (let ((source-emb (embed-concept atenspace source #:embedding-dim embedding-dim))
        (target-emb (embed-concept atenspace target #:embedding-dim embedding-dim))
        (rel-emb (randn (list embedding-dim))))
    ;; Combine embeddings (TransE-style: source + relation ≈ target)
    (let ((combined (tensor-add (tensor-add source-emb rel-emb)
                                (tensor-mul target-emb (ones (list embedding-dim))))))
      ;; Normalize the combined embedding
      (let ((norm (tensor-norm combined)))
        (if (> norm 0)
            (tensor-div combined (make-tensor (list embedding-dim)
                                              #:data (make-vector embedding-dim norm)))
            combined)))))

;;; Propagate attention through embeddings
(define (propagate-attention atenspace source-name attention-weight)
  "Propagate attention from source atom to neighbors"
  (let ((neighbors (find-nearest-neighbors atenspace source-name #:k 10)))
    (map (lambda (pair)
           (let* ((name (car pair))
                  (similarity (cdr pair))
                  (propagated-attention (* attention-weight similarity)))
             (cons name propagated-attention)))
         neighbors)))

;;; Neural inference - combine embeddings for reasoning
(define* (neural-inference atenspace premises conclusion-name #:key (threshold 0.6))
  "Perform neural inference by combining premise embeddings"
  (let* ((premise-embeddings
          (filter identity
                  (map (lambda (p) (atenspace-get-embedding atenspace p)) premises)))
         (num-premises (length premise-embeddings)))
    (if (= num-premises 0)
        #f
        (let* ((dim (first (tensor-shape (car premise-embeddings))))
               (combined (fold (lambda (emb acc) (tensor-add emb acc))
                               (zeros (list dim))
                               premise-embeddings))
               (avg-embedding (tensor-div combined
                                          (make-tensor (list dim)
                                                       #:data (make-vector dim num-premises)))))
          ;; Check if conclusion is similar to combined premises
          (let ((conclusion-emb (atenspace-get-embedding atenspace conclusion-name)))
            (if conclusion-emb
                (let ((sim (cosine-similarity avg-embedding conclusion-emb)))
                  (cons (>= sim threshold) sim))
                (cons #f 0.0)))))))

;;; Create tensor-based truth value
(define* (tensor-truth-value strength confidence #:optional (dim 16))
  "Create a tensor-based truth value with dimensional representation"
  (let ((tensor-rep (randn (list dim))))
    (make-tensor-truth-value-record strength confidence tensor-rep)))

;;; Get strength from tensor representation
(define (tensor-strength truth-val)
  "Extract strength value from tensor truth value"
  (truth-value-strength truth-val))

;;; Multi-entity embedding creation
(define* (create-entity-embedding atenspace entity-names #:key (embedding-dim 128))
  "Create embeddings for multiple entities as a batch"
  (map (lambda (name)
         (embed-concept atenspace name #:embedding-dim embedding-dim))
       entity-names))

;;; Compute entity similarity matrix
(define (entity-similarity-matrix atenspace entity-names)
  "Compute pairwise similarity matrix for entities"
  (let* ((n (length entity-names))
         (matrix (make-vector (* n n) 0.0)))
    (let loop-i ((i 0) (names entity-names))
      (when (pair? names)
        (let loop-j ((j 0) (names2 entity-names))
          (when (pair? names2)
            (let ((sim (semantic-similarity atenspace (car names) (car names2))))
              (vector-set! matrix (+ (* i n) j) sim))
            (loop-j (+ j 1) (cdr names2))))
        (loop-i (+ i 1) (cdr names))))
    (make-tensor (list n n) #:data matrix)))

;;; Cluster entities by embedding similarity
(define* (cluster-entities atenspace entity-names #:key (num-clusters 3) (max-iterations 10))
  "Cluster entities using k-means on embeddings"
  (let* ((embeddings (map (lambda (name)
                            (atenspace-get-embedding atenspace name))
                          entity-names))
         (valid-pairs (filter (lambda (p) (cdr p))
                              (map cons entity-names embeddings)))
         (valid-names (map car valid-pairs))
         (valid-embs (map cdr valid-pairs))
         (n (length valid-embs)))
    (if (< n num-clusters)
        (map list valid-names)  ; Each entity in its own cluster
        ;; Simple k-means clustering
        (let* ((dim (first (tensor-shape (car valid-embs))))
               ;; Initialize centroids randomly
               (centroids (take valid-embs num-clusters))
               (assignments (make-vector n 0)))
          ;; Iterate
          (let iter ((it 0))
            (when (< it max-iterations)
              ;; Assign each point to nearest centroid
              (let assign ((i 0) (embs valid-embs))
                (when (pair? embs)
                  (let* ((best-cluster 0)
                         (best-dist 1e10))
                    (let check ((c 0) (cents centroids))
                      (when (pair? cents)
                        (let ((dist (euclidean-distance (car embs) (car cents))))
                          (when (< dist best-dist)
                            (set! best-dist dist)
                            (set! best-cluster c)))
                        (check (+ c 1) (cdr cents))))
                    (vector-set! assignments i best-cluster))
                  (assign (+ i 1) (cdr embs))))
              (iter (+ it 1))))
          ;; Group names by cluster
          (let ((clusters (make-vector num-clusters '())))
            (let group ((i 0) (names valid-names))
              (when (pair? names)
                (let ((c (vector-ref assignments i)))
                  (vector-set! clusters c (cons (car names) (vector-ref clusters c))))
                (group (+ i 1) (cdr names))))
            (vector->list clusters))))))

;;; Create scale hierarchy for multi-scale representation
(define* (create-scale-hierarchy atenspace embedding #:key (num-scales 4))
  "Create multi-scale representation of an embedding"
  (create-multi-scale-tensor embedding #:num-scales num-scales))

;;; Cross-scale attention between different scales
(define (cross-scale-attention mst source-scale target-scale)
  "Compute attention from source scale to target scale"
  (let ((source-tensor (pyramid-representation mst source-scale))
        (target-tensor (pyramid-representation mst target-scale)))
    (cosine-similarity (tensor-flatten source-tensor)
                       (tensor-flatten target-tensor))))

;;; Create hierarchical embedding aggregating all scales
(define (hierarchical-embedding mst)
  "Create a single embedding from multi-scale representation"
  (let* ((scales (multi-scale-scales mst))
         (num-scales (vector-length scales)))
    ;; Concatenate all scale representations
    (let loop ((i 0) (parts '()))
      (if (< i num-scales)
          (loop (+ i 1) (cons (tensor-flatten (vector-ref scales i)) parts))
          ;; Average all parts to fixed dimension
          (let* ((all-data (apply append
                                  (map (lambda (t) (vector->list (tensor-data t)))
                                       (reverse parts))))
                 (total-size (length all-data))
                 (result (make-vector 128 0.0)))
            ;; Downsample or average to 128 dimensions
            (let fill ((i 0))
              (when (< i 128)
                (let ((start (* i (quotient total-size 128)))
                      (end (* (+ i 1) (quotient total-size 128))))
                  (let sum ((j start) (s 0.0))
                    (if (< j (min end total-size))
                        (sum (+ j 1) (+ s (list-ref all-data j)))
                        (vector-set! result i (/ s (max 1 (- end start)))))))
                (fill (+ i 1))))
            (make-tensor '(128) #:data result))))))

;;; Network proximity tensor for distributed awareness
(define* (network-proximity-tensor atenspace entity-names network-topology)
  "Create tensor encoding network proximity between entities"
  (let* ((n (length entity-names))
         (proximity (make-vector (* n n) 0.0)))
    ;; Combine semantic similarity with network distance
    (let loop-i ((i 0) (names1 entity-names))
      (when (pair? names1)
        (let loop-j ((j 0) (names2 entity-names))
          (when (pair? names2)
            (let* ((semantic-sim (semantic-similarity atenspace (car names1) (car names2)))
                   ;; Network distance from topology (default to 1.0 if not specified)
                   (net-dist (or (and network-topology
                                      (hash-ref network-topology
                                                (cons (car names1) (car names2))))
                                 1.0))
                   ;; Combine: high semantic sim + low network dist = high proximity
                   (combined (/ semantic-sim (+ 1.0 net-dist))))
              (vector-set! proximity (+ (* i n) j) combined))
            (loop-j (+ j 1) (cdr names2))))
        (loop-i (+ i 1) (cdr names1))))
    (make-tensor (list n n) #:data proximity)))

;;; Sync embeddings across distributed nodes
(define (distributed-embedding-sync local-atenspace remote-embeddings)
  "Synchronize embeddings with remote ATenSpace"
  ;; Merge remote embeddings into local space
  (for-each (lambda (pair)
              (let ((name (car pair))
                    (embedding (cdr pair)))
                (unless (atenspace-get-embedding local-atenspace name)
                  (hash-set! (atenspace-embeddings local-atenspace) name embedding))))
            remote-embeddings))

;;; Partition-aware query for distributed systems
(define* (partition-aware-query atenspace query-tensor partition-id #:key (k 5))
  "Query similar atoms with awareness of data partitioning"
  (let* ((similar (query-similar atenspace query-tensor #:k (* k 2)))
         ;; Filter to local partition (simplified: hash-based partitioning)
         (local-results
          (filter (lambda (pair)
                    (= (modulo (string-hash (car pair)) 4) partition-id))
                  similar)))
    (take local-results (min k (length local-results)))))
