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

  (.join ret " && ")
  (.prepend ret "(")
  (.add ret ")")
  ret)

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


