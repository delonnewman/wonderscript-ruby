(def ws.core/RecursionPoint
  (fn [args]
    (def obj (Object.create nil))
    (set! (.- obj $ws$lang$tag) "RecursionPoint")
    (set! (.- obj args) args)
    obj))

(def p (console.log.bind))

(loop [i 0]
  (p i)
  (cond 
    (identical? i 10000) nil
    :else
      (recur (+ 1 i))))
