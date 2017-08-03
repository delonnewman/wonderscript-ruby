; vim: ft=clojure
(def mori (require "mori"))

(def ws.core/RecursionPoint (fn []))

(def ws.core/str
  (fn []
    (. (Array.prototype.slice.call arguments) (join ""))))

(def ws.core/say (. console.log bind))

(def say ws.core/say)

(say (ws.core/str 1 2 3))

(def map* (fn [x] x))
(say (map* 1))

