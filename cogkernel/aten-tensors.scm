;;; ATen Tensors - C++11 Tensor Library Integration for Cognitive Kernel
;;; Inspired by ATen (https://github.com/o9nn/ATen)
;;; Implements tensor operations for neural-symbolic hybrid computation
;;;
;;; Copyright (C) 2025 GNU Hurd Project
;;; License: GPL-3.0-or-later

(define-module (cogkernel aten-tensors)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-43)
  #:export (;; Tensor creation
            make-tensor
            tensor?
            tensor-shape
            tensor-data
            tensor-dtype
            tensor-device
            zeros
            ones
            randn
            eye
            arange
            ;; Tensor operations
            tensor-add
            tensor-sub
            tensor-mul
            tensor-div
            tensor-matmul
            tensor-transpose
            tensor-reshape
            tensor-flatten
            tensor-slice
            ;; Reduction operations
            tensor-sum
            tensor-mean
            tensor-max
            tensor-min
            tensor-norm
            ;; Neural operations
            tensor-relu
            tensor-sigmoid
            tensor-softmax
            tensor-tanh
            ;; Similarity operations
            cosine-similarity
            euclidean-distance
            dot-product
            ;; Embedding operations
            make-embedding
            embedding-lookup
            embedding-update!
            ;; Multi-scale operations
            create-multi-scale-tensor
            downsample-tensor
            upsample-tensor
            pyramid-representation))

;;; Data types for tensors
(define tensor-dtypes '(float32 float64 int32 int64 bool))

;;; Device types
(define device-types '(cpu cuda))

;;; Tensor record structure
(define-record-type <tensor>
  (make-tensor-record shape data dtype device requires-grad)
  tensor?
  (shape tensor-shape)
  (data tensor-data tensor-set-data!)
  (dtype tensor-dtype)
  (device tensor-device)
  (requires-grad tensor-requires-grad?))

;;; Create a new tensor with given shape and data
(define* (make-tensor shape #:key (data #f) (dtype 'float32) (device 'cpu) (requires-grad #f))
  "Create a tensor with specified shape [dim1, dim2, ...].
   If data is not provided, initializes with zeros."
  (let* ((total-size (apply * shape))
         (tensor-data (or data (make-vector total-size 0.0))))
    (make-tensor-record shape tensor-data dtype device requires-grad)))

;;; Create tensor filled with zeros
(define* (zeros shape #:key (dtype 'float32) (device 'cpu))
  "Create a tensor filled with zeros"
  (make-tensor shape #:dtype dtype #:device device))

;;; Create tensor filled with ones
(define* (ones shape #:key (dtype 'float32) (device 'cpu))
  "Create a tensor filled with ones"
  (let ((total-size (apply * shape)))
    (make-tensor shape
                 #:data (make-vector total-size 1.0)
                 #:dtype dtype
                 #:device device)))

;;; Create tensor with random normal values
(define* (randn shape #:key (dtype 'float32) (device 'cpu))
  "Create a tensor with random normal distribution (mean=0, std=1)"
  (let* ((total-size (apply * shape))
         (data (make-vector total-size)))
    ;; Box-Muller transform for normal distribution
    (let loop ((i 0))
      (when (< i total-size)
        (let* ((u1 (+ 0.0001 (* (random 1.0) 0.9998)))
               (u2 (+ 0.0001 (* (random 1.0) 0.9998)))
               (z (sqrt (* -2.0 (log u1)))))
          (vector-set! data i (* z (cos (* 2.0 3.14159265359 u2))))
          (when (< (+ i 1) total-size)
            (vector-set! data (+ i 1) (* z (sin (* 2.0 3.14159265359 u2)))))
          (loop (+ i 2)))))
    (make-tensor shape #:data data #:dtype dtype #:device device)))

;;; Create identity matrix
(define* (eye n #:key (dtype 'float32) (device 'cpu))
  "Create an n x n identity matrix"
  (let ((data (make-vector (* n n) 0.0)))
    (let loop ((i 0))
      (when (< i n)
        (vector-set! data (+ (* i n) i) 1.0)
        (loop (+ i 1))))
    (make-tensor (list n n) #:data data #:dtype dtype #:device device)))

;;; Create a tensor with values in range
(define* (arange start end #:key (step 1) (dtype 'float32) (device 'cpu))
  "Create a 1D tensor with values from start to end (exclusive)"
  (let* ((size (ceiling (/ (- end start) step)))
         (data (make-vector size)))
    (let loop ((i 0) (val start))
      (when (< i size)
        (vector-set! data i val)
        (loop (+ i 1) (+ val step))))
    (make-tensor (list size) #:data data #:dtype dtype #:device device)))

;;; Element-wise tensor addition
(define (tensor-add t1 t2)
  "Element-wise addition of two tensors"
  (unless (equal? (tensor-shape t1) (tensor-shape t2))
    (error "Shape mismatch in tensor-add"))
  (let* ((data1 (tensor-data t1))
         (data2 (tensor-data t2))
         (size (vector-length data1))
         (result (make-vector size)))
    (let loop ((i 0))
      (when (< i size)
        (vector-set! result i (+ (vector-ref data1 i) (vector-ref data2 i)))
        (loop (+ i 1))))
    (make-tensor (tensor-shape t1) #:data result)))

;;; Element-wise tensor subtraction
(define (tensor-sub t1 t2)
  "Element-wise subtraction of two tensors"
  (unless (equal? (tensor-shape t1) (tensor-shape t2))
    (error "Shape mismatch in tensor-sub"))
  (let* ((data1 (tensor-data t1))
         (data2 (tensor-data t2))
         (size (vector-length data1))
         (result (make-vector size)))
    (let loop ((i 0))
      (when (< i size)
        (vector-set! result i (- (vector-ref data1 i) (vector-ref data2 i)))
        (loop (+ i 1))))
    (make-tensor (tensor-shape t1) #:data result)))

;;; Element-wise tensor multiplication
(define (tensor-mul t1 t2)
  "Element-wise multiplication of two tensors"
  (unless (equal? (tensor-shape t1) (tensor-shape t2))
    (error "Shape mismatch in tensor-mul"))
  (let* ((data1 (tensor-data t1))
         (data2 (tensor-data t2))
         (size (vector-length data1))
         (result (make-vector size)))
    (let loop ((i 0))
      (when (< i size)
        (vector-set! result i (* (vector-ref data1 i) (vector-ref data2 i)))
        (loop (+ i 1))))
    (make-tensor (tensor-shape t1) #:data result)))

;;; Element-wise tensor division
(define (tensor-div t1 t2)
  "Element-wise division of two tensors"
  (unless (equal? (tensor-shape t1) (tensor-shape t2))
    (error "Shape mismatch in tensor-div"))
  (let* ((data1 (tensor-data t1))
         (data2 (tensor-data t2))
         (size (vector-length data1))
         (result (make-vector size)))
    (let loop ((i 0))
      (when (< i size)
        (let ((d2 (vector-ref data2 i)))
          (vector-set! result i (if (= d2 0) 0.0 (/ (vector-ref data1 i) d2))))
        (loop (+ i 1))))
    (make-tensor (tensor-shape t1) #:data result)))

;;; Matrix multiplication
(define (tensor-matmul t1 t2)
  "Matrix multiplication of two 2D tensors"
  (let ((shape1 (tensor-shape t1))
        (shape2 (tensor-shape t2)))
    (unless (and (= (length shape1) 2) (= (length shape2) 2))
      (error "tensor-matmul requires 2D tensors"))
    (let ((m (first shape1))
          (k1 (second shape1))
          (k2 (first shape2))
          (n (second shape2)))
      (unless (= k1 k2)
        (error "Inner dimensions must match for matmul"))
      (let* ((result-size (* m n))
             (result (make-vector result-size 0.0))
             (data1 (tensor-data t1))
             (data2 (tensor-data t2)))
        (let loop-i ((i 0))
          (when (< i m)
            (let loop-j ((j 0))
              (when (< j n)
                (let loop-k ((k 0) (sum 0.0))
                  (if (< k k1)
                      (let ((a (vector-ref data1 (+ (* i k1) k)))
                            (b (vector-ref data2 (+ (* k n) j))))
                        (loop-k (+ k 1) (+ sum (* a b))))
                      (vector-set! result (+ (* i n) j) sum)))
                (loop-j (+ j 1))))
            (loop-i (+ i 1))))
        (make-tensor (list m n) #:data result)))))

;;; Transpose a 2D tensor
(define (tensor-transpose t)
  "Transpose a 2D tensor"
  (let ((shape (tensor-shape t)))
    (unless (= (length shape) 2)
      (error "tensor-transpose requires 2D tensor"))
    (let* ((m (first shape))
           (n (second shape))
           (data (tensor-data t))
           (result (make-vector (* m n))))
      (let loop-i ((i 0))
        (when (< i m)
          (let loop-j ((j 0))
            (when (< j n)
              (vector-set! result (+ (* j m) i) (vector-ref data (+ (* i n) j)))
              (loop-j (+ j 1))))
          (loop-i (+ i 1))))
      (make-tensor (list n m) #:data result))))

;;; Reshape tensor
(define (tensor-reshape t new-shape)
  "Reshape tensor to new shape (total elements must match)"
  (let ((old-size (apply * (tensor-shape t)))
        (new-size (apply * new-shape)))
    (unless (= old-size new-size)
      (error "Cannot reshape: total elements don't match"))
    (make-tensor new-shape #:data (vector-copy (tensor-data t)))))

;;; Flatten tensor to 1D
(define (tensor-flatten t)
  "Flatten tensor to 1D"
  (let ((total-size (apply * (tensor-shape t))))
    (make-tensor (list total-size) #:data (vector-copy (tensor-data t)))))

;;; Slice tensor
(define (tensor-slice t start end)
  "Slice a tensor along the first dimension"
  (let* ((shape (tensor-shape t))
         (first-dim (first shape))
         (rest-dims (cdr shape))
         (stride (apply * rest-dims))
         (slice-size (* (- end start) stride))
         (result (make-vector slice-size))
         (data (tensor-data t)))
    (let loop ((i 0))
      (when (< i slice-size)
        (vector-set! result i (vector-ref data (+ (* start stride) i)))
        (loop (+ i 1))))
    (make-tensor (cons (- end start) rest-dims) #:data result)))

;;; Sum all elements
(define (tensor-sum t)
  "Sum all elements in tensor"
  (let ((data (tensor-data t)))
    (let loop ((i 0) (sum 0.0))
      (if (< i (vector-length data))
          (loop (+ i 1) (+ sum (vector-ref data i)))
          sum))))

;;; Mean of all elements
(define (tensor-mean t)
  "Mean of all elements in tensor"
  (/ (tensor-sum t) (apply * (tensor-shape t))))

;;; Maximum element
(define (tensor-max t)
  "Maximum element in tensor"
  (let ((data (tensor-data t)))
    (let loop ((i 1) (max-val (vector-ref data 0)))
      (if (< i (vector-length data))
          (loop (+ i 1) (max max-val (vector-ref data i)))
          max-val))))

;;; Minimum element
(define (tensor-min t)
  "Minimum element in tensor"
  (let ((data (tensor-data t)))
    (let loop ((i 1) (min-val (vector-ref data 0)))
      (if (< i (vector-length data))
          (loop (+ i 1) (min min-val (vector-ref data i)))
          min-val))))

;;; L2 norm
(define (tensor-norm t)
  "L2 norm of tensor"
  (let ((data (tensor-data t)))
    (sqrt (let loop ((i 0) (sum 0.0))
            (if (< i (vector-length data))
                (let ((v (vector-ref data i)))
                  (loop (+ i 1) (+ sum (* v v))))
                sum)))))

;;; ReLU activation
(define (tensor-relu t)
  "Apply ReLU activation (max(0, x))"
  (let* ((data (tensor-data t))
         (size (vector-length data))
         (result (make-vector size)))
    (let loop ((i 0))
      (when (< i size)
        (vector-set! result i (max 0.0 (vector-ref data i)))
        (loop (+ i 1))))
    (make-tensor (tensor-shape t) #:data result)))

;;; Sigmoid activation
(define (tensor-sigmoid t)
  "Apply sigmoid activation (1 / (1 + exp(-x)))"
  (let* ((data (tensor-data t))
         (size (vector-length data))
         (result (make-vector size)))
    (let loop ((i 0))
      (when (< i size)
        (let ((x (vector-ref data i)))
          (vector-set! result i (/ 1.0 (+ 1.0 (exp (- x))))))
        (loop (+ i 1))))
    (make-tensor (tensor-shape t) #:data result)))

;;; Tanh activation
(define (tensor-tanh t)
  "Apply tanh activation"
  (let* ((data (tensor-data t))
         (size (vector-length data))
         (result (make-vector size)))
    (let loop ((i 0))
      (when (< i size)
        (vector-set! result i (tanh (vector-ref data i)))
        (loop (+ i 1))))
    (make-tensor (tensor-shape t) #:data result)))

;;; Softmax activation
(define (tensor-softmax t)
  "Apply softmax activation"
  (let* ((data (tensor-data t))
         (size (vector-length data))
         (max-val (tensor-max t))
         (result (make-vector size)))
    ;; Compute exp(x - max) for numerical stability
    (let ((sum (let loop ((i 0) (s 0.0))
                 (if (< i size)
                     (let ((e (exp (- (vector-ref data i) max-val))))
                       (vector-set! result i e)
                       (loop (+ i 1) (+ s e)))
                     s))))
      ;; Normalize
      (let loop ((i 0))
        (when (< i size)
          (vector-set! result i (/ (vector-ref result i) sum))
          (loop (+ i 1)))))
    (make-tensor (tensor-shape t) #:data result)))

;;; Cosine similarity between two vectors
(define (cosine-similarity t1 t2)
  "Compute cosine similarity between two tensors"
  (let ((norm1 (tensor-norm t1))
        (norm2 (tensor-norm t2)))
    (if (or (= norm1 0) (= norm2 0))
        0.0
        (/ (dot-product t1 t2) (* norm1 norm2)))))

;;; Euclidean distance between two tensors
(define (euclidean-distance t1 t2)
  "Compute Euclidean distance between two tensors"
  (tensor-norm (tensor-sub t1 t2)))

;;; Dot product of two tensors
(define (dot-product t1 t2)
  "Compute dot product of two tensors"
  (let* ((data1 (tensor-data t1))
         (data2 (tensor-data t2))
         (size (min (vector-length data1) (vector-length data2))))
    (let loop ((i 0) (sum 0.0))
      (if (< i size)
          (loop (+ i 1) (+ sum (* (vector-ref data1 i) (vector-ref data2 i))))
          sum))))

;;; Embedding table structure
(define-record-type <embedding>
  (make-embedding-record num-embeddings embedding-dim weights)
  embedding?
  (num-embeddings embedding-num-embeddings)
  (embedding-dim embedding-dim)
  (weights embedding-weights embedding-set-weights!))

;;; Create an embedding table
(define* (make-embedding num-embeddings embedding-dim #:key (init-scale 0.1))
  "Create an embedding table with num_embeddings vectors of dimension embedding_dim"
  (let* ((total-size (* num-embeddings embedding-dim))
         (weights (make-vector total-size)))
    ;; Initialize with small random values
    (let loop ((i 0))
      (when (< i total-size)
        (vector-set! weights i (* init-scale (- (* 2 (random 1.0)) 1.0)))
        (loop (+ i 1))))
    (make-embedding-record num-embeddings embedding-dim weights)))

;;; Lookup embedding by index
(define (embedding-lookup embedding idx)
  "Look up embedding vector by index"
  (let* ((dim (embedding-dim embedding))
         (start (* idx dim))
         (result (make-vector dim))
         (weights (embedding-weights embedding)))
    (let loop ((i 0))
      (when (< i dim)
        (vector-set! result i (vector-ref weights (+ start i)))
        (loop (+ i 1))))
    (make-tensor (list dim) #:data result)))

;;; Update embedding at index
(define (embedding-update! embedding idx tensor)
  "Update embedding vector at index"
  (let* ((dim (embedding-dim embedding))
         (start (* idx dim))
         (weights (embedding-weights embedding))
         (data (tensor-data tensor)))
    (let loop ((i 0))
      (when (< i dim)
        (vector-set! weights (+ start i) (vector-ref data i))
        (loop (+ i 1))))))

;;; Multi-scale tensor representation
(define-record-type <multi-scale-tensor>
  (make-multi-scale-tensor-record scales base-tensor)
  multi-scale-tensor?
  (scales multi-scale-scales)
  (base-tensor multi-scale-base))

;;; Create multi-scale tensor representation
(define* (create-multi-scale-tensor tensor #:key (num-scales 4) (scale-factor 2))
  "Create a pyramid of tensors at different scales"
  (let ((scales (make-vector num-scales)))
    (vector-set! scales 0 tensor)
    (let loop ((i 1) (current tensor))
      (when (< i num-scales)
        (let ((downsampled (downsample-tensor current scale-factor)))
          (vector-set! scales i downsampled)
          (loop (+ i 1) downsampled))))
    (make-multi-scale-tensor-record scales tensor)))

;;; Downsample tensor by averaging
(define (downsample-tensor tensor factor)
  "Downsample tensor by factor (averaging adjacent elements)"
  (let* ((shape (tensor-shape tensor))
         (new-shape (map (lambda (d) (max 1 (quotient d factor))) shape))
         (data (tensor-data tensor))
         (new-size (apply * new-shape))
         (result (make-vector new-size 0.0)))
    ;; Simple downsampling for 1D case
    (if (= (length shape) 1)
        (let ((old-len (first shape))
              (new-len (first new-shape)))
          (let loop ((i 0))
            (when (< i new-len)
              (let inner ((j 0) (sum 0.0))
                (if (< j factor)
                    (let ((idx (+ (* i factor) j)))
                      (inner (+ j 1)
                             (+ sum (if (< idx old-len)
                                        (vector-ref data idx)
                                        0.0))))
                    (vector-set! result i (/ sum factor))))
              (loop (+ i 1)))))
        ;; For higher dimensions, just truncate for simplicity
        (let loop ((i 0))
          (when (< i new-size)
            (vector-set! result i (vector-ref data (min i (- (vector-length data) 1))))
            (loop (+ i 1)))))
    (make-tensor new-shape #:data result)))

;;; Upsample tensor by repetition
(define (upsample-tensor tensor factor)
  "Upsample tensor by factor (repeating elements)"
  (let* ((shape (tensor-shape tensor))
         (new-shape (map (lambda (d) (* d factor)) shape))
         (data (tensor-data tensor))
         (new-size (apply * new-shape))
         (result (make-vector new-size)))
    ;; Simple upsampling for 1D case
    (if (= (length shape) 1)
        (let ((old-len (first shape)))
          (let loop ((i 0))
            (when (< i old-len)
              (let ((val (vector-ref data i)))
                (let inner ((j 0))
                  (when (< j factor)
                    (vector-set! result (+ (* i factor) j) val)
                    (inner (+ j 1)))))
              (loop (+ i 1)))))
        ;; For higher dimensions
        (let loop ((i 0))
          (when (< i new-size)
            (vector-set! result i (vector-ref data (quotient i factor)))
            (loop (+ i 1)))))
    (make-tensor new-shape #:data result)))

;;; Get pyramid representation at specific scale
(define (pyramid-representation mst scale-idx)
  "Get tensor at specific scale from multi-scale tensor"
  (vector-ref (multi-scale-scales mst) scale-idx))
