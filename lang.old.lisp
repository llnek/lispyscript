;; Copyright (c) 2013-2017, Kenneth Leung. All rights reserved.
;; The use and distribution terms for this software are covered by the
;; Eclipse Public License 1.0 (http:;;opensource.org;licenses;eclipse-1.0.php)
;; which can be found in the file epl-v10.html at the root of this distribution.
;; By using this software in any fashion, you are agreeing to be bound by
;; the terms of this license.
;; You must not remove this notice, or any other, from this software.

(ns ^{:doc ""
      :author "Kenneth Leung" }

  czlab.lispy.lang)

(require "./require")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- conj!! (list obj)
  (if obj (.push list obj)) list)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- addToken (tree token filename lineno tknCol)
  (when token
    (if (= ":else" token) (set! token "true"))
    (if (= "nil" token) (set! token "null"))
    (if (and (.startsWith token ":")
             (REGEX.id.test (.substring token 1)))
      (set! token (str "\"" (.substring token 1) "\"")))
    (conj!! tree
            (tnode lineno,
                   (- tknCol 1)
                   filename token token)))
  "")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- parseError (c tree) (synError c tree))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- lexer (tlen)
  (var tree [] token = "" c nil
       esc? false str? false qstr? false
       regex? false comment? false endList? false)

  (set! tree "_filename" filename)
  (set! tree "_line" lineno)

  (while (< pos tlen)
    (set! c  (.charAt codeStr pos))
    (++ colno)
    (++ pos)
    (when (= c "\n")
      (++ lineno)
      (set! colno 1)
      (if comment?
        (set! comment? false)))
    (if comment? { continue; }
      if (isEsc) {
        isEsc= false; token += c; continue; }
      // strings
      if (c === '"') {
        isStr = !isStr; token += c; continue; }
      if (isStr) {
        if (c === "\n") {
          token += "\\n"; }
        else {
          if (c === "\\") { isEsc= true; }
          token += c;
        }
        continue;
      }
      if (c === "'") {
        isSQStr = !isSQStr;
        token += c; continue; }
      if (isSQStr) {
        token += c; continue; }
      // data types
      if (c === "[") {
        ++jsArray;
        token += c; continue; }
      if (c === "]") {
        if (jsArray === 0) {
          parseError("e4", tree); }
        --jsArray;
        token += c; continue; }
      if (jsArray > 0) {
        token += c; continue; }
      if (c === "{") {
        ++jsObject;
        token += c; continue; }
      if (c === "}") {
        if (jsObject === 0) {
          parseError("e6", tree); }
        --jsObject;
        token += c; continue; }
      if (jsObject > 0) {
        token += c; continue; }
      if (c === ";") {
        isComment = true; continue; }
      // regex
      // regex in function position with first char " " is a prob. Use \s instead.
      if (c === "/"&&
          !(tree.length === 0 &&
            token.length === 0 &&
            REGEX.wspace.test(codeStr.charAt(pos)))) {
        isRegex = !isRegex;
        token += c; continue; }
      if (isRegex) {
        if (c === "\\") {
          isEsc= true; }
        token += c; continue; }
      if (c === "(") {
        token=addToken(tree,token); // catch e.g. "blah("
        tknCol = colno;
        tree.push(lexer());
        continue;
      }
      if (c === ")") {
        isEndForm = true;
        token=addToken(tree,token);
        tknCol = colno;
        break;
      }
      if (REGEX.wspace.test(c)) {
        if (c === "\n") { --lineno; }
        token=addToken(tree,token);
        if (c === "\n") { ++lineno; }
        tknCol = colno;
        continue;
      }
      token += c;
    }
    if (isStr || isSQStr) { parseError("e3", tree);}
    if (isRegex) { parseError("e14", tree); }
    if (jsArray > 0) { parseError("e5", tree); }
    if (jsObject > 0) { parseError("e7", tree); }
    if (!isEndForm) { parseError("e8", tree); }
    return tree;
  },
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- toAST (codeStr filename)
  (set! codeStr (str "(" codeStr ")"))
  (var length (alen codeStr)
       pos  1
       lineno  1
       colno  1
       tknCol 1)
  ;;(defn- addToken (tree token filename lineno tknCol)
  let lexer = function() {
    let tree = [],
        token = "",
        c,
        jsArray = 0,
        jsObject = 0,
        isEsc= false,
        isStr = false,
        isSQStr = false,
        isRegex = false,
        isComment = false,
        isEndForm = false;
    tree._filename = filename;
    tree._line = lineno;
    while (pos < length) {
      c = codeStr.charAt(pos);
      ++colno;
      ++pos;
      if (c === "\n") {
        ++lineno;
        colno = 1;
        if (isComment) {
          isComment = false; }
      }
      if (isComment) { continue; }
      if (isEsc) {
        isEsc= false; token += c; continue; }
      // strings
      if (c === '"') {
        isStr = !isStr; token += c; continue; }
      if (isStr) {
        if (c === "\n") {
          token += "\\n"; }
        else {
          if (c === "\\") { isEsc= true; }
          token += c;
        }
        continue;
      }
      if (c === "'") {
        isSQStr = !isSQStr;
        token += c; continue; }
      if (isSQStr) {
        token += c; continue; }
      // data types
      if (c === "[") {
        ++jsArray;
        token += c; continue; }
      if (c === "]") {
        if (jsArray === 0) {
          parseError("e4", tree); }
        --jsArray;
        token += c; continue; }
      if (jsArray > 0) {
        token += c; continue; }
      if (c === "{") {
        ++jsObject;
        token += c; continue; }
      if (c === "}") {
        if (jsObject === 0) {
          parseError("e6", tree); }
        --jsObject;
        token += c; continue; }
      if (jsObject > 0) {
        token += c; continue; }
      if (c === ";") {
        isComment = true; continue; }
      // regex
      // regex in function position with first char " " is a prob. Use \s instead.
      if (c === "/"&&
          !(tree.length === 0 &&
            token.length === 0 &&
            REGEX.wspace.test(codeStr.charAt(pos)))) {
        isRegex = !isRegex;
        token += c; continue; }
      if (isRegex) {
        if (c === "\\") {
          isEsc= true; }
        token += c; continue; }
      if (c === "(") {
        token=addToken(tree,token); // catch e.g. "blah("
        tknCol = colno;
        tree.push(lexer());
        continue;
      }
      if (c === ")") {
        isEndForm = true;
        token=addToken(tree,token);
        tknCol = colno;
        break;
      }
      if (REGEX.wspace.test(c)) {
        if (c === "\n") { --lineno; }
        token=addToken(tree,token);
        if (c === "\n") { ++lineno; }
        tknCol = colno;
        continue;
      }
      token += c;
    }
    if (isStr || isSQStr) { parseError("e3", tree);}
    if (isRegex) { parseError("e14", tree); }
    if (jsArray > 0) { parseError("e5", tree); }
    if (jsObject > 0) { parseError("e7", tree); }
    if (!isEndForm) { parseError("e8", tree); }
    return tree;
  },
  ret = lexer();
  return (pos < length) ? handleError("e10") : ret;
}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- evalAST (astTree)
  (var ret (tnode)
       pstr ""
       len (alen astTree))

  (+= gIndent gIndentSize)
  (set! pstr (pad gIndent))

  (each astTree
        (fn (expr i tree)
          (let (name "" tmp nil r "")
            (if (list? expr)
              (do
                (if (node? (1st expr))
                  (set! name (.-name (1st expr))))
                (set! tmp (evalForm expr))
                (when (= name "include")
                  (.add ret tmp)
                  (set! tmp nil)))
              (set! tmp expr))
            (when (and (= i (- len 1))
                       gIndent
                       (not (REGEX.noret.test name)))
              (set! r "return "))
            (when tmp
              (.add ret
                    (vec (str pstr r)
                         tmp
                         (if gNoSemiColon "\n" ";\n"))))
            (set! gNoSemiColon false))))
  (-= gIndent gIndentSize)
  ret)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- onMacro (form mc)
  (var m  (evalMacro mc form))
  (if (list? m) (evalForm m) m))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- evalForm (form)

  (var cmd (.-name (1st form))
      mc (get MACROS-MAP cmd))

  (cond
    (some? mc)
    (onMacro form mc)

    (and (string? cmd)
         (.startsWith cmd ".-"))
    (let (ret (tnode) f2 (2nd form))
      (.add ret (if (list? f2)
                  (evalForm f2) f2))
      (.prepend ret "(")
      (.add ret (vec ")[\"" (.slice cmd 2) "\"]"))
      ret)

    (and (string? cmd)
         (= (.charAt cmd 0) "."))
    (let (ret (tnode) f2 (2nd form))
      (.add ret (if (list? f2)
                  (evalForm f2) f2))
      (.add ret (vec (1st form) "("))
      (for ((i 2) (< i (alen form)) (i (+ i 1)))
        (if (not= i 2) (.add ret ","))
        (.add ret (if (list? (nth form i))
                    (evalForm (nth form i) (nth form i)))))
      (.add ret ")")
      ret)

    :else
    (let (f (if (string? cmd)
              (get SPECIAL-FORMS cmd)))
      (if f
        (f form)
        (do
          (evalSexp form)
          (let (f1 (1st form))
            (if-not f1 (handleError 1 (.-line form)))
            (if (REGEX.fn.test f1)
              (set! f1 (tnodeChunk (vec "(" f1 ")"))))
            (tnodeChunk
              (vec f1
                   "("
                   (.join (tnodeChunk
                            (.slice form 1)) ",") ")"))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- evalSexp (sexp)
  (each sexp
        (fn (part i list)
            (if (list? part) (set! list i (evalForm part))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- evalMacroOp (source tree cmd frags ename)
  (var s1 (nth source 1)
       s1name (-.name s1)
       a nil
       g nil
       frag (get frags (str TILDA s1name)))

  (cond
    (= ename "#<<")
    (do
      (if-not (list? frag)
        (synError :e13 tree cmd))
      (set! a (.shift frag))
      (if (undef? a)
          (synError :e12 tree cmd))
      a)

    (= ename "#head")
    (if-not (list? frag)
      (synError :e13 tree cmd)
      (1st frag))

    (= ename "#tail")
    (if-not (list? frag)
      (synError :e13 tree cmd)
      (last frag))

    (.startsWith ename "#slice@")
    (do
      (if-not (list? frag)
        (synError :e13 tree cmd))
      (set! g (REGEX.macroGet.exec ename))
      (assert (and g (= 2 (alen g)) (> (2nd g) 0))
              (str "Invalid macro slice: " ename))
      (set! a (1st (.splice frag (- (2nd g) 1) 1)))
      (if (undef? a)
        (synError :e12 tree cmd))
      a)

    (= ename "#if")
    (do
      (if-not (list? frag)
        (synError :e13 tree cmd))
      (if (not-empty frag)
        (expand (nth source 2))
        (if (nth source 3)
          (expand (nth source 3))
          undefined)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- expandMacro (source)

  (var ret (vec)
       len (alen source)
       ename (.-name (1st source)))

  (doto ret
    (set! "_filename" (.-_filename tree))
    (set! "_line" (.-line tree)))

  (if (REGEX.macroOp.test ename)
    (evalMacroOp source tree cmd frags ename)
    (loop (i) (0)
      (if-not (< i len)
        ret
        (let (si (nth source i) c nil)
          (if (list? si)
            (conj!! ret (expand si))
            (let (token si
                  repl nil
                  bak token
                  atSign? false)
              (when (.includes (.-name token) "@")
                (set! atSign? true)
                (set! bak (tnode (.-line token)
                                 (.-column token)
                                 (.-source token)
                                 (.replace (.-name token) "@" "")
                                 (.replace (.-name token) "@" ""))))
              (if (get frags (.-name bak))
                (do
                  (set! repl (get frags (.-name bak)))
                  (if (or atSign?
                          (= (.-name bak) TILDA_VARGS))
                    (for ((j 0) (< j (alen repl)) (j (+ j 1)))
                      (conj!! ret (nth repl j)))
                    (conj!! ret repl)))
                (conj!! ret token))))
          (recur (+ i 1)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- evalMacro (mc cmd tree)

  (var args (get mc "args")
       code (get mc "code")
       vargs false
       tpos 0
       i 0
       frags (object))

  (for ((i 0) (< i (alen args)) (i (+ i 1)))
    ;; skip the cmd at 0
    (set! tpos (+ i 1))
    (if (= (.-name (nth args i)) VARGS)
      (do
        (set! frags TILDA_VARGS (.slice tree tpos))
        (set! vargs true))
      (set! frags
            (str TILDA (.-name (nth args i)))
            (if (>= tpos (.alen tree))
              (tnodeChunk "undefined") (nth tree tpos)))))

  (if (and (not vargs)
           (< (+ i 1) (alen tree)))
    (synError :e16 tree cmd))

  (expandMacro code))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_compOp (list)
  (if (< (alen list) 3) (synError :e0 list))
  (evalSexp list)

  ;; dont use === as arr[0] is a source node
  (if (eq? (1st list) "!=") (set! list 0  "!=="))
  (if (eq? (1st list) "=") (set! list 0 "==="))

  (var op (.shift list)
       ret (tnode)
       end (eindex list))

  (for ((i 0) (< i end) (i (+ i 1)))
    (.add ret (tnodeChunk (vec (nth list i)
                               " " op " "
                               (nth list (+ i 1))))))
  (doto ret
    (.join " && ")
    (.prepend "(")
    (.add ")")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_arithOp (list)
  (if (< (alen list) 3) (synError :e0 list))
  (evalSexp list)

  (var op (tnode)
       ret (tnode))

  (.add op (vec " " (.shift list) " "))
  (.add ret list)
  (.join ret op)
  (.prepend ret "(")
  (.add ret ")")
  ret)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_logicalOp (list)
  (sf_arithOp list))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; special forms

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_repeat (arr)

  (if (not= (alen arr) 3)
    (synError :e0 arr))

  (evalSexp arr)
  (var ret (tnode)
       end (parseInt (.-name (aget arr 1))))
  (for ((i 0) (< i end) (i (+ i 1)))
    ( if (not= i 0)
      (.add ret ","))
    (.add ret (aget arr 2)))
  (.prepend ret "[")
  (.add ret "]")
  ret)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_do (list)

  (var end (eindex list)
       last (nth list end)
       p (pad gIndent)
       ret (tnode)
       e nil)

  (for ((i 1) (< i end) (i (+ i 1)))
    (set! e (nth list i))
    (.add ret (vec p (evalForm e) ";\n")))

  (set! e (if (isform? last) (evalForm last) last))
  (doto ret
    (.add (vec p "return " e ";\n"))
    (.prepend (str p "(function() {\n"))
    (.add (str p "})()"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_doto (list)

  (if (< (alen list) 2)
    (synError :e0 list))

  (var ret (tnode)
       p (pad gIndent)
       p2 (pad (+ gIndent gIndentSize))
       p3 (pad (+ gIndent (* 2 gIndentSize)))
       e nil
       e1 (1st list))

  (set! e1 (if (isform? e1) (evalForm e1) e1))
  (.add ret (vec p2 "let ___x = " e1 ";\n"))

  (for ((i  2) (< i (alen list)) (i (+ i 1)))
    (set! e (nth list i))
    (.splice e 1 0  "___x")
    (.add ret (vec p3 (evalForm e) ";\n")))

  (doto ret
    (.add (vec p2 "return ___x;\n"))
    (.prepend (str p "(function() {\n"))
    (.add (str p "})()"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_range (arr)

  (if (or (< (alen arr) 2)
          (> (alen arr) 4))
    (synError :e0 arr))

  (evalSexp arr)
  (var ret (tnode)
       len (alen arr)
       start 0
       step 1
       end (parseInt (.-name (aget arr 1))))
  (when (> len 2)
    (set! start (parseInt (.-name (aget arr 1))))
    (set! end (parseInt (.-name (aget arr 2)))))
  (if (> len 3)
    (set! step (parseInt (.-name (aget arr 3)))))

  (for ((i start) (< i end) (i (+ i step)))
    (if (not= i start)
      (.add ret ","))
    (.add ret (str "" i)))
  (.prepend ret "[")
  (.add ret "]")
  ret)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_var (arr cmd)

  (if (or (< (alen arr) 3)
          (= 0 (mod (alen arr) 2)))
    (synError :e0 arr))

  ( if (> (alen arr) 3)
    (set! gIndent (+ gIndent gIndentSize)))

  (evalSexp arr)
  (var ret (tnode))
  (for ((i 1) (< i (alen arr)) (i (+ i 2)))
    (if (> i 1)
      (.add ret (str ",\n" (pad gIndent))))
    (if-not (REGEX.id.test (aget arr i))
      (synError :e9 arr))
    (.add ret (vec (aget arr i) " = "  (aget arr (+ i 1)))))
  (.prepend ret " ")
  (.prepend ret cmd)
  (if (> (alen arr) 3)
    (set! gIndent (- gIndent gIndentSize)))
  ret)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_new (arr)
  ( if (< (alen arr) 2) (synError :e0 arr))
  (var ret (tnode))
  (.add ret (evalForm (.slice arr 1)))
  (.prepend ret "new ")
  ret)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_throw (arr)
  (assertArgs arr 2 :e0)
  (var ret ( tnode))
  (.add ret (if (isform? (aget arr 1))
                (evalForm (aget arr 1)) (aget arr 1)))
  (.prepend ret "throw ")
  (.add ret ";")
  ret)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_while (form)
  (var f1 (2nd form))
  (.splice form 0 2 (tnodeChunk "do" "do"))
  (tnodeChunk
    (vec "while "
         (if (list? f1) (evalForm f1) f1)
         " {\n"
         (evalForm form) ";\n}\n")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_x_opop (form op)
  (assertArgs form 2 :e0)
  (tnodeChunk
    (vec op
         (if (list? (2nd form))
           (evalForm (2nd form)) (2nd form)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_x_eq (form op)
  (assertArgs form 3 :e0)
  (tnodeChunk
    (vec (2nd form)
         (str " " op "= ")
         (if (list? (nth form 2))
           (evalForm (nth form 2)) (nth form 2)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_set (arr)
  (if (or (< (alen arr) 3)
          (> (alen arr) 4))
    (synError :e0 arr))
  (when (= (alen arr) 4)
    (if (isform? (aget arr 1))
      (set! arr 1 (evalForm (aget arr 1))))
    (if (isform? (aget arr 2))
      (set! arr 2 (evalForm (aget arr 2))))
    (set! arr 1 (str (aget arr 1) "[" (aget arr 2) "]"))
    (set! arr 2 (aget arr 3)))

  (tnodeChunk (vec (aget arr 1)
                   " = "
                   (if (isform? (aget arr 2))
                     (evalForm (aget arr 2))
                     (aget arr 2)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_anonFunc (arr)
  (if (< (alen arr) 2) (synError :e0 arr))

  (if-not (isform? (aget arr 1))
    (synError :e0 arr))

  (var fArgs (aget arr 1)
       fBody (.slice arr 2)
       ret (tnodeChunk fArgs))
  (.join ret ",")
  (.prepend ret "function (")
  (.add ret (vec ") {\n"
                 (evalAST fBody)
                 (pad gIndent) "}"))
  ret)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_func (arr public?)

  (if (< (alen arr) 2) (synError :e0 arr))

  (var ret nil
       fName nil
       fArgs nil fBody nil)

  (if (and (not (isform? (aget arr 1)))
           (isform? (aget arr 2)))
    (do
      (set! fName (normalizeId (.-name (aget arr 1))))
      (set! fArgs (aget arr 2))
      (set! fBody (.slice arr 3)))
    (synError :e0 arr))

  (set! ret (tnodeChunk fArgs))
  (.join ret ",")
  (.prepend ret (str "function " fName "("))
  (.add ret (vec ") {\n"
                 (evalAST fBody)
                 (pad gIndent) "}"))
  (set! gNoSemiColon true)
  ret)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_try (arr)

  (var sz (.-length arr)
       t nil
       f nil
       c nil
       ret nil
       ind (pad gIndent))

  ;if (sz < 2) { return ""; }

  ;;look for finally
  (set! f (aget arr (- sz 1)))
  (if (and (isform? f)
           (= (.-name (aget f 0)) "finally"))
    (do
      (set! f (.pop arr))
      (set! sz (.-length arr)))
    (set! f nil))

  ;;look for catch
  (set! c (if (> sz 1) (aget arr (- sz 1)) nil))
  (if (and (isform? c)
           (= (.-name (aget c 0)) "catch"))
    (do
      (if (or (< (.-length c) 2)
              (not (isNode? (aget c 1)))) (synError :e0 arr))
      (set! c (.pop arr)))
    (set! c nil))

  ;;try needs either a catch or finally or both
  (if (and (nil? f)
           (nil? c)) (synError :e0 arr))

  (set! ret
    (tnodeChunk((vec (str "(function() {\n" ind "try {\n")
                     (evalAST (.slice arr 1))
                     (str "\n" ind "} ")))))
  (when c
    (set! t (aget c 1))
    (.splice c 0 2 (tnodeChunk "do" "do"))
    (.add ret (vec (str "catch ("  t  ") {\n")
                   (evalForm c)
                   (str ";\n" ind "}\n"))))

  (when f
    (.splice f 0 1 (tnodeChunk "do" "do"))
    (.add ret (vec "finally {\n"
                   (evalForm f)
                   (str ";\n" ind "}\n"))))

  (.add ret (str ind "})()"))
  ret)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_if (arr)
  (if (or (< (.-length arr) 3)
          (> (.-length arr) 4))
    (synError :e0 arr))
  (set! gIndent (+ gIndent gIndentSize))
  (evalSexp arr)
  (try
    (tnodeChunk (vec "("
                       (aget arr 1)
                       (str " ?\n" (pad gIndent))
                       (aget arr 2)
                       (str " :\n" (pad gIndent))
                       (or (aget arr 3) "undefined") ")"))
    (finally
      (set! gIndent (- gIndent gIndentSize)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_get (arr)
  (assertArgs arr 3 :e0)
  (evalSexp arr)
  (tnodeChunk (vec (aget arr 1) "[" (aget arr 2) "]")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_str (arr)
  (if (< (.-length arr) 2) (synError :e0 arr))
  (evalSexp arr)
  (do-with (ret (tnode))
    (.add ret (.slice arr 1))
    (.join ret ",")
    (.prepend ret "[")
    (.add ret "].join('')")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_array (arr)
  (var ret (tnode)
       p (pad gIndent)
       epilog (str "\n" p "]"))

  (if (= 1 (.-length arr))
    (do
      (.add ret "[]") ret)
    (try
      (set! gIndent (+ gIndent gIndentSize))
      (evalSexp arr)
      (set! p (pad gIndent))
      (.add ret (str "[\n" p))
      (for ((i 1)
            (< i (.-length arr))
            (i (+ i 1)))
        (if (> i 1) (.add ret (str ",\n" p)))
        (.add ret (aget arr i)))
      (.add ret epilog)
      ret
      (finally
        (set! gIndent (- gIndent gIndentSize))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_object (arr)
  (var ret (tnode)
       p (pad gIndent)
       epilog (str "\n" p "}"))

  (if (= 1 (.-length arr))
    (do
      (.add ret "{}") ret)
    (try
      (set! gIndent (+ gIndent gIndentSize))
      (evalSexp arr)
      (set! p (pad gIndent))
      (.add ret (str "{\n" p))
      (for ((i 1) (< i (.-length arr)) (i (+ i 2)))
        (if (> i 1) (.add ret (str ",\n" p)))
        (.add ret (vec (aget arr i) ": " (aget arr (+ i 1)))))
      (.add ret epilog)
      ret
      (finally
        (set! gIndent (- gIndent  gIndentSize))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- includeFile ()
  (var icache (vec))
  (fn (fname)
    (if (not= -1 (.indexOf icache fname))
      ""
      (do
        (.push icache fname)
        (evalAST (toAST (fs.readFileSync fname) fname))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_include (arr)

  (assertArgs arr 2 :e0)

  (var found false
       fname (.-name (aget arr 1)))

  (if (string? fname)
    (set! fname (.replace fname (new Regex "\"'" "g") "")))
  (set! gIndent (- gIdent gIndentSize))

  (conj gIncludePaths (.dirname path (.-_filename arr)))

  (when-not
    (some gIncludePaths
          (fn (elem)
              (try!
                (do->true
                  (set! fname
                    (.realpathSync fs
                                   (str elem "/" fname)))))))
    (synError :e11 arr))

  (try
    ((includeFile) fname)
    (finally
      (set! gIndent (+ gIndent gIndentSize)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_ns (arr) "")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_comment (arr) "")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_jscode (arr)
  (assertArgs arr 2 :e0)
  (set! gNoSemiColon true)
  (.replaceRight (aget arr 1)
                 (new Regex "\"" "g") "")
  (aget arr 1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_macro (arr)
  (assertArgs arr 4 :e0)
  (assertNode (aget arr 1))
  (assertForm (aget arr 2))
  (dotimes (i (.-length (aget arr 2)))
    (if (and (= (.-name (aget (aget arr 2) i)) VARGS)
             (not= (+ i 1) (.-length (aget arr 2))))
      (synError :e15 arr (.-name (aget arr 1)))))
  (set! MACROS_MAP (.-name (aget arr 1))
                   (object args (aget arr 2)
                           code (aget arr 3)))
  "")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- sf_not (arr)
  (assertArgs arr 2 :e0)
  (evalSexp arr)
  (str "(!" (aget arr 1) ")"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- dbg (obj hint)
  (cond
    (array? obj)
    (do
      (set! hint (or hint "block"))
      (console.log (str "<" hint ">"))
      (dotimes (i (.-length obj))
        (dbg (aget obj i)))
      (console.log (str "</" hint ">")))
    (isNode? obj)
    (do
      (console.log "<node>")
      (console.log obj)
      (dbg (.-children obj) "subs")
      (console.log "</node>"))
    :else
    (console.log obj)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- dbgAST (codeStr fname)
  (dbg (toAST codeStr fname) "tree"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- compileCode (codeStr fname srcMap? incPaths)

  (if (array? incPaths) (set! gIncludePaths incPaths))
  (set! gIndent (- gIndent gIndentSize))

  (var outNode (evalAST (toAST codeStr fname)))
  (.prepend outNode gBanner)

  (if srcMap?
    (let (outFile (str (.basename path fname ".lisp") ".js")
          srcMap (str outFile ".map")
          output (.toStringWithSourceMap outNode (object file outFile)))
      (.writeFileSync fs srcMap (.-map output))
      (str (.-code output)
           "\n//# sourceMappingURL="
           (.relative path (.dirname path fname) srcMap)))
    (.toString outNode)))





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;EOF


