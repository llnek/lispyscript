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

(macro do (&args)
  ((fn () ~&args)))

(macro when (cond &args)
  (if ~cond (do ~&args)))

(macro unless (cond &args)
  (when (! ~cond) (do ~&args)))

(macro cond (&args)
  (if (#args-shift &args) (#args-shift &args) (#args-if &args (cond ~&args))))

(macro arrayInit (len obj)
  ((fn (l o)
    (var ret [])
    (js# "for(var i=0;i<l;i++) ret.push(o);")
    ret) ~len ~obj))

(macro arrayInit2d (i j obj)
  ((fn (i j o)
    (var ret [])
    (js# "for(var n=0;n<i;n++){let inn=[];for(var m=0;m<j;m++) inn.push(o); ret.push(inn);}")
    ret) ~i ~j ~obj))

;; method chaining macro
(macro -> (func form &args)
  (#args-if &args
    (-> (((#args-shift form) ~func) ~@form) ~&args)
    (((#args-shift form) ~func) ~@form)))

;;;;;;;;;;;;;;;;;;;;;; Iteration and Looping ;;;;;;;;;;;;;;;;;;;;

(macro each (arr &args)
  ((.forEach ~arr) ~&args))

(macro reduce (arr &args)
  ((.reduce ~arr) ~&args))

(macro eachKey (obj func &args)
  ((fn (o f s)
    (var _k (Object.keys o))
    (each _k
      (fn (elem)
        (f.call s (get o elem) elem o)))) ~obj ~func ~&args))

(macro each2d (arr func)
  (each ~arr
    (fn (___elem ___i ___oa)
      (each ___elem
        (fn (___val ___j ___ia)
          (~func ___val ___j ___i ___ia ___oa))))))

(macro map (arr &args)
  ((.map ~arr) ~&args))

(macro filter (&args)
  (Array.prototype.filter.call ~&args))

(macro some (&args)
  (Array.prototype.some.call ~&args))

(macro every (&args)
  (Array.prototype.every.call ~&args))

(macro loop (args vals &args)
  ((fn ()
    (var recur null
         ___result !undefined
         ___nextArgs null
         ___f (fn ~args ~&args))
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

(macro for (&args)
  (doMonad arrayMonad ~&args))


;;;;;;;;;;;;;;;;;;;; Templates ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(macro template (name args &args)
  (def ~name
    (fn ~args
      (str ~&args))))

(macro template-repeat (arg &args)
  (reduce ~arg
    (fn (___memo elem index)
      (+ ___memo (str ~&args))) ""))

(macro template-repeat-key (obj &args)
  (do
    (var ___ret "")
    (eachKey ~obj
      (fn (value key)
        (set! ___ret (+ ___ret (str ~&args)))))
    ___ret))


;;;;;;;;;;;;;;;;;;;; Callback Sequence ;;;;;;;;;;;;;;;;;;;;;

(macro sequence (name args init &args)
  (var ~name
    (fn ~args
      ((fn ()
        ~@init
        (var next null)
        (var ___curr 0)
        (var ___actions (new Array ~&args))
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

(macro testGroup (name &args)
  (var ~name
    (fn ()
      (array ~&args))))

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

(macro withMonad (monad &args)
  ((fn (___monad)
    (var mBind ___monad.mBind
         mResult ___monad.mResult
         mZero ___monad.mZero
         mPlus ___monad.mPlus)
    ~&args) (~monad)))

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

(defmacro and (&args) (&& ~&args))
(defmacro or (&args) (|| ~&args))
(defmacro not (&args) (! ~&args))
(defmacro not= (&args) (!= ~&args))
(defmacro mod (&args) (% ~&args))
(defmacro nil? (&args) (null? ~&args))

(defmacro #
  (&args)
  (fn () ~&args))

(defmacro pos?
  (arg)
  (and (number? ~arg) (> ~arg 0)))

(defmacro neg?
  (arg)
  (and (number? ~arg) (< ~arg 0)))

(defmacro when-not
  (cond &args)
  (if (! ~cond) (do ~&args)))

(defmacro if-not
  (cond &args)
  (if (! ~cond) ~&args))

(defmacro try! (&args)
  (try ~&args (fn () )))

(defmacro let (bindings expr)
  (doMonad identityMonad ~bindings ~expr))

(defmacro do-with
  (bind-one &args)
  (let ~bind-one (do ~&args (#args-peek bind-one))))

(defmacro do->false (&args) (do ~&args false))
(defmacro do->true (&args) (do ~&args true))
(defmacro do->nil (&args) (do ~&args nil))


(defmacro dotimes (bind-one &args)
  (loop ((#args-peek bind-one) times)
        (0 (#args-pook bind-one))
    (if (> times (#args-peek bind-one))
      (do ~&args (recur (+ (#args-peek bind-one) 1) times)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;EOF

