(comment
(var x [ 1 2 3 ])
(var x [])
(var x [[1 2 (* 2 3) [4 5]]])

(var x { a 1 b 2 c 3 })
(var x {})
(var x { z { a 1 b { c 2 }  d (fn () (* 3 4))}})
(m-identity))
;;(let (a [1 2 3] b [3 4 5]) (+ a b))

(do-monad m-array (a [1 2 3] b [3 4 5]) (+ a b))


