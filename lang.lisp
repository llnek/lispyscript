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
(defn- sf_object (arr)
  (var ret (tnode)
       p (pad gIndent)
       epilog  (str "\n" p "}"))

  (when (= 1 (.-length arr))
    (.add ret "{}")
    ret)

  (try
    (set! gIndent (+ gIndent gIndentSize))
    (evalSexp arr)
    (set! p (pad gIndent))
    (.add ret (str "{\n" p))
    (range 1 (.-length arr) 2)
    (floop ((i 1 j (* 3 4))
            (or (< i (.-length arr))
                (< j (.-length arr)))
            (i (+ i 2) j (* 2 3)))
      (if (> i 1)
        (.add ret (str ",\n" p)))
      (.add ret (vec (aget arr i) ": " (aget arr (+ i 1)))))
    (.add ret epilog)
    ret
    (finally
      (set! gIndent (- gIndent  gIndentSize)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- includeFile ()
  (var icache (vec))
  (fn (fname)
    (if (not= -1 (.indexOf icache fname)) (return ""))
    (.push icache fname)
    (evalAST (toAST (fs.readFileSync fname) fname))))

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


