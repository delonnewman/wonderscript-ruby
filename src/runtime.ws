; vim: ft=clojure
"use strict"

;; Practical, Simple, Flexible

(def p (. console.log bind))

(def ws.core/RecursionPoint
  (fn [args]
    (def obj (Object.create nil))
    (set! (.- obj $ws$lang$tag) "RecursionPoint")
    (set! (.- obj args) args)
    obj))

(set! module.exports ws.core)

(def str
  (fn [&args]
    (. (Array.prototype.slice.call args) (join ""))))

(def nil?
  (fn [x]
    (identical? nil x)))

(def empty?
  (fn [x]
    (cond
      (nil? x) true
      (identical? (.- x length) 0) true
      :else false)))

(def is
  (fn [expected actual]
    (cond (identical? expected actual) nil
          :else
            (throw (str "FAILURE: " expected " is not equal to " actual)))))

(def array
  (fn [&args]
    (Array.prototype.slice.call args)))

(def array?
  (fn [x]
    (identical? (Object.prototype.toString.call x) "[object Array]")))

(def object
  (fn [&args]
    (def obj (Object.create nil))
    (loop [i 0]
      (cond
        (identical? i (.- args length)) nil
        :else
          ((fn []
            (aset obj (aget args i) (aget args (+ 1 i)))
            (recur (+ 2 i))))))
    obj))

(def Keyword
  (fn [namespace name]
    (object "$ws$lang$type" "keyword" "$namespace" namespace "$name" name)))

(def ws.core/keyword
  (fn [&xs]
    (cond (identical? (.- xs length) 1) (Keyword nil (aget xs 0))
          (identical? (.- xs length) 2) (Keyword (aget xs 0) (aget xs 1))
          :else
            (throw (new Error "expected either 1 or 2 arguments")))))

(def ws.core/keyword?
  (fn [x]
    (identical? (aget x "$ws$lang$type") "keyword")))

(def ws.core/namespace
  (fn [x]
    (.- x namespace)))

(def ws.core/name
  (fn [x]
    (.- x name)))

(def Symbol
  (fn [namespace name]
    (object "$ws$lang$type" "symbol" "$namespace" namespace "$name" name)))

(def ws.core/symbol
  (fn [&xs]
    (cond (identical? (.- xs length) 1) (Symbol nil (aget xs 0))
          (identical? (.- xs length) 2) (Symbol (aget xs 0) (aget xs 1))
          :else
            (throw (new Error "expected either 1 or 2 arguments")))))

(def PersistentList
  ((fn []
    (def first
      (fn [l]
        (fn []
          (aget l "$h"))))
    
    (def rest
      (fn [l]
        (fn []
          (aget l "$t"))))
    
    (def cons
      (fn [l]
        (fn [x]
          (PersistentList x l (+ 1 (.- l length))))))

    ;; constructor
    (fn [h t length]
      (def obj (object "$h" h "$t" t "length" length))
      (aset obj "first" (first obj))
      (aset obj "rest" (rest obj))
      (aset obj "cons" (cons obj))
      obj))))

(def first
  (fn [col]
    (cond
      (array? col) (aget col 0)
      :else
        (. col first))))

(def cons
  (fn [x col]
    (p col)
    (cond
      (array? col) (Array.prototype.contact.call col x)
      :else
        (. col (cons x)))))

(def empty-list (PersistentList nil nil 0))

(def ws.core/list
  (fn [&xs]
    (cond (identical? (.- xs length) 0) empty-list
          (identical? (.- xs length) 1) (cons (aget xs 0) empty-list)
          :else
            ((fn []
               (def l empty-list)
               (loop [i (- (.- xs length) 1)]
                 (cond (identical? i -1) nil
                       :else
                       ((fn []
                          (set! l (cons (aget xs i) l))
                          (recur (- i 1))))))
               l)))))

(def PersistentArrayMap
  ((fn []

      (fn [entries]
        (def obj (object "entries" entries "length" (. entries length)))
        obj)
     )))

(def ws.core/vector array)

;(p [1 2 3 4 5])

;(def xs (list 1 2 3 4 5))
;(p xs)
;(p (first xs))
;(p (list))
;(p (quote (1 2 3 4)))
;(p (List nil nil 0))

;; HAMT implementation blatantly stolen from (https://github.com/mattbierner/hamt/blob/master/lib/hamt.js)
;; Configuration

(def SIZE 5)
(def BUCKET_SIZE (Math.pow 2 SIZE))
(def MASK (- BUCKET_SIZE 1))
(def MAX_INDEX_NODE (div BUCKET_SIZE 2))
(def MIN_ARRAY_NODE (div BUCKET_SIZE 4))
(def nothing (Object.create nil))

(def constant (fn [x] (fn [] x)))

(def default-val-bind
  (fn [f default]
    (fn [&args]
      (f (cond (identical? (.- args length) 0) default :else (aget args 0))))))


(def str-hash
  (fn [s h]
    (cond
      (empty? s) h
      :else
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
    (cond
      (identical? type "number") x
      (not (identical? type "string")) (set! x (str x))
      :else (str-hash x 0))))

;(is 3556498 (hash "test"))
;(is 1 (hash 1))

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
;(is 145880092 h)
;(is 13 (popcount h))

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

(def array-update
  (fn [at v arr]
    (def len (.- arr length))
    (def out (new Array len))
    (loop [i 0]
      (cond (>= i len) out
            :else
              ((fn []
                (aset out i (aget arr i))
                (recur (+ i 1))))))
    (aset out at v)
    out))

;(def a (array 1 2 3 4))
;(p a)
;(p (array-update 2 5 a))

(def array-splice-out
  (fn [at arr]
    (. (. arr (slice 0 at)) (concat (. arr (slice (+ at 1) (.- arr length)))))))

;(def a (array 1 2 3 4))
;(p a)
;(p (array-splice-out 2 a))

(def array-splice-in
  (fn [at v arr]
    (def a (. arr (slice 0 at)))
    (. a (push v))
    (. a (concat (. arr (slice (+ at 1) (.- arr length)))))))

;(def a (array 1 2 3 4))
;(p a)
;(p (array-splice-in 2 5 a))

;; Node Structures

(def LEAF 1)
(def COLLISION 2)
(def INDEX 3)
(def ARRAY 4)

;(p (object "a" 1 "b" 2))

(def empty (object "__hamt_isEmpty" true))

(def Leaf
  (fn [hash key value]
    (object
      "type"  LEAF
      "hash"  hash
      "key"   key
      "value" value)))

(def Collision
  (fn [hash children]
    (object
      "type"     COLLISION
      "hash"     hash
      "children" children)))

(def IndexedNode
  (fn [mask children]
    (object
      "type"     INDEX
      "mask"     mask
      "children" children)))

(def ArrayNode
  (fn [size children]
    (object
      "type"     ARRAY
      "size"     size
      "children" children)))

(def leaf?
  (fn [node]
    (or (identical? node empty)
        (or (identical? (.- node type) LEAF)
            (identical? (.- node type) COLLISION)))))

;; Internal Node Operations

; expand an indexed node into an array node

(def expand
  (fn [frag child bitmap subnodes]
    (def arr (array))
    (def bit bitmap)
    (def count 0)
    (loop [i 0]
      (cond
        (not (bit-and bit 1))
          (aset arr i (aget subnodes count))
        :else
          ((fn []
             (aset arr i (aget subnodes count))
             (set! count (+ 1 count))
             (unsigned-bit-shift-right bit 1)
             (recur (+ 1 i))))))
    (ArrayNode (+ 1 count) arr)))
