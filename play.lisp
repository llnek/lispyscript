
;(var a 5 b (+ 4 3) c (poo.foo (+ 6 8) (fred.jer 9 0)))
;(throw (new String (str "poo" (str "face"))))

;(get (poo.foo (+ 2 "2")) (+ 3 4) )

;(let (a (* 3 4) b (* a 2)) (+ a b) (.-poo console))
;(dotimes (a (* 3 5)) (+ 4 5) (console.log (str "a=" a)))
;(do-with (a (* 3 4)) (+ 4 5) (console.log (str "a=" a)))
;(bit-shift-right-zero 3 5 6)

(comment
(loop (result x) ([] 5)
  (if (= 0 x)
    result
    (do
      (result.push x)
      (recur result (dec x))))))


;(cond (> 2 0) "aaa" (< 5 4) "bbb" (> 6 7) "ccc" :else "sfsf")
;(when-some (poo (* 2 3)) (poo 4) (xxxxyz 4) (+ 2 3))
;(range 1 10 2)

(defn pset! [a? b] (str a? "5578787"))

(do 
  (var yy? (dfd* 33)
       poo (xxx? (+ (if yy? 2 4) 3)))
  (+ 2 3)
  (pset! yy? "444"))

(comment
(-> ($ "#xyz") (.required) (.alphanum) (.min 3) (.max 30) (.with "email"))
(doto ($ "#xyz") 
      (.required) 
      (.alphanum) 
      (.min 3) 
      (.max 30) 
      (.with "email")))

(while (< xyz (poo 34 6565))
  (var yy? (dfd* 33)
       poo (xxx? (+ (if yy? 2 4) 3)))
  (+ 2 73)
  (pset! yy? "444"))


(.create zzz [[a (+ 1 2) [ b 3] c]])
(try (throw 10) (catch err err))


