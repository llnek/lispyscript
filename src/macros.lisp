;; List of built in macros for LispyScript. This file is included by
;; default by the LispyScript compiler.


;;;;;;;;;;;;;;;;;;;; Conditionals ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defmacro whatis? (obj)
  (Object.prototype.toString.call ~obj))

(defmacro string? (obj)
  (= (whatis? ~obj) "[object String]"))

(defmacro fn? (obj)
  (= (whatis? ~obj) "[object Function]"))

(defmacro date? (obj)
  (= (whatis? ~obj) "[object Date]"))

(defmacro number? (obj)
  (= (whatis? ~obj) "[object Number]"))

(defmacro regex? (obj)
  (= (whatis? ~obj) "[object RegExp]"))

(defmacro boolean? (obj)
  (= (whatis? ~obj) "[object Boolean]"))

(defmacro array? (obj)
  (= (whatis? ~obj) "[object Array]"))
(defmacro vector? (obj)
  (= (whatis? ~obj) "[object Array]"))

(defmacro object? (obj)
  (= (whatis? ~obj) "[object Object]"))

(defmacro null? (obj)
  (= (whatis? ~obj) "[object Null]"))

(defmacro undef? (obj)
  (= (typeof ~obj) "undefined"))

(defmacro some? (obj)
  (not (or (undef? ~obj) (null? ~obj))))

(defmacro def? (obj) (not (undef? ~obj)))

(defmacro true? (obj)
  (= true ~obj))

(defmacro false? (obj)
  (= false ~obj))

(defmacro zero? (obj)
  (= 0 ~obj))

;;;;;;;;;;;;;;;;;;;;;;; Expressions ;;;;;;;;;;;;;;;;;;;;

(defmacro unless (cond &args) (when (! ~cond) ~&args))

(defmacro when (cond &args) (if ~cond (do ~&args)))

;(defmacro do (&args) ((# ~&args)))

(defmacro cond (&args)
  (if (#<< &args)
    (#<< &args)
    (#if &args (cond ~&args))))

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

(defmacro -> (func form &args)
  (#if &args
    (-> ((#<< form) ~func ~@form) ~&args)
    ((#<< form) ~func ~@form)))

;;;;;;;;;;;;;;;;;;;;;; Iteration and Looping ;;;;;;;;;;;;;;;;;;;;

(defmacro each (arr &args)
  (.forEach ~arr ~&args))

(defmacro reduce (arr &args)
  (.reduce ~arr ~&args))

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
  (.map ~arr ~&args))

(defmacro filter (&args)
  (Array.prototype.filter.call ~&args))

(defmacro some (&args)
  (Array.prototype.some.call ~&args))

(defmacro every (&args)
  (Array.prototype.every.call ~&args))

(defmacro loop (bind-args bind-vals &args)
  ((# (var recur nil ___xs nil
           ___f (fn ~bind-args ~&args) ___ret ___f)
      (set! recur
            (# (set! ___xs arguments)
               (when (def? ___ret)
                 (js# "for (___ret=undefined; ___ret===undefined; ___ret=___f.apply(this,___xs));")
                 ___ret)))
      (recur ~@bind-vals))))


;(defmacro for (&args) (do-monad m-array ~&args))

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
      ((# ~@init
          (var next nil)
          (var ___curr 0)
          (var ___actions (new Array ~&args))
          (set! next
            (# (var ne (get ___actions ++___curr))
               (if ne ne (throw "Call to (next) beyond sequence."))))
          ((next)))))))

;;;;;;;;;;;;;;;;;;; Unit Testing ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defmacro assert (cond message)
  (if (true? ~cond)
    (str "Passed - " ~message)
    (str "Failed - " ~message)))

(defmacro testGroup (name &args)
  (var ~name (# (array ~&args))))

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
(defmacro eq? (&args) (== ~&args))
(defmacro alen (arr) (.-length ~arr))
(defmacro eindex (arr) (- (.-length ~arr) 1))

(defmacro last (arr) (let (a ~arr)
                       (aget a (- (alen a) 1))))
(defmacro nth (arr pos) (aget ~arr ~pos))
(defmacro first (arr) (aget ~arr 0))
(defmacro 1st (arr) (aget ~arr 0))
(defmacro second (arr) (aget ~arr 1))
(defmacro 2nd (arr) (aget ~arr 1))

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

(defmacro try! (&args) (try ~&args (catch e undefined)))

(defmacro let* (bindings expr)
  (do-monad m-identity ~bindings ~expr))

(defmacro let (bindings &args)
  (do
    (var ~@bindings)
    ~&args))

(defmacro do-with
  (bind-one &args)
  (let ~bind-one (do ~&args (#head bind-one))))

(defmacro do->false (&args) (do ~&args false))
(defmacro do->true (&args) (do ~&args true))
(defmacro do->nil (&args) (do ~&args nil))

(defmacro dotimes (bind-one &args)
  (loop ((#head bind-one) times)
        (0 (#tail bind-one))
    (when (> times (#head bind-one))
      ~&args
      (recur (inc (#head bind-one)) times))))

(defmacro constantly (x) (do (# ~x)))

(defmacro identity (x) (do ~x))

(defmacro if-some (bind-one then else)
  (do
    (var (#head bind-one)
         (#tail bind-one))
    (if (some? (#head bind-one))
      ~then
      ~else)))

(defmacro when-some (bind-one &args)
  (do
    (var (#head bind-one)
         (#tail bind-one))
    (when (some? (#head bind-one)) ~&args)))

(defmacro repeat (n expr)
  (do (var _x ~expr)
      (repeat-n ~n _x)))

(defmacro count* (x)
      (if (or (array? ~x)
              (string? ~x))
        (.-length ~x)
        (if (object? ~x)
          (.-length (Object.keys ~x)) 0)))

(defmacro count (x)
  (do (var _x ~x) (count* _x)))

(defmacro empty? (x)
  (do (var _x ~x)
      (if (some? _x) (zero? (count* _x)) true)))

(defmacro concat (a b) (.concat ~a ~b))

(defmacro conj (c a) (.concat ~c (array ~a)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;EOF

