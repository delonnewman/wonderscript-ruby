(deftype Point
  [x y]
  (toString [this] (str "[" (.- this x) ", " (.- this y) "]")))

(p (. (new Point 1 3) toString))
