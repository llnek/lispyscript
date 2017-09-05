;; state.filename = filename; state.line = lineno;

(defn- lexer [prevToken context]
  (var ____BREAK! nil
       token ""
       ch nil
       isArray? false
       isObject? false
       escStr? false
       isStr? false
       comment? false
       isEndForm? false)

  (do-with [tree []]
    (->> (reduce (fn [acc k]
                   (set! acc k (get context k)) acc)
                 [:filename :lineno])
         (set! tree KIRBY ))

    (cond
      (= "[" prevToken)
      (set! state :array true)
      (= "{" prevToken)
      (set! state :object true))

    (set! ____BREAK! false)
    (while (and (not ____BREAK!)
                (< context.pos (alen context.code)))
      (set! ch (.charAt context.code context.pos))
      (inc!! context.colno)
      (inc!! context.pos)
      (when (= ch "\n")
        (inc!! context.lineno)
        (set! context.colno 1)
        (if comment? (set! comment? false)))
      (cond
        comment?
        nil
        escStr?
        (do
          (set! escStr? false)
          (inc! token ch))
        (= ch "\"")
        (do
          (set! inStr? (not inStr?))
          (inc! token ch))
        inStr?
        (do
          (if (= ch "\n") (set! ch "\\n"))
          (if (= ch "\\") (set! escStr? true))
          (inc! token ch))
        (= ch "[")
        (do
          (set! token (addToken tree token))
          (set! context.tknCol context.colno)
          (set! isArray? true)
          (conj!! tree (lexer "[" context)))
        (= ch "]")
        (do
          (set! token (addToken tree token))
          (set! isArray? false)
          (set! isEndForm? true)
          (set! context.tknCol context.colno)
          (set! ____BREAK! true))
        (= ch "{")
        (do
          (set! token (addToken tree token))
          (set! context.tknCol context.colno)
          (set! isObject? true)
          (conj!! tree (lexer "{" context)))
        (= ch "}")
        (do
          (set! token (addToken tree token))
          (set! isObject? false)
          (set! isEndForm? true)
          (set! context.tknCol context.colno)
          (set! ____BREAK! true))
        (= ch ";")
        (set! comment? true)
        (= ch "(")
        (do
          (set! token (addToken tree token))
          (set! context.tknCol context.colno)
          (conj!! tree (lexer nil context)))
        (= ch ")")
        (do
          (set! isEndForm? true)
          (set! token (addToken tree token))
          (set! context.tknCol context.colno)
          (set! ____BREAK! true))
        (REGEX.wspace.test ch)
        (do
          (if (= ch "\n") (dec!! lineno))
          (set! token (addToken tree token))
          (if (= ch "\n") (inc!! lineno))
          (set! context.tknCol context.colno))
        :else
        (inc!! token ch)))
    ;;final check!
    (if isStr? (syntax! 'e3 tree))
    (if isArray? (syntax! 'e5 tree))
    (if isObject? (syntax! 'e7 tree))
    (if-not isEndForm? (syntax! 'e8 tree))))


