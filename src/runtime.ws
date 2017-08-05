; vim: ft=clojure

;; Practical, Simple, Useful

;; HAMT implementation blatantly stolen from (https://github.com/mattbierner/hamt/blob/master/lib/hamt.js)
;; Configuration

"use strict"

(def SIZE 5)

(def BUCKET_SIZE (Math.pow 2 SIZE))

(def MASK (- BUCKET_SIZE 1))

(def MAX_INDEX_NODE (/ BUCKET_SIZE 2))

(def MIN_ARRAY_NODE (/ BUCKET_SIZE 4))

(def nothing (Object.create nil))

(def constant (fn [x] (fn [] x)))

(def default-val-bind
  (fn [f default]
    (fn [x]
      (f (if (= (.- arguments length) 0) default x)))))

(def p (. console.log bind))

(def str
  (fn []
    (. (Array.prototype.slice.call arguments) (join ""))))

(def nil?
  (fn [x]
    (= nil x)))

(def empty?
  (fn [x]
    (if (nil? x)
      true
      (if (= (.- x length) 0)
        true
        false))))

(def str-hash
  (fn [s h]
    (if (empty? s)
      h
      (str-hash
        (. s (slice 1))
        (bit-or
          (+ (- (bit-shift-left h 5) h)
             (. s (charCodeAt 0)))
          0)))))

; seems to only support strings and numbers will need to change that
(def hash
  (fn [x]
    (def type (typeof x))
    (if (= type "number")
      x
      (if (not (= type "string"))
        (set! x (str x))
        (str-hash x 0)))))

;(p (hash "test"))
;(p (hash 1))

;; Bit Ops

; reader doesn't support hex notation for integers
(def popcount
  (fn [x]
    (set! x (- x (bit-and (bit-shift-right x 1) 1431655765))) ; hex: 0x55555555
    (set! x (+ (bit-and x 858993459) (bit-and (bit-shift-right x 2) 858993459))) ; hex: 0x33333333
    (set! x (bit-and (+ x (bit-shift-right x 4)) 252645135)) ; hex: 0x0f0f0f0f
    (set! x (+ x (bit-shift-right x 8)))
    (set! x (+ x (bit-shift-right x 16)))
    (bit-and x 127))) ; hex: 0x7f

;(def h (hash "To be or not to be, that is the question"))
;(p h)
;(p (popcount h))

(def hash-fragment
  (fn [shift h]
    (bit-and (unsigned-bit-shift-right h shift) MASK)))

(def ->bitmap
  (fn [x]
    (bit-shift-left 1 x)))

(def <-bitmap
  (fn [bitmap bit]
    (popcount (bit-and bitmap (- bit 1)))))

;; Array Ops
