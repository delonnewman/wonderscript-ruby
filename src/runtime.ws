; vim: ft=clojure
;(def mori (require "mori"))
(require "google-closure-library")

; (ns ws.core)
(goog.provide "ws.core")
(def ws.core/CURRENT_NS ws.core)

(def RecursionPoint (fn []))

(def str
  (fn []
    (. ((.- (.- (.- Array prototype) slice) call) arguments) (join ""))))

(def say (. console.log bind))

(say (str 1 2 3))

(def array
  (fn []
    (Array.prototype.slice.call arguments)))
