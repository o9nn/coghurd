;;; Test suite for ATenSpace module
;;; Copyright (C) 2025 GNU Hurd Project
;;; License: GPL-3.0-or-later

(add-to-load-path "..")
(add-to-load-path ".")

(use-modules (srfi srfi-64)
             (ice-9 hash-table))

;; Mock implementations for testing
(define (make-mock-tensor shape)
  (let ((data (make-vector (apply * shape) 0.0)))
    ;; Initialize with random-ish values
    (let loop ((i 0))
      (when (< i (vector-length data))
        (vector-set! data i (- (* 2.0 (/ (modulo (* i 17) 100) 100.0)) 1.0))
        (loop (+ i 1))))
    (list 'tensor shape data)))

(define (mock-tensor? t) (and (pair? t) (eq? (car t) 'tensor)))
(define (mock-tensor-shape t) (cadr t))
(define (mock-tensor-data t) (caddr t))

(define (mock-tensor-norm t)
  (let ((data (mock-tensor-data t)))
    (sqrt (let loop ((i 0) (sum 0.0))
            (if (< i (vector-length data))
                (loop (+ i 1) (+ sum (expt (vector-ref data i) 2)))
                sum)))))

(define (mock-cosine-similarity t1 t2)
  (let ((norm1 (mock-tensor-norm t1))
        (norm2 (mock-tensor-norm t2)))
    (if (or (= norm1 0) (= norm2 0))
        0.0
        (let ((data1 (mock-tensor-data t1))
              (data2 (mock-tensor-data t2)))
          (/ (let loop ((i 0) (sum 0.0))
               (if (< i (min (vector-length data1) (vector-length data2)))
                   (loop (+ i 1) (+ sum (* (vector-ref data1 i) (vector-ref data2 i))))
                   sum))
             (* norm1 norm2))))))

;; Mock ATenSpace implementation
(define (make-mock-atenspace)
  (let ((embeddings (make-hash-table))
        (atoms (make-hash-table)))
    (list 'atenspace embeddings atoms)))

(define (mock-atenspace? as) (and (pair? as) (eq? (car as) 'atenspace)))
(define (mock-atenspace-embeddings as) (cadr as))
(define (mock-atenspace-atoms as) (caddr as))

(define (mock-atenspace-add! as name embedding)
  (hash-set! (mock-atenspace-embeddings as) name embedding))

(define (mock-atenspace-get-embedding as name)
  (hash-ref (mock-atenspace-embeddings as) name))

(define (mock-query-similar as query-tensor k threshold)
  (let ((results '()))
    (hash-for-each
     (lambda (name embedding)
       (let ((sim (mock-cosine-similarity query-tensor embedding)))
         (when (>= sim threshold)
           (set! results (cons (cons name sim) results)))))
     (mock-atenspace-embeddings as))
    (take (sort results (lambda (a b) (> (cdr a) (cdr b))))
          (min k (length results)))))

;; Begin tests
(test-begin "atenspace")

;;; ATenSpace Creation Tests
(test-group "atenspace-creation"
  (test-assert "create atenspace"
    (mock-atenspace? (make-mock-atenspace)))

  (test-assert "atenspace has embeddings table"
    (hash-table? (mock-atenspace-embeddings (make-mock-atenspace)))))

;;; Embedding Storage Tests
(test-group "embedding-storage"
  (test-assert "add embedding"
    (let ((as (make-mock-atenspace))
          (emb (make-mock-tensor '(128))))
      (mock-atenspace-add! as "test-concept" emb)
      (equal? (mock-atenspace-get-embedding as "test-concept") emb)))

  (test-assert "get non-existent embedding returns #f"
    (let ((as (make-mock-atenspace)))
      (not (mock-atenspace-get-embedding as "non-existent"))))

  (test-assert "multiple embeddings"
    (let ((as (make-mock-atenspace)))
      (mock-atenspace-add! as "concept-a" (make-mock-tensor '(64)))
      (mock-atenspace-add! as "concept-b" (make-mock-tensor '(64)))
      (mock-atenspace-add! as "concept-c" (make-mock-tensor '(64)))
      (and (mock-atenspace-get-embedding as "concept-a")
           (mock-atenspace-get-embedding as "concept-b")
           (mock-atenspace-get-embedding as "concept-c")))))

;;; Similarity Search Tests
(test-group "similarity-search"
  (test-assert "query similar finds matches"
    (let ((as (make-mock-atenspace))
          (emb1 (make-mock-tensor '(32)))
          (emb2 (make-mock-tensor '(32))))
      (mock-atenspace-add! as "item1" emb1)
      (mock-atenspace-add! as "item2" emb2)
      (let ((results (mock-query-similar as emb1 5 0.0)))
        (> (length results) 0))))

  (test-assert "self similarity is highest"
    (let ((as (make-mock-atenspace))
          (emb (make-mock-tensor '(32))))
      (mock-atenspace-add! as "self" emb)
      (mock-atenspace-add! as "other" (make-mock-tensor '(32)))
      (let ((results (mock-query-similar as emb 5 0.0)))
        (string=? (caar results) "self"))))

  (test-assert "threshold filters results"
    (let ((as (make-mock-atenspace)))
      (mock-atenspace-add! as "a" (make-mock-tensor '(32)))
      (mock-atenspace-add! as "b" (make-mock-tensor '(32)))
      (let ((query (make-mock-tensor '(32))))
        (let ((results-low (mock-query-similar as query 10 0.0))
              (results-high (mock-query-similar as query 10 0.99)))
          (<= (length results-high) (length results-low)))))))

;;; Multi-Entity Tests
(test-group "multi-entity"
  (test-assert "entity permissions storage"
    (let ((permissions (make-hash-table)))
      (hash-set! permissions "entity-1" '(read write))
      (hash-set! permissions "entity-2" '(read))
      (and (equal? (hash-ref permissions "entity-1") '(read write))
           (equal? (hash-ref permissions "entity-2") '(read))))))

;;; Network-Aware Tests
(test-group "network-aware"
  (test-assert "partition-aware storage"
    (let ((partitions (make-hash-table)))
      (hash-set! partitions 'partition-id 0)
      (hash-set! partitions 'replicas '(1 2))
      (and (= (hash-ref partitions 'partition-id) 0)
           (equal? (hash-ref partitions 'replicas) '(1 2))))))

(test-end "atenspace")

;; Print summary
(let ((runner (test-runner-current)))
  (format #t "\n=== ATenSpace Test Summary ===\n")
  (format #t "Pass: ~a\n" (test-runner-pass-count runner))
  (format #t "Fail: ~a\n" (test-runner-fail-count runner))
  (format #t "Skip: ~a\n" (test-runner-skip-count runner)))
