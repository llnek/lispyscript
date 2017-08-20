(require "./require")
(var fs (require "fs")
     path (require "path")
     ls (require "./ls")
     repl (require "./repl")
     watch (require "watch")
     isValidFlag /-h\b|-r\b|-v\b|-b\b|-s\b|-t\b/
     error
       (fn (err)
         (console.error err.message)
         (process.exit 1)))

(var opt (->
  (require 'node-getopt')
  (.create [['h', 'help', 'display this help'],
    ['v', 'version', 'show version'],
    ['r', 'run', 'run .ls files directly'],
    ['w', 'watch', 'watch and compile changed files beneath current directory'],
    ['b', 'browser-bundle', 'create browser-bundle.js in the same directory'],
    ['m', 'map', 'generate source map files'],
    ['t', 'tree', 'show AST tree'],
    ['i', 'include-dir=ARG+', 'add directory to include search path']])
  (.setHelp (+ "lispy [OPTION] [<infile>] [<outfile>]\n\n"
               "<outfile> will default to <infile> with '.js' extension\n\n"
              "Also compile stdin to stdout\n"
              "eg. $ echo '(console.log \"hello\")' | lispy\n\n"
              "[[OPTIONS]]\n\n"))
  (.bindHelp)
  (.parseSystem)
))

;; We use maybe monad to carry out each step, so that we can
;; halt the operation anytime in between if needed.

(doMonad maybeMonad

  ;; Start maybe Monad bindings

  ;; when no args do stdin -> stdout compile or run repl and return null to
  ;; halt operations.
  (noargs
    (when (and
              (zero? opt.argv.length)
              (zero? (.length (Object.keys opt.options))))
      (var output process.stdout)
      (var input process.stdin)
      (input.resume)
      (input.setEncoding "utf8")
      (var source "")
      ;; Accumulate text form input until it ends.
      (input.on "data"
        (fn (chunck)
          (set! source (+ source (chunck.toString)))))
      ;; Once input ends try to compile & write to output.
      (input.on "end"
        (#
          (try
            (output.write (ls.transpile source process.cwd))
            error)))
      (input.on "error" error)
      (output.on "error" error)
      (setTimeout
        (#
          (if (zero? input.bytesRead)
            (do
              (input.removeAllListeners "data")
              (repl.runrepl)))) 20)
      nil)

  compile
    (cond
      (true? opt.options['version']) (do->nil (console.log (+ "Version " ls.version)))
      (true? opt.options['browser-bundle'])
          (do->nil
            (var bundle
              (require.resolve "lispyscript/lib/browser-bundle.js"))
              ((.pipe (fs.createReadStream bundle))
              (fs.createWriteStream "browser-bundle.js")))
      (true? opt.options['run'])
          ;; run specified .ls file (directly with no explicit .js file)
          (do->nil
            (var infile
              (if opt.argv[0]
                ;; we require .ls extension (our require extension depends on it!)
                (if (and (= (opt.argv[0].indexOf '.ls') -1)
                         (= (opt.argv[0].indexOf '.js') -1))
                  (error (new Error "Error: Input file must have extension '.ls' or '.js'"))
                  opt.argv[0])
                (error (new Error "Error: No Input file given"))))
            ;; by running the file via require we ensure that any other
            ;; requires within infile work (and process paths correctly)
            (require infile))
      (true? opt.options['watch'])
          (do->nil
            (var cwd (process.cwd))
            (console.log 'Watching' cwd 'for .ls file changes...')
            (watch.watchTree cwd
              (object
                filter (fn (f stat) (or (stat.isDirectory) (not= (f.indexOf '.ls') -1)))
                ignoreDotFiles true
                ignoreDirectoryPattern /node_modules/ )
              (fn (f curr prev)
                (cond
                  (and curr (not= curr.nlink 0))
                    (->
                      (require "child_process")
                      (.spawn "lispy" [f.substring(cwd.length+1)] {stdio: "inherit"}))
                  (and (object? f) (nil? prev) (nil? curr))
                    (eachKey f
                      (fn (stat initialf)
                        (unless (= initialf cwd)
                          (->
                            (require "child_process")
                            (.spawn "lispy" [initialf.substring(cwd.length+1)] {stdio: "inherit"})))))))))
      :else true) ;; no other options - go ahead and compile

  ;; if infile undefined
  infile
    (if opt.argv[0]
      opt.argv[0]
      (error (new Error "Error: No Input file given")))

  ;; set outfile args.shift. ! outfile set outfile to infile(.js)
  outfile
    (do-with (outfile opt.argv[1])
      (unless outfile
        (set! outfile (infile.replace /\.ls$/ ".js"))
        (if (= outfile infile)
          (error (new Error "Error: Input file must have extension '.ls'"))))))

  ;; compile infile to outfile.
  (try
    (var wantMap (true? opt.options["map"]))
    (var dbgAST (true? opt.options["tree"]))
    (var dirs opt.options["include-dir"])
    (if-not dbgAST
      (console.log
        (str "lispy v" ls.version ":  compiling: " infile " -> " outfile)))
    (var content (fs.readFileSync infile "utf8"))
    (if dbgAST
      (ls.dbgAST content infile dirs)
      (fs.writeFileSync
        outfile
        (if wantMap
          (ls.transpileWithSrcMap content infile dirs)
          (ls.transpile content infile dirs))
        "utf8"))
    (fn (err) (error err) nil)))
;; end of maybe Monad bindings


