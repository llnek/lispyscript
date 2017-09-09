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

(defmacro unless [cond &rest] (when (! ~cond) ~&rest))

(defmacro when [cond &rest] (if ~cond (do ~&rest)))

(defmacro cond [&rest]
  (if (#<< &rest)
    (#<< &rest)
    (#if &rest (cond ~&rest))))

(defmacro arrayInit [len obj]
  ((fn [z o]
    (do-with [ret []]
    (js# "for (var i=0;i<z;++i) { ret.push(o); }"))) ~len ~obj))

(defmacro arrayInit2d [i j obj]
  ((fn [i j o]
    (do-with [ret []]
    (js# "for (var n=0;n<i;++n){let inn=[];for (var m=0;m<j;++m) {inn.push(o);} ret.push(inn);}"))) ~i ~j ~obj))

(defmacro -> [func form &rest]
  (#if &rest
    (-> ((#<< form) ~func ~@form) ~&rest)
    ((#<< form) ~func ~@form)))

;;(defmacro each [arr &rest] (.forEach ~arr ~&rest))
(defmacro each [func arr] (.forEach ~arr ~func))

;;(defmacro reduce [arr &rest] (.reduce ~arr ~&rest))
(defmacro reduce [func start arr] (.reduce ~arr ~func ~start))

(defmacro eachKey [func obj &rest]
  ((fn [o f s]
    (var _k (Object.keys o))
    (each 
      (fn [em]
        (f.call s (get o em) em o)) _k)) ~obj ~func ~&rest))

(defmacro each2d [arr func]
  (each 
    (fn [__e1 __i __a1]
      (each 
        (fn [__e2 __j __a2]
          (~func __e2 __j __i __a2 __a1)) __e1)) ~arr))

(defmacro map [func arr] (.map ~arr ~func))

(defmacro filter [&rest]
  (Array.prototype.filter.call ~&rest))

(defmacro some [&rest]
  (Array.prototype.some.call ~&rest))

(defmacro every? [&rest]
  (Array.prototype.every.call ~&rest))

(defmacro loop [bindings &rest]
  ((# (var recur nil
           __xs nil
           __f (fn [ (#odds* bindings) ] ~&rest)
           __ret __f)
      (set! recur
            (# (set! __xs arguments)
               (when (def? __ret)
                 (js# "for (__ret=undefined; __ret===undefined; __ret=__f.apply(this,__xs));")
                 __ret)))
      (recur (#evens* bindings)))))

(defmacro template [name pms &rest]
  (def ~name (fn [ ~@pms ] (str ~&rest))))

(defmacro template-repeat [arg &rest]
  (reduce
    (fn [__memo __elem __index __arr]
      (str __memo (str ~&rest))) "" ~arg))

(defmacro template-repeat-key [obj &rest]
  (do-with [__ret ""]
    (eachKey 
      (fn [value key]
        (set! __ret (str __ret (str ~&rest)))) ~obj)))

(defmacro sequence [name args init &rest]
  (var ~name
    (fn [ ~@args ]
      ((# ~@init
          (var next nil)
          (var __curr 0)
          (var __actions (new Array ~&rest))
          (set! next
            (# (var ne (get __actions ++__curr))
               (if ne ne (throw "Call to (next) beyond sequence."))))
          ((next)))))))

(defmacro assert [cond message]
  (if (true? ~cond)
    (str "Passed - " ~message)
    (str "Failed - " ~message)))

(defmacro testGroup [name &rest]
  (var ~name (# [ ~&rest ])))

(defmacro testRunner [groupname desc]
  ((fn [groupname desc]
    (var start (new Date)
         tests (groupname)
         passed 0
         failed 0)
    (each
      (fn [em]
        (if (em.match (new RegExp "^Passed"))
          (++ passed)
          (++ failed))) tests)
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
             (fn [accum val] (accum.concat val))
             []
             (map mf mv) ))
    unit (fn [v] [v])
    zero []
    plus (# (reduce
              (fn [accum val] (accum.concat val))
              []
              (Array.prototype.slice.call arguments)))))

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
(defmacro and [&rest] (&& ~&rest))
(defmacro or [&rest] (|| ~&rest))
(defmacro not [&rest] (! ~&rest))
(defmacro not= [&rest] (!= ~&rest))
(defmacro mod [&rest] (% ~&rest))
(defmacro nil? [&rest] (null? ~&rest))
(defmacro eq? [&rest] (== ~&rest))
(defmacro alen [arr] (.-length ~arr))
(defmacro eindex [arr] (- (.-length ~arr) 1))

(defmacro last [arr] (let [a ~arr]
                       (aget a (- (alen a) 1))))
(defmacro nth [arr pos] (aget ~arr ~pos))
(defmacro first [arr] (aget ~arr 0))
(defmacro second [arr] (aget ~arr 1))
(defmacro 2nd [arr] (aget ~arr 1))
(defmacro 1st [arr] (aget ~arr 0))

(defmacro cadr [arr] (aget ~arr 1))
(defmacro car [arr] (aget ~arr 0))


(defmacro bit-and [&rest] (& ~&rest))
(defmacro bit-or [&rest] (| ~&rest))
(defmacro bit-xor [&rest] (^ ~&rest))

(defmacro bit-shift-right-zero [&rest] (>>> ~&rest))
(defmacro bit-shift-right [&rest] (>> ~&rest))
(defmacro bit-shift-left [&rest] (<< ~&rest))

(defmacro # [&rest] (fn [] ~&rest))

(defmacro pos? [arg] (and (number? ~arg) (> ~arg 0)))

(defmacro neg? [arg] (and (number? ~arg) (< ~arg 0)))

(defmacro inc [x] (+ ~x 1))

(defmacro dec [x] (- ~x 1))

(defmacro when-not [cond &rest] (if (! ~cond) (do ~&rest)))

(defmacro if-not [cond then else] (if (! ~cond) ~then ~else))

(defmacro try! [&rest] (try ~&rest (catch e undefined)))

(defmacro let* [bindings expr]
  (do-monad m-identity ~bindings ~expr))

(defmacro let [bindings &rest] (do (var ~@bindings) ~&rest))

(defmacro do-with
  [binding &rest]
  (let ~binding (do ~&rest (#head binding))))

(defmacro do->false [&rest] (do ~&rest false))
(defmacro do->true [&rest] (do ~&rest true))
(defmacro do->nil [&rest] (do ~&rest nil))

(defmacro dotimes [binding &rest]
  (loop ((#head binding) 0 times (#tail binding))
    (when (> times (#head binding))
      ~&rest
      (recur (+ 1 (#head binding)) times))))

(defmacro constantly [x] (do (# ~x)))

(defmacro identity [x] (do ~x))

(defmacro if-some [binding then else]
  (do
    (var ~@binding)
    (if (some? (#head binding)) ~then ~else)))

(defmacro when-some [binding &rest]
  (do
    (var ~@binding)
    (when (some? (#head binding)) ~&rest)))

(defmacro repeat [n expr]
  (do (var __x ~expr)
      (repeat-n ~n __x)))

(defmacro concat [a b] (.concat ~a ~b))

(defmacro conj [c a] (.concat ~c [ ~a ]))

(defmacro not-empty [x] (if (and ~x (> (.-length ~x) 0)) ~x nil))
(defmacro empty? [x] (if ~x (= 0 (.-length ~x)) false))
(defmacro js-args? [] (> (.-length arguments) 0))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;EOF
(defmacro regexs [pattern glim] (new RegExp ~pattern ~glim))
(defmacro regex [pattern] (new RegExp ~pattern))
(defmacro values [obj] (Object.values ~obj))
(defmacro keys [obj] (Object.keys ~obj))
(defmacro toggle! [x] (set! ~x (not ~x)))
(defmacro jsargs! [] (Array.prototype.slice.call arguments))






