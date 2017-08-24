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


(defn compileCode (codeStr fname withSrcMap? a_include_dirs)

  (if (def? a_include_dirs)
    (set! include_dirs a_include_dirs))

  (set! indent (- indent indentSize))

  (var outNode (evalAST (toAST codeStr fname)))
  (.prepend outNode banner)

  if (withSrcMap) {
    let outFile = path.basename(fname, ".lisp") + ".js",
        srcMap = outFile + ".map",
        output = outNode.toStringWithSourceMap( { file: outFile });

    fs.writeFileSync(srcMap, output.map);
    return output.code +
           "\n//# sourceMappingURL=" +
           path.relative(path.dirname(fname), srcMap);
  } else {
    return outNode.toString();
  }
}





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;EOF


