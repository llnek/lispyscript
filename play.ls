
;(var a 5 b (+ 4 3) c (poo.foo (+ 6 8) (fred.jer 9 0)))
;(throw (new String (str "poo" (str "face"))))

;(get (poo.foo (+ 2 "2")) (+ 3 4) )

;(let (a (* 3 4) b (* a 2)) (+ a b) (.-poo console))
;(dotimes (a (* 3 4)) (+ 4 5) (console.log (str "a=" a)))
;(do-with (a (* 3 4)) (+ 4 5) (console.log (str "a=" a)))
;(bit-shift-right-zero 3 5 6)


(doMonad identityMonad (a (+ 1 2) b (+ 7 a)) (console.log (str a ", " b)))





