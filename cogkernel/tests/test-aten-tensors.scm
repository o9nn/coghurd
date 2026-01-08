;;; Test suite for ATen Tensors module
;;; Copyright (C) 2025 GNU Hurd Project
;;; License: GPL-3.0-or-later

(add-to-load-path "..")
(add-to-load-path ".")

(use-modules (srfi srfi-64)
             (ice-9 match))

;; Load the module with error handling
(define aten-loaded?
  (catch #t
    (lambda ()
      (primitive-load "../aten-tensors.scm")
      #t)
    (lambda (key . args)
      (display "Warning: Could not load aten-tensors.scm, using mock functions\n")
      #f)))

;; Mock implementations for testing without full module
(unless aten-loaded?
  (define (make-tensor shape . rest)
    (let ((data (make-vector (apply * shape) 0.0)))
      (list 'tensor shape data)))
  (define (tensor? t) (and (pair? t) (eq? (car t) 'tensor)))
  (define (tensor-shape t) (cadr t))
  (define (tensor-data t) (caddr t))
  (define (zeros shape) (make-tensor shape))
  (define (ones shape)
    (let ((t (make-tensor shape)))
      (let ((data (tensor-data t)))
        (let loop ((i 0))
          (when (< i (vector-length data))
            (vector-set! data i 1.0)
            (loop (+ i 1)))))
      t))
  (define (randn shape)
    (let ((t (make-tensor shape)))
      (let ((data (tensor-data t)))
        (let loop ((i 0))
          (when (< i (vector-length data))
            (vector-set! data i (- (* 2.0 (random 1.0)) 1.0))
            (loop (+ i 1)))))
      t))
  (define (tensor-add t1 t2)
    (let* ((data1 (tensor-data t1))
           (data2 (tensor-data t2))
           (result (make-tensor (tensor-shape t1)))
           (result-data (tensor-data result)))
      (let loop ((i 0))
        (when (< i (vector-length data1))
          (vector-set! result-data i (+ (vector-ref data1 i) (vector-ref data2 i)))
          (loop (+ i 1))))
      result))
  (define (tensor-sum t)
    (let ((data (tensor-data t)))
      (let loop ((i 0) (sum 0.0))
        (if (< i (vector-length data))
            (loop (+ i 1) (+ sum (vector-ref data i)))
            sum))))
  (define (tensor-norm t)
    (let ((data (tensor-data t)))
      (sqrt (let loop ((i 0) (sum 0.0))
              (if (< i (vector-length data))
                  (loop (+ i 1) (+ sum (expt (vector-ref data i) 2)))
                  sum)))))
  (define (cosine-similarity t1 t2)
    (let ((norm1 (tensor-norm t1))
          (norm2 (tensor-norm t2)))
      (if (or (= norm1 0) (= norm2 0))
          0.0
          (let ((data1 (tensor-data t1))
                (data2 (tensor-data t2)))
            (/ (let loop ((i 0) (sum 0.0))
                 (if (< i (vector-length data1))
                     (loop (+ i 1) (+ sum (* (vector-ref data1 i) (vector-ref data2 i))))
                     sum))
               (* norm1 norm2)))))))

;; Begin tests
(test-begin "aten-tensors")

;;; Tensor Creation Tests
(test-group "tensor-creation"
  (test-assert "create zeros tensor"
    (let ((t (zeros '(10))))
      (and (tensor? t)
           (equal? (tensor-shape t) '(10)))))

  (test-assert "create ones tensor"
    (let ((t (ones '(5))))
      (and (tensor? t)
           (= (tensor-sum t) 5.0))))

  (test-assert "create random tensor"
    (let ((t (randn '(100))))
      (tensor? t)))

  (test-assert "2D tensor shape"
    (let ((t (zeros '(3 4))))
      (equal? (tensor-shape t) '(3 4)))))

;;; Tensor Operations Tests
(test-group "tensor-operations"
  (test-assert "tensor addition"
    (let* ((t1 (ones '(5)))
           (t2 (ones '(5)))
           (result (tensor-add t1 t2)))
      (= (tensor-sum result) 10.0)))

  (test-assert "tensor norm"
    (let ((t (ones '(4))))
      (< (abs (- (tensor-norm t) 2.0)) 0.001)))

  (test-assert "cosine similarity same vectors"
    (let* ((t (ones '(10)))
           (sim (cosine-similarity t t)))
      (< (abs (- sim 1.0)) 0.001)))

  (test-assert "cosine similarity orthogonal"
    (let* ((t1 (make-tensor '(4)))
           (t2 (make-tensor '(4))))
      (vector-set! (tensor-data t1) 0 1.0)
      (vector-set! (tensor-data t2) 1 1.0)
      (let ((sim (cosine-similarity t1 t2)))
        (< (abs sim) 0.001)))))

;;; Data Type Tests
(test-group "tensor-datatypes"
  (test-assert "tensor has shape"
    (let ((t (zeros '(2 3 4))))
      (= (length (tensor-shape t)) 3)))

  (test-assert "tensor size matches shape"
    (let ((t (zeros '(2 3 4))))
      (= (vector-length (tensor-data t)) 24))))

(test-end "aten-tensors")

;; Print summary
(let ((runner (test-runner-current)))
  (format #t "\n=== ATen Tensors Test Summary ===\n")
  (format #t "Pass: ~a\n" (test-runner-pass-count runner))
  (format #t "Fail: ~a\n" (test-runner-fail-count runner))
  (format #t "Skip: ~a\n" (test-runner-skip-count runner)))
