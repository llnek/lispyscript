(def fs (require "fs")
     path (require "path")
     ls (require "../lib/ls"))

;; Register `.lisp` file extension so that `lisp`
;; modules can be simply required.
(set! require.extensions[".lisp"]
  (fn (module filename)
    (var code (fs.readFileSync filename "utf8"))
    (module._compile (ls.transpile code (path.relative (process.cwd) filename)) filename)))

;; Load macros to be included into a compiler.
(require "../src/macros")

