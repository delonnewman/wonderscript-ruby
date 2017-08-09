; vim: ft=clojure
1
:a
:user/a
(quote a)
(quote user/a)
true
false
nil
(p "hello")
{:a 1 :b 2}
{:a {:b 1} :c {:d {:e 1} :f 2}}
[1 2 3 4]
(+ 1 2 3 4 5)
(- 1 2 3 4 5)
(< 0 9)
(fn [x] x)
(cond 1 2 :else 3)
(cond 1 (cond 1 2) :else 3)
(def x 1)
(def ws.core/x 1)
(def ws.core/identity (fn [x] x))
