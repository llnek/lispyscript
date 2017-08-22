;; List of built in macros for LispyScript. This file is included by
;; default by the LispyScript compiler.


;;;;;;;;;;;;;;;;;;;; Conditionals ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defmacro undefined? (obj)
  (= (typeof ~obj) "undefined"))

(defmacro null? (obj)
  (= ~obj null))

(defmacro true? (obj)
  (= true ~obj))

(defmacro false? (obj)
  (= false ~obj))

(defmacro boolean? (obj)
  (= (typeof ~obj) "boolean"))

(defmacro zero? (obj)
  (= 0 ~obj))

(defmacro number? (obj)
  (= (Object.prototype.toString.call ~obj) "[object Number]"))

(defmacro string? (obj)
  (= (Object.prototype.toString.call ~obj) "[object String]"))

(defmacro array? (obj)
  (= (Object.prototype.toString.call ~obj) "[object Array]"))

(defmacro object? (obj)
  (= (Object.prototype.toString.call ~obj) "[object Object]"))

(defmacro function? (obj)
  (= (Object.prototype.toString.call ~obj) "[object Function]"))


;;;;;;;;;;;;;;;;;;;;;;; Expressions ;;;;;;;;;;;;;;;;;;;;

(defmacro do (&args)
  ((fn () ~&args)))

(defmacro when (cond &args)
  (if ~cond (do ~&args)))

(defmacro unless (cond &args)
  (when (! ~cond) (do ~&args)))

(defmacro cond (&args)
  (if (#<< &args) (#<< &args) (#if &args (cond ~&args))))

(defmacro arrayInit (len obj)
  ((fn (l o)
    (var ret [])
    (js# "for(var i=0;i<l;i++) ret.push(o);")
    ret) ~len ~obj))

(defmacro arrayInit2d (i j obj)
  ((fn (i j o)
    (var ret [])
    (js# "for(var n=0;n<i;n++){let inn=[];for(var m=0;m<j;m++) inn.push(o); ret.push(inn);}")
    ret) ~i ~j ~obj))

;; method chaining macro
(defmacro -> (func form &args)
  (#if &args
    (-> (((#<< form) ~func) ~@form) ~&args)
    (((#<< form) ~func) ~@form)))

;;;;;;;;;;;;;;;;;;;;;; Iteration and Looping ;;;;;;;;;;;;;;;;;;;;

(defmacro each (arr &args)
  ((.forEach ~arr) ~&args))

(defmacro reduce (arr &args)
  ((.reduce ~arr) ~&args))

(defmacro eachKey (obj func &args)
  ((fn (o f s)
    (var _k (Object.keys o))
    (each _k
      (fn (elem)
        (f.call s (get o elem) elem o)))) ~obj ~func ~&args))

(defmacro each2d (arr func)
  (each ~arr
    (fn (___elem ___i ___oa)
      (each ___elem
        (fn (___val ___j ___ia)
          (~func ___val ___j ___i ___ia ___oa))))))

(defmacro map (arr &args)
  ((.map ~arr) ~&args))

(defmacro filter (&args)
  (Array.prototype.filter.call ~&args))

(defmacro some (&args)
  (Array.prototype.some.call ~&args))

(defmacro every (&args)
  (Array.prototype.every.call ~&args))

(defmacro loop (args vals &args)
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

(defmacro for (&args)
  (doMonad arrayMonad ~&args))


;;;;;;;;;;;;;;;;;;;; Templates ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defmacro template (name args &args)
  (def ~name
    (fn ~args
      (str ~&args))))

(defmacro template-repeat (arg &args)
  (reduce ~arg
    (fn (___memo elem index)
      (+ ___memo (str ~&args))) ""))

(defmacro template-repeat-key (obj &args)
  (do
    (var ___ret "")
    (eachKey ~obj
      (fn (value key)
        (set! ___ret (+ ___ret (str ~&args)))))
    ___ret))


;;;;;;;;;;;;;;;;;;;; Callback Sequence ;;;;;;;;;;;;;;;;;;;;;

(defmacro sequence (name args init &args)
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

(defmacro assert (cond message)
  (if (true? ~cond)
    (+ "Passed - " ~message)
    (+ "Failed - " ~message)))

(defmacro testGroup (name &args)
  (var ~name
    (fn ()
      (array ~&args))))

(defmacro testRunner (groupname desc)
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

(defmacro identityMonad ()
  (object
    mBind (fn (mv mf) (mf mv))
    mResult (fn (v) v)))

(defmacro maybeMonad ()
  (object
    mBind (fn (mv mf) (if (null? mv) null (mf mv)))
    mResult (fn (v) v)
    mZero null))

(defmacro arrayMonad ()
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

(defmacro stateMonad ()
  (object
    mBind (fn (mv f)
              (fn (s)
                (var l (mv s)
                     v (get l 0)
                     ss (get l 1))
                ((f v) ss)))
    mResult (fn (v) (fn (s) [v, s]))))

(defmacro continuationMonad ()
  (object
    mBind (fn (mv mf)
              (fn (c)
                (mv
                  (fn (v)
                    ((mf v) c)))))
    mResult (fn (v)
                (fn (c)
                  (c v)))))

(defmacro m-bind (bindings expr)
  (mBind (#slice@2 bindings)
    (fn ((#<< bindings))
      (#if bindings (m-bind ~bindings ~expr) ((fn () ~expr))))))

(defmacro withMonad (monad &args)
  ((fn (___monad)
    (var mBind ___monad.mBind
         mResult ___monad.mResult
         mZero ___monad.mZero
         mPlus ___monad.mPlus)
    ~&args) (~monad)))

(defmacro doMonad (monad bindings expr)
  (withMonad ~monad
    (var ____mResult
      (fn (___arg)
        (if (&& (undefined? ___arg) (! (undefined? mZero)))
          mZero
          (mResult ___arg))))
    (m-bind ~bindings (____mResult ~expr))))

(defmacro monad (name obj) (def ~name (fn () ~obj)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;clojure-like

(defmacro and (&args) (&& ~&args))
(defmacro or (&args) (|| ~&args))
(defmacro not (&args) (! ~&args))
(defmacro not= (&args) (!= ~&args))
(defmacro mod (&args) (% ~&args))
(defmacro nil? (&args) (null? ~&args))

(defmacro bit-and (&args) (& ~&args))
(defmacro bit-or (&args) (| ~&args))
(defmacro bit-xor (&args) (^ ~&args))

(defmacro bit-shift-right-zero (&args) (>>> ~&args))
(defmacro bit-shift-right (&args) (>> ~&args))
(defmacro bit-shift-left (&args) (<< ~&args))

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

(defmacro let* (bindings expr)
  (doMonad identityMonad ~bindings ~expr))

(defmacro let (bindings &args)
  (do
    (var ~@bindings)
    ~&args))

(defmacro do-with
  (bind-one &args)
  (let ~bind-one (do ~&args (#head ~bind-one))))

(defmacro do->false (&args) (do ~&args false))
(defmacro do->true (&args) (do ~&args true))
(defmacro do->nil (&args) (do ~&args nil))

(defmacro dotimes (bind-one &args)
  (loop ((#head ~bind-one) times)
        (0 (#tail ~bind-one))
    (if (> times (#head ~bind-one))
      (do ~&args (recur (+ (#head ~bind-one) 1) times)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;EOF

