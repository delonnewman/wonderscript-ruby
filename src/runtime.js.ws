; vim: ft=clojure
"use strict"

;; Practical, Simple, Flexible

(def p (. console.log bind))

(deftype ws.core/RecursionPoint [args])

(cond (not (identical? (typeof module.exports) "undefined"))
      (set! module.exports ws.core))

(def ws.core/str
  (fn [&args]
    (. (Array.prototype.slice.call args) (join ""))))
(def str ws.core/str)

(def ws.core/nil?
  (fn [x]
    (identical? nil x)))
(def nil? ws.core/nil?)

(def ws.core/empty?
  (fn [x]
    (cond
      (nil? x) true
      (identical? (count x) 0) true
      :else
        false)))
(def empty? ws.core/empty?)

(def ws.core/count
  (fn [x]
    (cond
      (nil? x) 0
      (.- x length) (.- x length)
      :else
        (loop [i 0, x (first x), xs (rest x)]
          (cond
            (nil? x) i
            :else
              (recur (+ 1 i) (first x) (rest x)))))))
(def count ws.core/count)

(def ws.core/is
  (fn [expected actual]
    (cond (identical? expected actual) nil
          :else
            (throw (str "FAILURE: " expected " is not equal to " actual)))))
(def is ws.core/is)

(def ws.core/array
  (fn [& args]
    (Array.prototype.slice.call args)))
(def array ws.core/array)

(def ws.core/array?
  (fn [x]
    (identical? (Object.prototype.toString.call x) "[object Array]")))
(def array? ws.core/array?)

(def amap
  (fn [f a]
    (Array.prototype.map.call a f)))
(def ws.core/amap amap)

(def areduce
  (fn [f a init]
    (Array.prototype.reduce.call a f init)))
(def ws.core/areduce areduce)

(def afilter
  (fn [f a]
    (Array.prototype.filter.call a f)))
(def ws.core/afilter afilter)

(def ws.core/object
  (fn [& args]
    (def obj (Object.create nil))
    (loop [i 0]
      (cond
        (identical? i (.- args length)) nil
        :else
          ((fn []
            (aset obj (aget args i) (aget args (+ 1 i)))
            (recur (+ 2 i))))))
    obj))
(def object ws.core/object)

(deftype Keyword [namespace name])

(def ws.core/keyword
  (fn [& xs]
    (cond (identical? (.- xs length) 1) (new Keyword nil (aget xs 0))
          (identical? (.- xs length) 2) (new Keyword (aget xs 0) (aget xs 1))
          :else
            (throw (new Error "expected either 1 or 2 arguments")))))

(def ws.core/keyword?
  (fn [x]
    (instance? x Keyword)))

(def ws.core/namespace
  (fn [x]
    (.- x namespace)))

(def ws.core/name
  (fn [x]
    (.- x name)))

(deftype Symbol [namespace name])

(def ws.core/symbol
  (fn [& xs]
    (cond (identical? (.- xs length) 1) (new Symbol nil (aget xs 0))
          (identical? (.- xs length) 2) (new Symbol (aget xs 0) (aget xs 1))
          :else
            (throw (new Error "expected either 1 or 2 arguments")))))
(def symbol ws.core/symbol)

(def ws.core/symbol?
  (fn [x]
    (instance? x ws.core/Symbol)))
(def symbol? ws.core/symbol?)

(deftype PersistentList [h t length]
  (first [l] (.- l h))
  (rest [l] (.- l t))
  (cons [l x] (new PersistentList x l (+ 1 (.- l length)))))

(def first
  (fn [col]
    (cond
      (array? col) (aget col 0)
      :else
        (. col first))))
(def ws.core/first first)

(def rest
  (fn [col]
    (cond
      (array? col) (. col (slice 1))
      :else
        (. col rest))))
(def ws.core/rest rest)

(def cons
  (fn [x col]
    (cond
      (array? col) (Array.prototype.concat.call col x)
      :else
        (. col (cons x)))))
(def ws.core/cons cons)

(def ws.core/empty-list (new PersistentList nil nil 0))
(def empty-list ws.core/empty-list)

(def ws.core/list
  (fn [& xs]
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
(def list ws.core/list)

(def ws.core/list?
  (fn [x]
    (instance? x PersistentList)))
(def list? ws.core/list?)

(def map
  (fn [f col]
    (cond
      (empty? col) col
      :else
        (loop [l empty-list, x (first col), xs (rest col)]
          (cond
            (nil? x) l
            :else
              (recur (cons (f x) l) (first xs) (rest xs)))))))
(def ws.core/map map)

(def reverse
  (fn [col]
    (loop [l empty-list, x (first col), xs (rest col)]
      (cond
        (nil? x) l
        :else
          (recur (cons x l) (first xs) (rest xs))))))
(def ws.core/reverse reverse)

;(p [1 2 3 4 5])

;(def xs (list 1 2 3 4 5))
;(p xs)
;(p (first xs))
;(p (list))
;(p (quote (1 2 3 4)))
;(p (List nil nil 0))

(def ws.core/inc
  (fn [x]
    (+ 1 x)))

(def ws.core/dec
  (fn [x]
    (- x 1)))

(def ws.core/sum
  (fn [& xs]
    (cond (empty? xs) 0
          (identical? 1 (count xs)) (first xs)
          :else
            (loop [x (first xs) sum 0]
              (cond (nil? x) sum
                    :else
                      (recur (first xs) (+ sum x)))))))
