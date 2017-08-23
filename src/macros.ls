;; List of built in macros for LispyScript. This file is included by
;; default by the LispyScript compiler.


;;;;;;;;;;;;;;;;;;;; Conditionals ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defmacro some? (obj)
  (not (or (undef? obj) (null? obj))))

(defmacro def? (obj)
  (not= (typeof ~obj) "undefined"))

(defmacro undef? (obj)
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

(defmacro loop (bind-args vals &args)
  ((#
    (var ___ret !undefined
         ___xs null
         recur null
         ___f (fn ~bind-args ~&args))
    (set! recur
      (fn ()
        (set! ___xs arguments)
        (when (def? ___ret)
          (set! ___ret undefined)
          (js# "while (___ret===undefined) ___ret=___f.apply(this,___xs);")
          ___ret)))
    (recur ~@vals))))

(defmacro for (&args)
  (do-monad m-array ~&args))


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

(defmacro m-identity ()
  (object
    bind (fn (mv mf) (mf mv))
    unit (fn (v) v)))

(defmacro m-maybe ()
  (object
    bind (fn (mv mf) (if (null? mv) null (mf mv)))
    unit (fn (v) v)
    zero null))

(defmacro m-array ()
  (object
    bind (fn (mv mf)
              (reduce
                (map mv mf)
                (fn (accum val) (accum.concat val))
                []))
    unit (fn (v) [v])
    zero []
    plus (#
          (reduce
            (Array.prototype.slice.call arguments)
            (fn (accum val) (accum.concat val))
            []))))

(defmacro m-state ()
  (object
    bind (fn (mv f)
              (fn (s)
                (var l (mv s)
                     v (get l 0)
                     ss (get l 1))
                ((f v) ss)))
    unit (fn (v) (fn (s) [v, s]))))

(defmacro m-continuation ()
  (object
    bind (fn (mv mf)
              (fn (c)
                (mv
                  (fn (v)
                    ((mf v) c)))))
    unit (fn (v)
                (fn (c)
                  (c v)))))

(defmacro m-bind (binder bindings expr)
  (~binder (#slice@2 bindings)
    (fn ((#<< bindings))
      (#if bindings
        (m-bind ~binder ~bindings ~expr)
        ((# ~expr))))))

(defmacro do-monad (monad bindings expr)
  ((fn (___m)
    (var ___u
         (fn (v)
           (if (and (undef? v)
                    (def? ___m.zero))
             ___m.zero
             (___m.unit v))))
    (m-bind ___m.bind ~bindings (___u ~expr)))(~monad)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;clojure-like

(defmacro defmonad (name obj) (def ~name (# ~obj)))

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

(defmacro inc (x) (+ ~x 1))

(defmacro dec (x) (- ~x 1))

(defmacro when-not
  (cond &args)
  (if (! ~cond) (do ~&args)))

(defmacro if-not
  (cond &args)
  (if (! ~cond) ~&args))

(defmacro try! (&args)
  (try ~&args (fn () )))

(defmacro let* (bindings expr)
  (do-monad m-identity ~bindings ~expr))

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
      (do ~&args (recur (inc (#head ~bind-one)) times)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;EOF

