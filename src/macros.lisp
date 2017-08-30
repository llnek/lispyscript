;; List of built in macros for LispyScript. This file is included by
;; default by the LispyScript compiler.

(defmacro whatis? [obj]
  (Object.prototype.toString.call ~obj))

(defmacro string? [obj]
  (= (whatis? ~obj) "[object String]"))

(defmacro fn? [obj]
  (= (whatis? ~obj) "[object Function]"))

(defmacro date? [obj]
  (= (whatis? ~obj) "[object Date]"))

(defmacro number? [obj]
  (= (whatis? ~obj) "[object Number]"))

(defmacro regex? [obj]
  (= (whatis? ~obj) "[object RegExp]"))

(defmacro boolean? [obj]
  (= (whatis? ~obj) "[object Boolean]"))

(defmacro array? [obj]
  (= (whatis? ~obj) "[object Array]"))

(defmacro vector? [obj]
  (= (whatis? ~obj) "[object Array]"))

(defmacro list? [obj]
  (= (whatis? ~obj) "[object Array]"))

(defmacro object? [obj]
  (= (whatis? ~obj) "[object Object]"))

(defmacro null? [obj]
  (= (whatis? ~obj) "[object Null]"))

(defmacro undef? [obj]
  (= (typeof ~obj) "undefined"))

(defmacro some? [obj]
  (not (or (undef? ~obj) (null? ~obj))))

(defmacro def? [obj] (not (undef? ~obj)))

(defmacro true? [obj] (= true ~obj))

(defmacro false? [obj] (= false ~obj))

(defmacro zero? [obj] (= 0 ~obj))

(defmacro -= [x y] (dec! ~x ~y))
(defmacro += [x y] (inc! ~x ~y))

(defmacro -- [x] (dec!! ~x))
(defmacro ++ [x] (inc!! ~x))

(defmacro unless [cond &args] (when (! ~cond) ~&args))

(defmacro when [cond &args] (if ~cond (do ~&args)))

(defmacro cond [&args]
  (if (#<< &args)
    (#<< &args)
    (#if &args (cond ~&args))))

(defmacro arrayInit [len obj]
  ((fn [z o]
    (do-with [ret []]
    (js# "for (var i=0;i<z;++i) { ret.push(o); }"))) ~len ~obj))

(defmacro arrayInit2d [i j obj]
  ((fn [i j o]
    (do-with [ret []]
    (js# "for (var n=0;n<i;++n){let inn=[];for (var m=0;m<j;++m) {inn.push(o);} ret.push(inn);}"))) ~i ~j ~obj))

(defmacro -> [func form &args]
  (#if &args
    (-> ((#<< form) ~func ~@form) ~&args)
    ((#<< form) ~func ~@form)))

(defmacro each [arr &args] (.forEach ~arr ~&args))

(defmacro reduce [arr &args] (.reduce ~arr ~&args))

(defmacro eachKey [obj func &args]
  ((fn [o f s]
    (var _k (Object.keys o))
    (each _k
      (fn [em]
        (f.call s (get o em) em o)))) ~obj ~func ~&args))

(defmacro each2d [arr func]
  (each ~arr
    (fn [__e1 __i __a1]
      (each __e1
        (fn [__e2 __j __a2]
          (~func __e2 __j __i __a2 __a1))))))

(defmacro map [arr &args] (.map ~arr ~&args))

(defmacro filter [&args]
  (Array.prototype.filter.call ~&args))

(defmacro some? [&args]
  (Array.prototype.some.call ~&args))

(defmacro every? [&args]
  (Array.prototype.every.call ~&args))

(defmacro loop [bindings &args]
  ((# (var recur nil
           __xs nil
           __f (fn [ (#odds* bindings) ] ~&args)
           __ret __f)
      (set! recur
            (# (set! __xs arguments)
               (when (def? __ret)
                 (js# "for (__ret=undefined; __ret===undefined; __ret=__f.apply(this,__xs));")
                 __ret)))
      (recur (#evens* bindings)))))

(defmacro template [name pms &args]
  (def ~name (fn [ ~@pms ] (str ~&args))))

(defmacro template-repeat [arg &args]
  (reduce ~arg
    (fn [__memo __elem __index __arr]
      (str __memo (str ~&args))) ""))

(defmacro template-repeat-key [obj &args]
  (do-with [__ret ""]
    (eachKey ~obj
      (fn [value key]
        (set! __ret (str __ret (str ~&args)))))))

(defmacro sequence [name args init &args]
  (var ~name
    (fn [ ~@args ]
      ((# ~@init
          (var next nil)
          (var __curr 0)
          (var __actions (new Array ~&args))
          (set! next
            (# (var ne (get __actions ++__curr))
               (if ne ne (throw "Call to (next) beyond sequence."))))
          ((next)))))))

(defmacro assert [cond message]
  (if (true? ~cond)
    (str "Passed - " ~message)
    (str "Failed - " ~message)))

(defmacro testGroup [name &args]
  (var ~name (# [ ~&args ])))

(defmacro testRunner [groupname desc]
  ((fn [groupname desc]
    (var start (new Date)
         tests (groupname)
         passed 0
         failed 0)
    (each tests
      (fn [em]
        (if (em.match (new RegExp "^Passed"))
          (++ passed)
          (++ failed))))
    (str
      (str "\n" desc "\n" start "\n\n")
      (template-repeat tests __elem "\n")
      "\nTotal tests " tests.length
      "\nPassed " passed
      "\nFailed " failed
      "\nDuration " (- (new Date) start) "ms\n")) ~groupname ~desc))

(defmacro m-identity []
  (hash-map
    bind (fn [mv mf] (mf mv))
    unit (fn [v] v)))

(defmacro m-maybe []
  (hash-map
    bind (fn [mv mf] (if (nil? mv) nil (mf mv)))
    unit (fn [v] v)
    zero nil))

(defmacro m-array []
  (hash-map
    bind (fn [mv mf]
           (reduce
             (map mv mf)
             (fn [accum val] (accum.concat val))
             []))
    unit (fn [v] [v])
    zero []
    plus (# (reduce
              (Array.prototype.slice.call arguments)
              (fn [accum val] (accum.concat val))
              []))))

(defmacro m-state []
  (hash-map
    bind (fn [mv f]
           (fn [s]
             (var l (mv s)
                  v (get l 0)
                  ss (get l 1))
             ((f v) ss)))
    unit (fn [v] (fn [s] [v s]))))

(defmacro m-continuation []
  (hash-map
    bind (fn [mv mf]
           (fn [c]
             (mv (fn [v] ((mf v) c)))))
    unit (fn [v]
           (fn [c] (c v)))))

(defmacro m-bind [binder bindings expr]
  (~binder (#slice@2 bindings)
    (fn [ (#<< bindings) ]
      (#if bindings
        (m-bind ~binder ~bindings ~expr)
        ((# ~expr))))))

(defmacro do-monad [monad bindings expr]
  ((fn [__m]
    (var __u (fn [v]
               (if (and (undef? v)
                        (def? __m.zero))
                 __m.zero
                 (__m.unit v))))
    (m-bind __m.bind ~bindings (__u ~expr))) (~monad)))

(defmacro defmonad [name obj] (def ~name (# ~obj)))
(defmacro and [&args] (&& ~&args))
(defmacro or [&args] (|| ~&args))
(defmacro not [&args] (! ~&args))
(defmacro not= [&args] (!= ~&args))
(defmacro mod [&args] (% ~&args))
(defmacro nil? [&args] (null? ~&args))
(defmacro eq? [&args] (== ~&args))
(defmacro alen [arr] (.-length ~arr))
(defmacro eindex [arr] (- (.-length ~arr) 1))

(defmacro last [arr] (let [a ~arr]
                       (aget a (- (alen a) 1))))
(defmacro nth [arr pos] (aget ~arr ~pos))
(defmacro first [arr] (aget ~arr 0))
(defmacro 1st [arr] (aget ~arr 0))
(defmacro second [arr] (aget ~arr 1))
(defmacro 2nd [arr] (aget ~arr 1))

(defmacro bit-and [&args] (& ~&args))
(defmacro bit-or [&args] (| ~&args))
(defmacro bit-xor [&args] (^ ~&args))

(defmacro bit-shift-right-zero [&args] (>>> ~&args))
(defmacro bit-shift-right [&args] (>> ~&args))
(defmacro bit-shift-left [&args] (<< ~&args))

(defmacro # [&args] (fn [] ~&args))

(defmacro pos? [arg] (and (number? ~arg) (> ~arg 0)))

(defmacro neg? [arg] (and (number? ~arg) (< ~arg 0)))

(defmacro inc [x] (+ ~x 1))

(defmacro dec [x] (- ~x 1))

(defmacro when-not [cond &args] (if (! ~cond) (do ~&args)))

(defmacro if-not [cond &args] (if (! ~cond) ~&args))

(defmacro try! [&args] (try ~&args (catch e undefined)))

(defmacro let* [bindings expr]
  (do-monad m-identity ~bindings ~expr))

(defmacro let [bindings &args] (do (var ~@bindings) ~&args))

(defmacro do-with
  [binding &args]
  (let ~binding (do ~&args (#head binding))))

(defmacro do->false [&args] (do ~&args false))
(defmacro do->true [&args] (do ~&args true))
(defmacro do->nil [&args] (do ~&args nil))

(defmacro dotimes [binding &args]
  (loop ((#head binding) 0 times (#tail binding))
    (when (> times (#head binding))
      ~&args
      (recur (+ 1 (#head binding)) times))))

(defmacro constantly [x] (do (# ~x)))

(defmacro identity [x] (do ~x))

(defmacro if-some [binding then else]
  (do
    (var ~@binding)
    (if (some? (#head binding)) ~then ~else)))

(defmacro when-some [binding &args]
  (do
    (var ~@binding)
    (when (some? (#head binding)) ~&args)))

(defmacro repeat [n expr]
  (do (var __x ~expr)
      (repeat-n ~n __x)))

(defmacro concat [a b] (.concat ~a ~b))

(defmacro conj [c a] (.concat ~c [ ~a ]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;EOF

