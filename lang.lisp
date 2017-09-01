;; Copyright (c) 2013-2017, Kenneth Leung. All rights reserved.
;; The use and distribution terms for this software are covered by the
;; Eclipse Public License 1.0 (http:;;opensource.org;licenses;eclipse-1.0.php)
;; which can be found in the file epl-v10.html at the root of this distribution.
;; By using this software in any fashion, you are agreeing to be bound by
;; the terms of this license.
;; You must not remove this notice, or any other, from this software.

(ns ^{:doc ""
      :author "Kenneth Leung" }

  czlab.kirby.lang)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(def- TreeNode (.-SourceNode (require "source-map")))
(def- fs nil path nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(when (undef? window)
  (set! path (require "path"))
  (set! fs (require "fs")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(def- VERSION "1.0.0"
      includePaths []
      noSemi? false
      indentSize 2
      VARGS "&args"
      TILDA "~"
      indentWidth -indentSize
      TILDA-VARGS (str TILDA VARGS))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(def- REGEX
  { macroGet (new RegExp "^#slice@(\\d+)")
    noret (new RegExp "^def\\b|^var\\b|^set!\\b|^throw\\b")
    id (new RegExp "^[a-zA-Z_$][?\\-*!0-9a-zA-Z_$]*$")
    id2 (new RegExp "^[*][?\\-*!0-9a-zA-Z_$]+$")
    func (new RegExp "^function\\b")
    query (new RegExp "\\?" "g")
    bang (new RegExp "!" "g")
    dash (new RegExp "-" "g")
    star (new RegExp "\\*" "g")
    wspace (new RegExp "\\s") })

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(def- SPECIAL-OPS {})
(def- MACROS_MAP {})
(def- ERRORS_MAP {
  e0 "Syntax Error"
  e1 "Empty statement"
  e2 "Invalid characters in function name"
  e3 "End of File encountered, unterminated string"
  e4 "Closing square bracket, without an opening square bracket"
  e5 "End of File encountered, unterminated array"
  e6 "Closing curly brace, without an opening curly brace"
  e7 "End of File encountered, unterminated javascript object '}'"
  e8 "End of File encountered, unterminated parenthesis"
  e9 "Invalid character in var name"
  e10 "Extra chars at end of file. Maybe an extra ')'."
  e11 "Cannot Open include File"
  e12 "Invalid no of arguments to "
  e13 "Invalid Argument type to "
  e14 "End of File encountered, unterminated regular expression"
  e15 "Invalid vararg position, must be last argument."
  e16 "Invalid arity (args > expected) to "
  e17 "Invalid arity (args < expected) to " })

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- eval?? [x]
  (if (list? x) (evalList ~x) ~x))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- conj!! [tree obj]
  (if obj (.push tree obj)) tree)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- testid [name]
  (or (REGEX.id.test name) (REGEX.id2.test name)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- normalizeId [name]
  (var pfx "")
  (if (and (string? name)
           (= '-' (.charAt name 0)))
    (set! pfx "-")
    (set! name (.slice name 1)))
  (if (testid name)
    (str pfx (-> (.replace name REGEX.query "_QUERY")
                 (.replace REGEX.bang "_BANG")
                 (.replace REGEX.dash "_")
                 (.replace REGEX.star "_STAR")))
    (if (= pfx "") name (str pfx name))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- assert [cond msg]
  (if-not cond (throw (new Error msg))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- node? [obj]
  (and (object? obj)
       (true? (get obj "$$$isSourceNode$$$"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- error! [e line file msg]
  (throw
    (new Error
         (str (get ERRORS-MAP e)
              (if msg (str " : " msg))
              (if line (str "\nLine no " line))
              (if file (str "\nFile " file))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(def- attr-file "_file")
(def- attr-line "_line")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- syntax! [c expr cmd]
  (error! c
          (get expr attr-line)
          (get expr attr-file) cmd))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defmacro assertArgs [expr cnt ecode msg]
  (if (not= (alen ~expr) ~cnt) (syntax! ~ecode ~expr ~msg)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- pad [z] (.repeat " " z))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;use this function to generate code, we need to escape out funny
;;chars in names
(defn- tnodeString []
  (do-with [s ""]
    (.walk this
           (fn [chunk hint]
             (if (and (= (.-name hint) chunk)
                      (string? chunk))
               (set! chunk (normalizeId chunk)))
             (inc! s chunk)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- tnode [ln col src chunk name]
  (do-with [n nil]
    (if (js-args?)
      (set! n
            (if name
              (new TreeNode ln col src chunk name)
              (new TreeNode ln col src chunk)))
      (set! n (new TreeNode)))
    (set! n toString tnodeString)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- tnodeChunk [chunk name] (tnode nil nil nil chunk name))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- toASTree [code fname]
  (var codeStr (str "(" code ")")
       state { file fname
               lineno 1
               colno 1
               pos 1
               tknCol 1})
  (do-with [ret (lexer codeStr state)]
    (if (< (.-pos state) (alen codeStr)) (error! :e10))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- parseTree [root]

  (var pstr ""
       endx (eindex root)
       treeSize (alen root))

  (inc! indentWidth indentSize)
  (set! pstr (pad indentWidth))

  (do-with [ret (tnode)]
    (each root
          (fn [expr i tree]
            (var name "" tmp nil r "")
            (if (list? expr)
              (let [e (nth expr 0)]
                (if (node? e)
                  (set! name (.-name e)))
                (set! tmp  (evalList expr))
                (when (= name "include")
                  (.add ret tmp)
                  (set! tmp nil)))
              (set! tmp expr))
            (if (and (= i endx)
                     (not= 0 indentWidth)
                     (not (REGEX.noret.test name)))
              (set! r "return "))
            (when tmp
              (.add ret [ (str pstr r)
                          tmp
                          (if-not noSemi? ";") "\n" ])
              (set! noSemi? false))))
    (dec! indentWidth indentSize)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- evalList2 [expr]

  (var s nil ename "")
  (evalConCells expr)
  (set! ename (nth expr 0))
  (if-not ename
    (syntax! :e1 expr))
  (if (REGEX.fn.test ename)
    (set! ename (tnodeChunk ["(" ename ")"])))
  (tnodeChunk [ename "("
               (-> (.slice expr 1)
                   (tnodeChunk )
                   (.join  ",")) ")"]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- evalList [expr]

  (var cmd "" tmp nil mc nil)

  (cond
    (true? (.-_object expr)) (set! cmd "{")
    (true? (.-_array expr)) (set! cmd "[")
    (and (not-empty expr)
         (node? (nth expr 0)))
    (do (set! cmd (.-name (1st expr)))
        (set! mc (get MACROS-MAP cmd))))

  (cond
    (some? mc) (eval?? (evalMacro mc expr))
    (string? cmd)
    (cond
      (.startsWith cmd ".-")
      (do-with [ret (tnode)]
        (.add ret (eval?? (nth expr 1)))
        (.prepend ret "(")
        (.add ret [")[\"" (.slice cmd 2) "\"]"]))
      (= (.charAt cmd 0) '.')
      (do-with [ret (tnode)]
        (.add ret (eval?? (nth expr 1)))
        (.add ret [(1st expr) "("])
        (for ((i 2) (< i (alen expr)) (i (inc i)))
          (if (not= i 2) (.add ret ","))
          (.add ret (eval?? (nth expr i))))
        (.add ret ")"))
      (.hasOwnProperty SPECIAL-OPS cmd)
      ((get SPECIAL-OPS cmd) expr)
      :else
      (evalList2 expr))
    :else
    (evalList2 expr)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- evalConCells [cells]
  (each cells
        (fn [cell i cc]
          (if (list? cell) (set! cc i (evalList cell))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- expandMacro [code data]
  (var ret [] ename "" s1name "" tmp nil)
  (set! ret "_filename" (get data "_filename"))
  (set! ret "_line" (get data "_line"))
  (when (and (list? code)
             (> (alen code) 1))
   (set! s1name (.-name (nth code 1)))
   (set! frag (get frags (str TILDA s1name))))
  (if (and (list? code)
           (not-empty code))
   (set! ename (.-name (1st code))))
  ;;deal with array and object literals
  (cond
    (true? (.-_object code))
    (set! ret "_object" true)
    (true? (.-_array code))
    (set! ret "_array" true))
  ;;the magic
  (cond
    (= ename "#<<")
    (if-not (list? frag)
      (syntax! :e13 data cmd)
      (.shift frag))
    ;;
    (= ename "#head")
    (if-not (list? frag)
      (syntax! :e13 data cmd)
      (if (not-empty frag) (1st frag)))
    ;;
    (= ename "#tail")
    (if-not (list? frag)
      (syntax! :e13 data cmd)
      (if (not-empty frag) (last frag)))
    ;;=> 0,2,4...
    (.startsWith ename "#evens")
    (do-with [r []]
      (for ((i 0) (< i (alen frag)) (i (+ i 2)))
        (conj!! r (nth frag i)))
      (if (.endsWith ename "*") (set! r "___split" true)))
    ;;=> 1,3,5...
    (.startsWith ename "#odds")
    (do-with [r []]
      (for ((i 1) (< i (alen frag)) (i (+ i 2)))
        (conj!! r (nth frag i)))
      (if (.endsWith ename "*") (set! r "___split" true)))
    ;;
    (.startsWith ename "#slice@")
    (do
      (if-not (list? frag) (syntax! :e13 data cmd))
      (set! tmp (REGEX.macroGet.exec ename))
      (1st (.splice frag (dec (nth tmp 1)) 1)))
    ;;
    (= ename "#if")
    (do
      (if-not (list? frag) (syntax! :e13 data cmd))
      (cond
        (not-empty frag) (expand (nth code 2))
        (and (> (alen code) 3)
             (nth code 3)) (expand (nth code 3))
        :else undefined))
    ;;
    :else
    (let [cell nil]
      (for ((i 0) (< i (alen code)) (i (inc i)))
        (set! cell (nth code i))
        (if (list? cell)
          (let [c (expandMacro cell)]
            (if (and (list? c)
                     (true? (get c "___split")))
              (for ((k 0) (< k (alen c)) (k (inc k)))
                (conj!! ret (nth c k)))
              (conj!! ret c)))
          ;;else
          (let [tn (.-name cell)
                atSign? false]
            (set! tmp cell)
            (when (.includes tn "@")
              (set! atSign? true)
              (set! tmp
                    (tnode (.-line token)
                           (.-column token)
                           (.-source token)
                           (.replace tn "@" "")
                           (.replace tn "@" ""))))
            (if-some [repl (get frags (.-name tmp))]
              (do (if (or atSign?
                          (= (.-name tmp) TILDA-VARGS))
                    (for ((j 0) (< j (alen repl)) (j (inc j)))
                      (conj!! ret (nth repl j)))
                    (conj!! ret repl)))
              (conj!! ret cell)))))
      ret)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- evalMacro [mc data]
  (var args (get mc "args")
       cmd (get mc "name")
       code (get mc "code")
       vargs false
       tpos 0
       i 0
       frags {})

  ;;map all args to actual data, say &args -> rest of the data
  ;;tpos is always one ahead to skip out the macro cmd
  (for ((i 0 tpos (inc i))
        (< i (alen args)) (i (inc i) tpos (inc i)))
    (if (= (.-name (nth args i)) VARGS)
      (do (set! vargs true)
          (set! frags TILDA-VARGS (.slice data tpos)))
      (set! frags
            (str TILDA (.-name (nth args i)))
            (if (>= tpos (alen data))
              (tnodeChunk "undefined") (nth data tpos)))))

  ;;check if enough args were supplied to the macro
  (if (and (not vargs)
           (< (+ i 1) (alen data))) (syntax! :e16 data cmd))

  (expandMacro code data))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-compOp [expr]
  (if (< (alen expr) 3) (syntax! :e0 expr))
  (evalConCells expr)
  ;; dont use === as it is a source node
  (if (eq? (1st expr) "!=") (set! expr 0  "!=="))
  (if (eq? (1st expr) "=") (set! expr 0 "==="))
  (do-with [ret (tnode)]
    (for ((i 0 op (.shift expr))
          (< i (- (alen expr) 1)) (i (inc i)))
      (.add ret (tnodeChunk [(nth expr i) " "
                                          op
                                          " "
                                          (nth expr (inc i))])))
    (.join ret " && ")
    (.prepend ret "(")
    (.add ret ")")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(each ["!=" "==" "=" ">" ">=" "<" "<="]
      (fn [k]
          (set! SPECIAL-OPS k sf-compOp)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-arithOp [expr]
  (if (< (alen expr) 3) (syntax! :e0 expr))
  (evalConCells expr)
  (var op (tnode))
  (do-with [ret (tnode)]
    (.add op [" " (.shift expr) " "])
    (.add ret expr)
    (.join ret op)
    (.prepend ret "(")
    (.add ret ")")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(each ["+" "-" "*" "/" "%"]
      (fn [k] (set! SPECIAL-OPS k sf-arithOp)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-logicalOp [expr] (sf-arithOp expr))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(each ["||" "&&" "^" "|" "&" ">>>" ">>" "<<"]
      (fn [k] (set! SPECIAL-OPS k sf-logicalOp)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-repeat [expr]
  (if (not= (alen expr) 3) (syntax! :e0 expr))
  (evalConCells expr)
  (do-with [ret (tnode)]
    (for ((i 0
           end (parseInt (.-name (nth expr 1))))
          (< i end)
          (i (inc i)))
      (if (not= i 0) (.add ret ","))
      (.add ret (nth expr 2)))
    (.prepend ret "[")
    (.add ret "]")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "repeat-n" sf-repeat)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-do [expr]
  (var end (eindex expr)
       e nil p (pad indentWidth))
  (do-with [ret (tnode)]
    (for ((i 1) (< i end) (i (inc i)))
      (set! e (nth expr i))
      (.add ret [p (evalList e) ";\n"]))
    (when (> end 0)
      (set! e (eval?? (last expr)))
      (.add ret [p "return " e ";\n"])
      (.prepend ret (str p "(function() {\n"))
      (.add ret (str p "})()")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "do" sf-do)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-doto [expr]

  (if (< (alen expr) 2) (syntax! :e0 expr))

  (var p (pad indentWidth)
       p2 (pad (+ indentWidth indentSize))
       p3 (pad (+ indentWidth (* 2 indentSize)))
       e nil
       e1 (eval?? (nth expr 1)))
  (do-with [ret (tnode)]
    (.add ret [p2 "let ___x = " e1 ";\n"])
    (for ((i 2) (< i (alen expr)) (i (inc i)))
      (set! e (nth expr i))
      (.splice e 1 0 "___x")
      (.add ret [p3 (evalList e) ";\n"]))
    (.add ret [p2 "return ___x;\n"])
    (.prepend ret (str p "(function() {\n"))
    (.add ret (str p "})()"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "doto" s-doto)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-range [expr]

  (if (or (< (alen expr) 2 )
          (> (alen expr) 4)) (syntax! :e0 expr))

  (var len 0 start 0 step 1 end 0)
  (evalConCells expr)
  (set! len (alen expr))
  (set! end (parseInt (.-name (nth expr 1))))
  (do-with [ret (tnode)]
    (when (> len 2)
      (set! start (parseInt (.-name (nth expr 1))))
      (set! end (parseInt (.-name (nth expr 2)))))
    (if (> len 3)
      (set! step (parseInt (.-name (nth expr 3)))))
    (for ((i start) (< i end) (i (+ i step)))
      (if (not= i start) (.add ret ","))
      (.add ret (str "" i)))
    (.prepend ret "[")
    (.add ret "]")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "range" sf-range)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-var [expr cmd]

  (if (or (< (alen expr) 3)
          (= 0 (mod (alen expr) 2))) (syntax! :e0 expr))

  (if (> (alen expr) 3)
    (inc! indentWidth indentSize))

  (evalConCells expr)
  (do-with [ret (tnode)]
    (for ((i 1) (< i (alen expr)) (i (+ i 2)))
      (if (> i 1)
        (.add ret (str ",\n" (pad indentWidth))))
      (if-not (testid (nth expr i)) (syntax! :e9 expr))
      (.add ret [(nth expr i) " = " (nth expr (inc i))]))
    (.prepend ret " ")
    (.prepend ret cmd)
    (if (> (alen expr) 3)
      (dec! indentWidth indentSize))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "var" (fn [x] (sf-var x "let")))
(set! SPECIAL-OPS "def" (fn [x] (sf-var x "var")))
(set! SPECIAL-OPS "def-" (get SPECIAL-OPS "def"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-new [expr]
  (if (< (alen expr) 2) (syntax! :e0 expr))
  (do-with [ret (tnode)]
    (.add ret (evalList (.slice expr 1)))
    (.prepend ret "new ")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "new" sf-new)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-throw [expr]
  (assertArgs expr 2 :e0)
  (do-with [ret (tnode)]
    (.add ret (eval?? (nth expr 1)))
    (.prepend ret "throw ")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "throw" sf-throw)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-while [expr]
  (var f1 (nth expr 1))
  (.splice expr 0 2 (tnodeChunk "do" "do"))
  (tnodeChunk ["while "
               (eval?? f1)
               " {\n" (evalList expr) ";\n}\n"]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "while" sf-while)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-x-opop [expr op]
  (if (not= (alen expr) 2) (syntax! :e0 expr))
  (tnodeChunk [op (eval?? (nth expr 1))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "dec!!" (fn [x] (sf-x-opop x "--")))
(set! SPECIAL-OPS "inc!!" (fn [x] (sf-x-opop x "++")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-x-eq [expr op]
  (if (not= (alen expr) 3) (syntax! :e0 expr))
  (tnodeChunk [(nth expr 1)
               (str " " op "= ")
               (eval?? (nth expr 2))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "dec!" (fn [x] (sf-x-eq x "-")))
(set! SPECIAL-OPS "inc!" (fn [x] (sf-x-eq x "+")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-set [expr]
  (if (or (< (alen expr) 3)
          (> (alen expr) 4)) (syntax! :e0 expr))
  (when (= (alen expr) 4)
    (if (list? (nth expr 1))
      (set! expr 1 (evalList (nth expr 1))))
    (if (list? (nth expr 2))
      (set! expr 2 (evalList (nth expr 2))))
    (set! expr 1 (str (nth expr 1) "[" (nth expr 2) "]"))
    (set! expr 2 (nth expr 3)))
  (tnodeChunk [(nth expr 1)
               " = "
               (eval?? (nth expr 2))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "set!" sf-set)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-anonFunc [expr]
  (if (< (alen expr) 2) (syntax! :e0 expr))
  (if-not (list? (nth expr 1)) (syntax! :e0 expr))
  (var fArgs (nth expr 1)
       fBody (.slice expr 2))
  (do-with [ret (tnodeChunk fArgs)]
    (.join ret ",")
    (.prepend ret "function (")
    (.add ret [") {\n"
               (parseTree fBody)
               (pad indentWidth) "}"])))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "fn" sf-anonFunc)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-func [expr public?]
  (if (< (alen expr) 2) (syntax! :e0 expr))
  (var fName nil
       fArgs nil fBody nil)
  (do-with [ret nil]
    (if (and (not (list? (nth expr 1)))
             (list? (nth expr 2)))
      (do
        (set! fName (normalizeId (.-name (nth expr 1))))
        (set! fArgs (nth expr 2))
        (set! fBody (.slice expr 3)))
      (syntax! :e0 expr))
    (set! ret (tnodeChunk fArgs))
    (.join ret ",")
    (.prepend ret (str "function " fName "("))
    (.add ret [") {\n"
               (parseTree fBody)
               (pad indentWidth) "}"])
    (set! noSemi? true)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "defn-" (fn [x] (sf-func x false)))
(set! SPECIAL-OPS "defn" (fn [x] (sf-func x true)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-try [expr]
  (var sz (alen expr)
       t nil
       f nil
       c nil
       ind (pad indentWidth))
  ;;look for finally
  (set! f (last expr))
  (if (and (list? f)
           (= (.-name (1st f)) "finally"))
    (do (set! f (.pop expr))
        (set! sz (alen expr)))
    (set! f nil))
  ;;look for catch
  (set! c (if (> sz 1) (nth expr (dec sz)) nil))
  (if (and (list? c)
           (= (.-name (1st c)) "catch"))
    (do
      (if (or (< (alen c) 2)
              (not (node? (nth c 1)))) (syntax! :e0 expr))
      (set! c (.pop expr)))
    (set! c nil))
  ;;try needs either a catch or finally or both
  (if (and (nil? f)
           (nil? c)) (syntax! :e0 expr))
  (do-with [ret (tnodeChunk
                  [(str "(function() {\n"
                        ind "try {\n")
                   (parseTree (.slice expr 1))
                   (str "\n" ind "} ") ])]
    (when c
      (set! t (nth c 1))
      (.splice c 0 2 (tnodeChunk "do" "do"))
      (.add ret [(str "catch (" t ") {\n")
                 "return "
                 (evalList c) (str ";\n" ind "}\n")]))
    (when f
      (.splice f 0 1 (tnodeChunk "do" "do"))
      (.add ret ["finally {\n"
                 (evalList f)
                 (str ";\n" ind "}\n") ]))
    (.add ret (str ind "})()"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "try" sf-try)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-if [expr]
  (if (or (< (alen expr) 3)
          (> (alen expr) 4)) (syntax! :e0 expr))
  (inc! indentWidth indentSize)
  (evalConCells expr)
  (try
    (tnodeChunk ["("
                 (nth expr 1)
                 (str " ?\n" (pad indentWidth))
                 (nth expr 2)
                 (str " :\n" (pad indentWidth))
                 (or (nth expr 3) "undefined") ")"])
    (finally
      (dec! indentWidth indentSize))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "if" sf-if)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-get [expr]
  (assertArgs expr 3 :e0)
  (evalConCells expr)
  (tnodeChunk [(nth expr 1) "[" (nth expr 2) "]"]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "get" sf-get)
(set! SPECIAL-OPS "aget" (get SPECIAL-OPS "get"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-str [expr]
  (if (< (alen expr) 2) (syntax! :e0 expr))
  (evalConCells expr)
  (do-with [ret (tnode)]
    (.add ret (.slice expr 1))
    (.join ret ",")
    (.prepend ret "[")
    (.add ret "].join('')")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "str" sf-str)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-array [expr]
  (var p (pad indentWidth)
       epilog (str "\n" p "]"))
  (do-with [ret (tnode)]
    (if (empty? expr)
      (.add ret "[]")
      (try
        (if-not (true? (.-_array expr))
          (.splice expr 0 1))
        (inc! indentWidth indentSize)
        (evalConCells expr)
        (set! p (pad indentWidth))
        (.add ret (str "[\n" p))
        (for ((i 0) (< i (alen expr)) (i (inc i)))
          (if (> i 0)
            (.add ret (str ",\n" p)))
          (.add ret (nth expr i)))
        (.add ret epilog)
        (finally
          (dec! indentWidth indentSize))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "[" sf-array)
(set! SPECIAL-OPS "vec" (get SPECIAL-OPS "["))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-object [expr]
  (var p (pad indentWidth)
       epilog (str "\n" p "}"))
  (do-with [ret (tnode)]
    (if (empty? expr)
      (.add ret "{}")
      (try
        (if-not (true? (.-_object expr))
          (.splice expr 0 1))
        (inc! indentWidth indentSize)
        (evalConCells expr)
        (set! p (pad indentWidth))
        (.add ret (str "{\n" p))
        (for ((i 0) (< i (alen expr)) (i (+ i 2)))
          (if (> i 0)
            (.add ret (str ",\n" p)))
          (.add ret [(nth expr i) ": " (nth expr (inc i))]))
        (.add ret epilog)
        (finally
          (dec! indentWidth indentSize))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "{" sf-object)
(set! SPECIAL-OPS "hash-map" (get SPECIAL-OPS "{"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(def- includeFile
  ((# (var icache [])
      (fn [fname]
        (if (not= (.indexOf icache fname) -1)
          ""
          (do (.push icache fname)
              (processTree (toASTree (.readFileSync fs fname)
                                     fname))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-include [expr]

  (assertArgs expr 2 :e0)

  (var found false
       fname (.-name (nth expr 1)))

  (if (string? fname)
    (set! fname (.replace fname
                          (new RegExp "[\"']", "g") "")))

  (dec! indentWidth indentSize)

  (each (.concat includePaths
                 [ (.dirname path (.-_file expr)) ])
        (fn [pfx]
          (try
            (when-not found
              (set! fname (.realpathSync fs (str pfx "/" fname)))
              (set! found true))
            (catch err nil))))

  (if-not found (syntax! :e11 expr))
  (try
    (includeFile fname)
    (finally
      (inc! indentWidth indentSize))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "include" sf-include)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-ns [expr] "")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "ns" sf-ns)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-comment [expr] "")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "comment" sf-comment)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-floop [expr]

  (if (< (alen expr) 2) (syntax! :e0 expr))

  (var c1 nil c2 nil c3 nil
       c (nth expr 1)
       ind (pad indentWidth))

  (do-with [ret (tnodeChunk "for (")]
    (if (or (not (list? c))
            (not= (alen c) 3)) (syntax! :e0 expr))
    (set! c1 (1st c))
    (set! c2 (nth c 1))
    (set! c3 (nth c 2))
    (inc! indentWidth indentSize)
    (for ((i 0) (< i (alen c1)) (i (+ i 2)))
      (if (= i 0) (.add ret "var "))
      (if (not= i 0) (.add ret ","))
      (.add ret [(nth c1 i)
                 " = "
                 (eval?? (nth c1 (inc i))) ]))
    (.add ret "; ")
    (.add ret (evalList c2))
    (.add ret "; ")
    (for ((i 0) (< i (alen c3)) (i (+ i 2)))
      (if (not= i 0) (.add ret ","))
      (.add ret [(nth c3 i)
                 " = "
                 (eval?? (nth c3 (inc i)))] ))
    (.add ret ") {\n")
    (when (> (alen expr) 2)
      (.splice expr 0 2 (tnodeChunk "do" "do"))
      (.add ret [ind (pad indentSize) (evalList expr) ";"]))
    (.add ret (str "\n" ind "}\n"))
    (dec! indentWidth indentSize)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "for" sf-floop)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-jscode [expr]
  (assertArgs expr 2 :e0)
  (set! noSemi? true)
  (.replaceRight (nth expr 1) (new RegExp "\"" "g") "")
  (nth expr 1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "js#" sf-jscode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-macro [expr]
  (assertArgs expr  4 :e0)
  (var a2 (nth expr 2)
       a3 (nth expr 3)
       cmd (.-name (nth expr 1)))
  (do-with [ret ""]
    (for ((i 0) (< i (alen a2)) (i (inc i)))
      (if (and (= (.-name (nth a2 i)) VARGS)
               (not= (+ i 1) (alen a2)))
        (syntax! :e15 expr cmd)))
    (set! MACROS-MAP cmd {args a2 code a3 name cmd})))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "defmacro" sf-macro)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf-not [expr]
  (assertArgs expr 2 :e0)
  (evalConCells expr)
  (str "(!" (nth expr 1) ")"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(set! SPECIAL-OPS "!" sf-not)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- dbg [obj hint]
  (cond
    (list? obj)
    (do
      (set! hint (or hint "block"))
      (console.log (str "<" hint ">"))
      (for ((i 0) (< i (alen obj)) (i (inc i)))
        (dbg (nth obj i)))
      (console.log (str "</" hint ">")))
    (node? obj)
    (do
      (console.log "<node>")
      (console.log obj)
      (dbg (.-children obj) "subs")
      (console.log "</node>"))
    :else
    (console.log obj)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- dbgAST [codeStr fname]
  (dbg (toASTree codeStr fname) "tree"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- compileCode [codeStr fname withSrcMap? incPaths]

  (if (array? incPaths)
    (set! includePaths incPaths))
  (set! indentWidth -indentSize)

  (var outNode (parseTree (toASTree codeStr fname)))
  (.prepend outNode banner)

  (if withSrcMap?
    (let [outFile (str (.basename path fname ".lisp") ".js")
          srcMap  (str outFile ".map")
          output (.toStringWithSourceMap outNode
                                         { file outFile })]
      (.writeFileSync fs srcMap (.-map output))
      (str (.-code output)
           "\n//# sourceMappingURL="
           (.relative path (.dirname path fname) srcMap))
    (.toString outNode))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;

(set! exports
      "transpileWithSrcMap"
      (fn [code file incDirs]
        (compileCode code file true incDirs)))

(set! exports
      "transpile"
      (fn [code file incDirs]
        (compileCode code file false incDirs)))

(set! exports "version" version)

(set! exports "dbgAST" dbgAST)

(set! exports "parseWithSourceMap"
      (fn [codeStr fname]
        (var outNode (processTree (toASTree codeStr fname)))
        (.prepend outNode banner)
        (.toStringWithSourceMap outNode)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;EOF


