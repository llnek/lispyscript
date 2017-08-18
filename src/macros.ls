;; List of built in macros for LispyScript. This file is included by
;; default by the LispyScript compiler.


;;;;;;;;;;;;;;;;;;;; Conditionals ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(macro undefined? (obj)
  (= (typeof ~obj) "undefined"))

(macro null? (obj)
  (= ~obj null))

(macro true? (obj)
  (= true ~obj))

(macro false? (obj)
  (= false ~obj))

(macro boolean? (obj)
  (= (typeof ~obj) "boolean"))

(macro zero? (obj)
  (= 0 ~obj))

(macro number? (obj)
  (= (Object.prototype.toString.call ~obj) "[object Number]"))

(macro string? (obj)
  (= (Object.prototype.toString.call ~obj) "[object String]"))

(macro array? (obj)
  (= (Object.prototype.toString.call ~obj) "[object Array]"))

(macro object? (obj)
  (= (Object.prototype.toString.call ~obj) "[object Object]"))

(macro function? (obj)
  (= (Object.prototype.toString.call ~obj) "[object Function]"))


;;;;;;;;;;;;;;;;;;;;;;; Expressions ;;;;;;;;;;;;;;;;;;;;

(macro do (rest...)
  ((fn () ~rest...)))

(macro when (cond rest...)
  (if ~cond (do ~rest...)))

(macro unless (cond rest...)
  (when (! ~cond) (do ~rest...)))

(macro cond (rest...)
  (if (#args-shift rest...) (#args-shift rest...) (#args-if rest... (cond ~rest...))))

(macro arrayInit (len obj)
  ((fn (l o)
    (var ret [])
    (js# "for(var i=0;i<l;i++) ret.push(o);")
    ret) ~len ~obj))

(macro arrayInit2d (i j obj)
  ((fn (i j o)
    (var ret [])
    (js# "for(var n=0;n<i;n++){var inn=[];for(var m=0;m<j;m++) inn.push(o); ret.push(inn);}")
    ret) ~i ~j ~obj))

;; method chaining macro
(macro -> (func form rest...)
  (#args-if rest...
    (-> (((#args-shift form) ~func) ~@form) ~rest...)
    (((#args-shift form) ~func) ~@form)))

;;;;;;;;;;;;;;;;;;;;;; Iteration and Looping ;;;;;;;;;;;;;;;;;;;;

(macro each (arr rest...)
  ((.forEach ~arr) ~rest...))

(macro reduce (arr rest...)
  ((.reduce ~arr) ~rest...))

(macro eachKey (obj func rest...)
  ((fn (o f s)
    (var _k (Object.keys o))
    (each _k
      (fn (elem)
        (f.call s (get o elem) elem o)))) ~obj ~func ~rest...))

(macro each2d (arr func)
  (each ~arr
    (fn (___elem ___i ___oa)
      (each ___elem
        (fn (___val ___j ___ia)
          (~func ___val ___j ___i ___ia ___oa))))))

(macro map (arr rest...)
  ((.map ~arr) ~rest...))

(macro filter (rest...)
  (Array.prototype.filter.call ~rest...))

(macro some (rest...)
  (Array.prototype.some.call ~rest...))

(macro every (rest...)
  (Array.prototype.every.call ~rest...))

(macro loop (args vals rest...)
  ((fn ()
    (var recur null
         ___result !undefined
         ___nextArgs null
         ___f (fn ~args ~rest...))
    (set! recur
      (fn ()
        (set! ___nextArgs arguments)
        (if (= ___result undefined)
          undefined
          (do
            (set! ___result undefined)
            (js# "while(___result===undefined) ___result=___f.apply(this,___nextArgs);")
            ___result))))
    (recur ~@vals))))

(macro for (rest...)
  (doMonad arrayMonad ~rest...))


;;;;;;;;;;;;;;;;;;;; Templates ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(macro template (name args rest...)
  (def ~name
    (fn ~args
      (str ~rest...))))

(macro template-repeat (arg rest...)
  (reduce ~arg
    (fn (___memo elem index)
      (+ ___memo (str ~rest...))) ""))

(macro template-repeat-key (obj rest...)
  (do
    (var ___ret "")
    (eachKey ~obj
      (fn (value key)
        (set! ___ret (+ ___ret (str ~rest...)))))
    ___ret))


;;;;;;;;;;;;;;;;;;;; Callback Sequence ;;;;;;;;;;;;;;;;;;;;;

(macro sequence (name args init rest...)
  (var ~name
    (fn ~args
      ((fn ()
        ~@init
        (var next null)
        (var ___curr 0)
        (var ___actions (new Array ~rest...))
        (set! next
          (fn ()
            (var ne (get ___actions ___curr++))
            (if ne
              ne
              (throw "Call to (next) beyond sequence."))))
        ((next)))))))


;;;;;;;;;;;;;;;;;;; Unit Testing ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(macro assert (cond message)
  (if (true? ~cond)
    (+ "Passed - " ~message)
    (+ "Failed - " ~message)))

(macro testGroup (name rest...)
  (var ~name
    (fn ()
      (array ~rest...))))

(macro testRunner (groupname desc)
  ((fn (groupname desc)
    (var start (new Date)
         tests (groupname)
         passed 0
         failed 0)
    (each tests
      (fn (elem)
        (if (elem.match /^Passed/)
          ++passed
          ++failed)))
    (str
      (str "\n" desc "\n" start "\n\n")
      (template-repeat tests elem "\n")
      "\nTotal tests " tests.length
      "\nPassed " passed
      "\nFailed " failed
      "\nDuration " (- (new Date) start) "ms\n")) ~groupname ~desc))


;;;;;;;;;;;;;;;; Monads ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(macro identityMonad ()
  (object
    mBind (fn (mv mf) (mf mv))
    mResult (fn (v) v)))

(macro maybeMonad ()
  (object
    mBind (fn (mv mf) (if (null? mv) null (mf mv)))
    mResult (fn (v) v)
    mZero null))

(macro arrayMonad ()
  (object
    mBind (fn (mv mf)
              (reduce
                (map mv mf)
                (fn (accum val) (accum.concat val))
                []))
    mResult (fn (v) [v])
    mZero []
    mPlus (fn ()
              (reduce
                (Array.prototype.slice.call arguments)
                (fn (accum val) (accum.concat val))
                []))))

(macro stateMonad ()
  (object
    mBind (fn (mv f)
              (fn (s)
                (var l (mv s)
                     v (get l 0)
                     ss (get l 1))
                ((f v) ss)))
    mResult (fn (v) (fn (s) [v, s]))))

(macro continuationMonad ()
  (object
    mBind (fn (mv mf)
              (fn (c)
                (mv
                  (fn (v)
                    ((mf v) c)))))
    mResult (fn (v)
                (fn (c)
                  (c v)))))

(macro m-bind (bindings expr)
  (mBind (#args-second bindings)
    (fn ((#args-shift bindings))
      (#args-if bindings (m-bind ~bindings ~expr) ((fn () ~expr))))))

(macro withMonad (monad rest...)
  ((fn (___monad)
    (var mBind ___monad.mBind
         mResult ___monad.mResult
         mZero ___monad.mZero
         mPlus ___monad.mPlus)
    ~rest...) (~monad)))

(macro doMonad (monad bindings expr)
  (withMonad ~monad
    (var ____mResult
      (fn (___arg)
        (if (&& (undefined? ___arg) (! (undefined? mZero)))
          mZero
          (mResult ___arg))))
    (m-bind ~bindings (____mResult ~expr))))

(macro monad (name obj) (def ~name (fn () ~obj)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;clojure-like

(defmacro and (rest...) (&& ~rest...))
(defmacro or (rest...) (|| ~rest...))
(defmacro not (rest...) (! ~rest...))
(defmacro not= (rest...) (!= ~rest...))
(defmacro mod (rest...) (% ~rest...))
(defmacro nil? (rest...) (null? ~rest...))

(defmacro #
  (rest...)
  (fn () ~rest...))

(defmacro pos?
  (arg)
  (and (number? ~arg) (> ~arg 0)))

(defmacro neg?
  (arg)
  (and (number? ~arg) (< ~arg 0)))

(defmacro when-not
  (cond rest...)
  (if (! ~cond) (do ~rest...)))

(defmacro if-not
  (cond rest...)
  (if (! ~cond) ~rest...))

(defmacro try! (rest...)
  (try ~rest... (fn () )))

(defmacro let* (names vals rest...)
  ((fn ~names ~rest...) ~@vals))

(defmacro do-with
  (obj expr rest...)
  (let* (~obj) (~expr) ~rest... ~obj))

(defmacro do->false (rest...) (do ~rest... false))
(defmacro do->true (rest...) (do ~rest... true))
(defmacro do->nil (rest...) (do ~rest... nil))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;EOF

