;; A template def for template test
(template testTemplate (one two three)
  "1" one "2" two "3" three)

;; A couple named (as opposed to anonymous) functions
(defn namedFn (x y)
  (+ x y))
(defn namedFnNoSpaceBeforeArgs(x y)
  (- x y))

;; Def testgroup name - lispyscript
;; tests lispyscript expressions

(testGroup lispyscript

(assert (true? true) "(true? true)")
(assert (false? false) "(false? false)")
(assert (false? (true? {})) "(false? (true? {}))")
(assert (undef? undefined) "(undefined? undefined)")
(assert (false? (undef? null)) "(false? (undefined? null))")
(assert (null? null) "(null? null)")
(assert (false? (null? undefined)) "(false? (null? undefined))")
(assert (zero? 0) "(zero? 0)")
(assert (false? (zero? "")) "(false? (zero? ''))")
(assert (boolean? true) "(boolean? true)")
(assert (false? (boolean? 0)) "(false? (boolean? 0))")
(assert (number? 1) "(number? 1)")
(assert (false? (number? "")) "(false? (number? ''))")
(assert (string? "") "(string? '')")
(assert (array? []) "(array? []])")
(assert (false? (array? {})) "(false? (array? {}))")
(assert (object? {}) "(object? {})")
(assert (false? (object? [])) "(object? [])")
(assert (false? (object? null)) "(false? (object? null))")
(assert (= 6 (+ 1 2 3)) "variadic arithmetic operator")
(assert (= true (> 3 2 1)) "variadic >")
(assert (= true (= 1 1 1)) "variadic =")
(assert (= false (!= 1 1 2)) "variadic !=")
(assert (= true (&& true true true)) "variadic logical operator")
(assert
  (= 10
    (when true
      (var ret 10)
      ret)) "when test")
(assert
  (= 10
    (unless false
      (var ret 10)
      ret)) "unless test")
(assert
  (= -10
    (do
      (var i -1)
      (cond
        (< i 0) -10
        (zero? i) 0
        (> i 0) 10))) "condition test less than")
(assert
  (= 10
    (do
      (var i 1)
      (cond
        (< i 0) -10
        (zero? i) 0
        (> i 0) 10))) "condition test greater than")
(assert
  (= 0
    (do
      (var i 0)
      (cond
        (< i 0) -10
        (zero? i) 0
        (> i 0) 10))) "condition test equal to")
(assert
  (= 10
    (do
      (var i Infinity)
      (cond
        (< i 0) -10
        (zero? i) 0
        true 10))) "condition test default")
(assert
  (= 10
    (loop (i 1)
      (if (= i 10)
        i
        (recur ++i)))) "loop recur test")
(assert
  (= 10
    (do
      (var ret 0)
      (each 
        (fn (val)
          (set! ret (+ ret val)))  
        [ 1 2 3 4])
      ret)) "each test")
(assert
  (= 10
    (do
      (var ret 0)
      (eachKey 
        (fn (val)
          (set! ret (+ ret val))) {a 1 b 2 c 3 d 4})
      ret)) "eachKey test")
(assert
  (= 10
    (reduce 
      (fn (accum val)
        (+ accum val)) 0
      [1 2 3 4])) "reduce test with init")
(assert
  (= 10
    (reduce
      (fn (accum val)
        (+ accum val)) 0 [1 2 3 4])) "reduce test without init")
(assert
  (= 20
    (reduce 
      (fn (accum val)
        (+ accum val)) 0
      (map (fn (val) (* val 2)) [1 2 3 4]))) "map test")
(assert (= "112233" (testTemplate 1 2 3)) "template test")
(assert (= "112233" (template-repeat-key {"1" 1 "2" 2 "3" 3} key value)) "template repeat key test")
(assert
  (= 10
    (try (var i 10) i (catch err err))) "try catch test - try block")
(assert
  (= 10
    (try (throw 10) (catch err err))) "try catch test - catch block")
(assert
  (= 3
    (do-monad m-identity (a 1 b (* a 2)) (+ a b))) "Identity Monad Test")
(assert
  (= 3
    (do-monad m-maybe (a 1 b (* a 2)) (+ a b))) "maybe Monad Test")
(assert
  (= null
    (do-monad m-maybe (a null b (* a 2)) (+ a b))) "maybe Monad null Test")
(assert
  (= 54
    (reduce
      (fn (accum val) (+ accum val))
      0
      (do-monad m-array (a [1 2 3] b [3 4 5]) (+ a b)))) "arrayMonad test")
(assert
  (= 32
    (reduce
      (fn (accum val) (+ accum val))
      0
      (do-monad m-array (a [1 2 3] b [3 4 5]) (when (<= (+ a b) 6) (+ a b))))) "arrayMonad when test")
(assert
  (= 6
    (reduce
      (fn (accum val) (+ accum val))
      0
      (do-monad m-array (a [1 2 0 null 3]) (when a a)))) "arrayMonad when null values test")
(assert
  (= 13
    (namedFn 7 6)) "named function test")
(assert
  (= 7
    (namedFnNoSpaceBeforeArgs 13 6)) "named function no space test")
)

;; Function for running on browser. This function is for
;; the test.html file in the same folder.
(defn browserTest ()
  (var el (document.getElementById "testresult"))
  (if el.outerHTML
    (set! el.outerHTML (str "<pre>" (testRunner lispyscript "LispyScript Testing") "</pre>"))
    (set! el.innerHTML (testRunner lispyscript "LispyScript Testing"))))

;; If not running on browser
;; call test runner with test group lispysript
;; otherwise call browserTest
(if (undef? window)
  (console.log (testRunner lispyscript "LispyScript Testing"))
  (set! window.onload browserTest))


