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

(require "./require")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(def- TreeNode (.-SourceNode (require "source-map")))
(def- fs nil path nil)

(def- VERSION "1.0.0"
      includePaths []
      noSemi? false
      indentSize 2
      VARGS "&args"
      TILDA "~"
      TILDA-VARGS (str TILDA VARGS))

(def- indentWidth -indentSize)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(def- REGEX
  { macroGet (new RegExp "^#slice@(\\d+)")
    noret (new RegExp "^def\\b|^var\\b|^set!\\b|^throw\\b")
    id (new RegExp "^[a-zA-Z_$][?\\-*!0-9a-zA-Z_$]*$")
    id2 (new RegExp "^[*$][?\\-*!0-9a-zA-Z_$]+$")
    func (new RegExp "^function\\b")
    query (new RegExp "\\?" "g")
    bang (new RegExp "!" "g")
    dash (new RegExp "-" "g")
    star (new RegExp "\\*" "g")
    wspace (new RegExp "\\s") })

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
;;(if (typeof window === "undefined") {
;;path = require("path"); fs = require("fs"); }
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
(defn- node? [obj tree]
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
(defn- syntax! [c arr cmd]
  (error! c
          (get arr "_line")
          (get arr "_filename") cmd))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defmacro assertArgs [arr cnt ecode]
  (if (not= (alen ~arr) ~cnt) (syntax! ~ecode ~arr)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- pad [z] (.repeat " " z))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
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
    (if (not-empty arguments)
      (set! n
            (if name
              (new TreeNode ln col src chunk name)
              (new TreeNode ln col src chunk)))
      (set! n (new TreeNode)))
    (set! n toString tnodeString)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- tnodeChunk [chunk name]
  (if name
    (tnode nil nil nil chunk name)
    (tnode nil nil nil chunk)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- toASTree [code state]
  (var state { pos 1
               lineno 1
               colno 1
               tknCol 1})
  (var codeStr (str "(" code ")"))
  (do-with [ret (lexer codeStr state)]
    (if (< (.-pos state) (alen codeStr)) (error! :e10))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- parseTree [root]

  (var pstr "" len (alen root))
  (inc! indentWidth indentSize)
  (set! pstr (pad indentWidth))

  (do-with [ret (tnode)]
    (each root
          (fn [expr i tree]
            (var e nil name "" tmp nil r "")
            (if (list? expr)
              (do
                (set! e (1st expr))
                (if (node? e)
                  (set! name (.-name e)))
                (set! tmp  (evalList expr))
                (when (= name "include")
                  (.add ret tmp)
                  (set! tmp nil)))
              (set! tmp expr))
            (if (and (= i (dec len))
                     indentWidth
                     (not (REGEX.noret.test name)))
              (set! r "return "))
            (when tmp
              (.add ret [ (str pstr r)
                          tmp
                          (if noSemi? "\n" ";\n") ])
              (set! noSemi? false))))
    (dec! indentWidth indentSize)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- evalList [expr]

  (var cmd "" tmp nil mc nil)
  (var evslist
       (# (evalSubList expr)
          (var s nil
               fName (1st expr))
          (if-not fName
            (syntax! :e1 expr ""))
          (if (REGEX.fn.test fName)
            (set! fName (tnodeChunk ["(" fName ")"])))
          (tnodeChunk [fName "("
                       (.join (tnodeChunk (.slice expr 1)) ",") ")"])))

  (cond
    (true? (.-_object expr)) (set! cmd "{")
    (true? (.-_array expr)) (set! cmd "[")
    (and (not-empty expr)
         (node? (1st expr)))
    (do
      (set! cmd (.-name (1st expr)))
      (set! mc (get MACROS-MAP cmd))))

  (cond
    (some? mc)
    (do
      (set! tmp (evalMacro mc cmd expr))
      (eval?? tmp))
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
        (for ((i 2) (< i (alen expr)) (i (+ 1 i)))
          (if (not= i 2) (.add ret ","))
          (.add ret (eval?? (nth expr i))))
        (.add ret ")"))
      (.hasOwnProperty SPEC-OPS cmd)
      ((get SPEC-OPS cmd) expr)
      :else
      (evslist))
    :else (evslist)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- evalSubList [subs]
  (each subs
        (fn [part i t]
          (if (list? part) (set! t i (evalList part))))))

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

  (for ((i 0) (< i (alen args)) (i (+ i 1)))
    (set! tpos (+ i 1)) ;skip the cmd at 0
    (if (= (.-name (nth args i)) VARGS)
      (do
        (set! frags TILDA-VARGS (.slice data tpos))
        (set! vargs true))
      (set! frags
            (str TILDA (.-name (nth args i)))
            (if (>= tpos (alen data))
              (tnodeChunk "undefined") (nth data tpos)))))

  (if (and (not vargs)
           (< (+ i 1) (alen data))) (syntax! :e16 tree cmd))

  (var expand
       (fn [source]
         (var ret [] ename "" s1name "")
         (set! ret "_filename" (get data "_filename"))
         (set! ret "_line" (get data "_line"))
         (when (and (list? source)
                    (> (alen source) 1))
           (set! s1name (.-name (nth source 1)))
           (set! frag (get frags (str TILDA s1name))))
         (if (and (list? source)
                  (not-empty source))
           (set! ename (.-name (1st source))))
         (cond
           (true? (get source "_object"))
           (set! ret "_object" true)
           (true? (get source "_array"))
           (set! ret "_array" true))

         (cond
           (= ename "#<<")
           (if-not (list? frag)
             (syntax! :e13 data cmd)
             (.shift frag))

    if (REGEX.macroOp.test(ename)) {
      let s1name= source[1].name,
          a, g,
          frag = frags[TILDA + s1name];


      if (ename === "#head") {
        if (!isarray(frag)) {
          synError("e13", tree, cmd);
        }
        return frag.length > 0 ? frag[0] : undefined;
      }
      if (ename === "#tail") {
        if (!isarray(frag)) {
          synError("e13", tree, cmd);
        }
        return frag.length > 0 ? frag[frag.length-1] : undefined;
      }
      if (ename.startsWith("#evens")) {
        var r=[];
        for (var i=1; i < frag.length; i=i+2) {
          r.push(frag[i]);
        }
        if (ename.endsWith("*")) { r.___split=true; }
        return r;
      }
      if (ename.startsWith("#odds")) {
        var r=[];
        for (var i=0; i < frag.length; i=i+2) {
          r.push(frag[i]);
        }
        if (ename.endsWith("*")) { r.___split=true; }
        return r;
      }
      if (ename.startsWith("#slice@")) {
        if (!isarray(frag)) {
          synError("e13", tree, cmd);
        }
        g= REGEX.macroGet.exec(ename);
        assert(g && g.length == 2 && g[1] > 0,
               "Invalid macro slice: " + ename);
        a= frag.splice(g[1]-1, 1)[0];
        //if (isUndef(a)) { synError("e12", tree, cmd); }
        return a;
      }
      if (ename === "#if") {
        if (!isarray(frag)) {
          synError("e13", tree, cmd);
        }
        if (frag.length > 0) {
          return expand(source[2]);
        } else if (source[3]) {
          return expand(source[3]);
        } else {
          return undefined;
        }
      }
    }

    for (var i = 0; i < source.length; ++i) {
      if (isarray(source[i])) {
        let c = expand(source[i]);
        if (c) {
          if (isarray(c) && c.___split === true) {
            for (var i=0; i < c.length; ++i) {
              ret.push(c[i]);
            }
          } else {
            ret.push(c);
          }
        }
      } else {
        let token = source[i],
            bak = token,
            isATSign = false;
        if (token.name.indexOf("@") >= 0) {
          isATSign = true;
          bak = tnode(token.line,
                      token.column,
                      token.source,
                      token.name.replace("@", ""),
                      token.name.replace("@", ""));
        }
        if (frags[bak.name]) {
          let repl = frags[bak.name];
          if (isATSign ||
              bak.name === TILDA_VARGS) {
            for (var j = 0; j < repl.length; ++j) {
              ret.push(repl[j]);
            }
          } else {
            ret.push(repl);
          }
        } else {
          ret.push(token);
        }
      }
    }
    return ret;
  }

  return expand(code);
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_compOp(arr) {
  if (arr.length < 3) { synError("e0", arr); }
  evalSexp(arr);

  // dont use === as arr[0] is a source node
  if (arr[0] == "!=") { arr[0] = "!=="; }
  if (arr[0] == "=") { arr[0] = "==="; }

  let op = arr.shift(),
      ret = tnode();

  for (var i = 0; i < arr.length - 1; ++i) {
    ret.add(tnodeChunk([arr[i], " ", op, " ", arr[i + 1]]));
  }

  ret.join(" && ");
  ret.prepend("(");
  ret.add(")");
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_arithOp(arr) {
  if (arr.length < 3) { synError("e0", arr); }
  evalSexp(arr);

  let op = tnode(),
      ret= tnode();

  op.add([" ", arr.shift(), " "]);
  ret.add(arr);
  ret.join(op);
  ret.prepend("(");
  ret.add(")");
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_logicalOp(arr) {
  return sf_arithOp(arr);
}

//////////////////////////////////////////////////////////////////////////////
//special forms
//////////////////////////////////////////////////////////////////////////////

function sf_repeat(form) {

  if (form.length !== 3) {
    synError("e0", form); }

  evalSexp(form);
  let ret = tnode(),
      end= parseInt(form[1].name);
  for (var i = 0; i < end; ++i) {
    if (i !== 0) {
      ret.add(",");
    }
    ret.add(form[2]);
  }
  ret.prepend("[");
  ret.add("]");
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_do(form) {

  if (form.length < 2) { return ""; }

  let end = form.length -1,
      last = form[end],
      p = pad(indent),
      ret= tnode(),
      e;

  for (var i = 1; i < end; ++i) {
    e=form[i];
    ret.add([p, evalForm(e), ";\n"]);
  }
  e= isform(last) ? evalForm(last) : last;
  ret.add([p, "return ", e, ";\n"]);
  ret.prepend(p + "(function() {\n");
  ret.add(p+"})()");
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_doto(form) {

  if (form.length < 2) {
    synError("e0", form); }

  let ret= tnode(),
      p = pad(indent),
      p2 = pad(indent + indentSize),
      p3 = pad(indent + indentSize * 2),
      e, e1 = form[1];
  e1= isform(e1) ? evalForm(e1) : e1;
  ret.add([p2, "let ___x = ", e1, ";\n"]);
  for (var i = 2; i < form.length; ++i) {
    e=form[i];
    e.splice(1,0, "___x");
    ret.add([p3, evalForm(e), ";\n"]);
  }
  ret.add([p2, "return ___x;\n"]);
  ret.prepend(p + "(function() {\n");
  ret.add(p+"})()");
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_range(form) {

  if (form.length < 2 || form.length > 4) {
    synError("e0", form); }

  evalSexp(form);
  let ret = tnode(),
      len= form.length,
      start=0,
      step=1,
      end= parseInt(form[1].name);
  if (len > 2) {
    start= parseInt(form[1].name);
    end= parseInt(form[2].name);
  }
  if (len > 3) {
    step= parseInt(form[3].name);
  }
  for (var i = start; i < end; i = i + step) {
    if (i !== start) {
      ret.add(",");
    }
    ret.add(""+i);
  }
  ret.prepend("[");
  ret.add("]");
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
function sf_var(form, cmd) {

  if (form.length < 3 ||
      0 === (form.length % 2)) {
    synError("e0", form); }

  if (form.length > 3) {
    indent += indentSize; }

  evalSexp(form);
  let ret = tnode();
  for (var i = 1; i < form.length; i = i + 2) {
    if (i > 1) {
      ret.add(",\n" + pad(indent));
    }
    if (!testid(form[i])) { synError("e9", form); }
    ret.add([form[i], " = ", form[i + 1]]);
  }
  ret.prepend(" ");
  ret.prepend(cmd);
  if (form.length > 3) {
    indent -= indentSize; }
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_new(form) {
  if (form.length < 2) { synError("e0", form); }
  let ret = tnode();
  ret.add(evalForm(form.slice(1)));
  ret.prepend("new ");
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_throw(form) {
  assertArgs(form, 2, "e0");
  let ret = tnode();
  ret.add(isform(form[1]) ? evalForm(form[1]) : form[1]);
  //ret.prepend("(function(){ throw ");
  //ret.add(";})()");
  ret.prepend("throw ");
  ret.add(";");
  return ret;
}

function sf_while(form) {
  let f1=form[1];
  form.splice(0,2,tnodeChunk("do","do"));
  return tnodeChunk(
    ["while ",
     isform(f1) ? evalForm(f1) : f1,
     " {\n",
     evalForm(form),
     ";\n}\n"]);
}

function sf_x_opop(form, op) {
  if (form.length !== 2) { synError("e0", form); }
  return tnodeChunk([op,
                     isform(form[1]) ? evalForm(form[1]) : form[1]]);
}

function sf_x_eq(form, op) {
  if (form.length !== 3) { synError("e0", form); }
  return tnodeChunk([form[1],
                     " " + op + "= ",
                     isform(form[2]) ? evalForm(form[2]) : form[2]]);
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_set(form) {
  if (form.length < 3 || form.length > 4) {
    synError("e0", form); }
  if (form.length === 4) {
    if (isform(form[1])) { form[1]= evalForm(form[1]); }
    if (isform(form[2])) { form[2]= evalForm(form[2]); }
    form[1] = form[1] + "[" + form[2] + "]";
    form[2] = form[3];
  }
  return tnodeChunk([form[1],
                     " = ",
                     isform(form[2]) ? evalForm(form[2]) : form[2]]);
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_anonFunc(arr) {
  if (arr.length < 2) { synError("e0", arr); }

  if (! isform(arr[1])) {
    synError("e0", arr);
  }

  let fArgs = arr[1],
      fBody = arr.slice(2),
      ret = tnodeChunk(fArgs);
  ret.join(",");
  ret.prepend("function (");
  ret.add([") {\n",evalAST(fBody), pad(indent), "}"]);
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_func(arr, public) {

  if (arr.length < 2) { synError("e0", arr); }

  let ret, fName, fArgs, fBody;

  if (!isform(arr[1]) && isform(arr[2])) {
    fName = normalizeId(arr[1].name);
    fArgs = arr[2];
    fBody = arr.slice(3);
  }
  else { synError("e0", arr); }

  ret = tnodeChunk(fArgs);
  ret.join(",");
  ret.prepend("function " + fName + "(");
  ret.add([") {\n",evalAST(fBody), pad(indent), "}"]);
  noSemiColon = true;
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_try(arr) {

  let sz= arr.length,
      t, f, c, ret,
      ind = pad(indent);

  if (sz < 2) { return ""; }

  //look for finally
  f=arr[sz-1];
  if (isform(f) && f[0].name === "finally") {
    f=arr.pop();
    sz=arr.length;
  } else { f=null; }
  //look for catch
  c= sz > 1 ? arr[sz-1] : null;
  if (isform(c) && c[0].name === "catch") {
    if (c.length < 2 || !isNode(c[1], c)) {
      synError("e0", arr);
    }
    c=arr.pop();
  } else { c=null; }

  //try needs either a catch or finally or both
  if (f === null && c === null) { synError("e0", arr); }

  ret= tnodeChunk(["(function() {\n" + ind + "try {\n",
                   evalAST(arr.slice(1)),
                   "\n" + ind + "} "]);
  if (c) {
    t=c[1];
    c.splice(0,2, tnodeChunk("do","do"));
    ret.add(["catch (" + t + ") {\n",
             "return ", evalForm(c), ";\n" + ind + "}\n"]);
  }
  if (f) {
    f.splice(0,1, tnodeChunk("do","do"));
    ret.add(["finally {\n",
             evalForm(f), ";\n" + ind + "}\n"]);
  }

  ret.add(ind + "})()");
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_if(arr) {
  if (arr.length < 3 || arr.length > 4)  {
    synError("e0", arr); }
  indent += indentSize;
  evalSexp(arr);
  try {
    return tnodeChunk(["(",
                       arr[1],
                       " ?\n" + pad(indent),
                       arr[2],
                       " :\n" + pad(indent),
                       (arr[3] || "undefined"), ")"]);
  } finally {
    indent -= indentSize;
  }
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_get(arr) {
  assertArgs(arr, 3, "e0");
  evalSexp(arr);
  return tnodeChunk([arr[1], "[", arr[2], "]"]);
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_str(arr) {
  if (arr.length < 2) { synError("e0", arr); }
  evalSexp(arr);
  let ret = tnode();
  ret.add(arr.slice(1));
  ret.join(",");
  ret.prepend("[");
  ret.add("].join('')");
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_array(arr) {
  let ret = tnode(),
      p= pad(indent),
      epilog="\n" + p + "]";

  if (arr.length === 0) {
    ret.add("[]");
    return ret;
  }

  if (arr._array === true) {} else {
    arr.splice(0,1);
  }

  try {
    indent += indentSize;
    evalSexp(arr);
    p= pad(indent);
    ret.add("[\n" + p);
    for (var i = 0; i < arr.length; ++i) {
      if (i > 0) {
        ret.add(",\n" + p);
      }
      ret.add(arr[i]);
    }
    ret.add(epilog);
    return ret;
  } finally {
    indent -= indentSize;
  }
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_object(arr) {
  let ret = tnode(),
      p= pad(indent),
      epilog= "\n" + p + "}";

  if (arr.length === 0) {
    ret.add("{}");
    return ret;
  }

  if (arr._object === true) {} else {
    arr.splice(0,1);
  }

  try {
    indent += indentSize;
    evalSexp(arr);
    p=pad(indent);
    ret.add("{\n" + p);
    for (var i = 0; i < arr.length; i = i + 2) {
      if (i > 0) {
        ret.add(",\n" + p); }
      ret.add([arr[i], ": ", arr[i + 1]]);
    }
    ret.add(epilog);
    return ret;
  } finally {
    indent -= indentSize;
  }
}

//////////////////////////////////////////////////////////////////////////////
//
var includeFile = (function () {
  let icache = [];
  return function(fname) {
    if (icache.indexOf(fname) !== -1) { return ""; }
    icache.push(fname);
    return evalAST(toAST(fs.readFileSync(fname), fname));
  };
})();

//////////////////////////////////////////////////////////////////////////////
//
function sf_include(arr) {

  assertArgs(arr, 2, "e0");

  let found=false,
      fname = arr[1].name;

  if (isStr(fname)) {
    fname = fname.replace(/["']/g, ""); }
  indent -= indentSize;

  include_dirs.
    concat([path.dirname(arr._filename)]).
    forEach(function(pfx) {
      if (found) { return; }
      try {
        fname = fs.realpathSync(pfx + '/' +fname);
        found = true;
      } catch (err) {}
    });

  if (!found) { synError("e11", arr); }

  try {
    return includeFile(fname);
  } finally {
    indent += indentSize;
  }
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_ns(arr) {
  return "";
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_comment(arr) {
  return "";
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_floop(arr) {
//(floop ((i 1) (< i (.-length arr)) (i (+ i 2)))

  if (arr.length < 2) { synError("e0",arr); }

  let c1,c2,c3,
      c=arr[1],
      ind= pad(indent),
      ret=tnodeChunk("for (");

  if (!isform(c) || c.length !== 3) { synError("e0",arr); }

  c1=c[0];
  c2=c[1];
  c3=c[2];

  indent += indentSize;

  for (var i=0; i < c1.length; i=i+2) {
    if (i==0) {ret.add("var "); }
    if (i !== 0) { ret.add(","); }
    ret.add([c1[i],
             " = ",
             isform(c1[i+1]) ? evalForm(c1[i+1]) : c1[i+1]]);
  }
  ret.add("; ");
  ret.add(evalForm(c2));
  ret.add("; ");
  for (var i=0; i < c3.length; i=i+2) {
    if (i !== 0) { ret.add(","); }
    ret.add([c3[i],
            " = ",
            isform(c3[i+1]) ? evalForm(c3[i+1]) : c3[i+1]]);
  }
  ret.add(") {\n");
  if (arr.length > 2) {
    arr.splice(0,2, tnodeChunk("do","do"));
    ret.add([ind, pad(indentSize), evalForm(arr), ";"]);
  }
  ret.add("\n" + ind + "}\n");
  indent -= indentSize;
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_jscode(arr) {
  assertArgs(arr, 2, "e0");
  noSemiColon = true;
  arr[1].replaceRight(/"/g, "");
  return arr[1];
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_macro(arr) {
  assertArgs(arr, 4, "e0");
  assertNode(arr[1],arr);
  assertForm(arr[2]);
  let a2=arr[2],
      a3=arr[3];

  for (var i=0; i < a2.length; ++i) {
    if (a2[i].name === VARGS &&
        (i+1) !== a2.length) {
      synError("e15", arr, arr[1].name);
    }
  }

  MACROS_MAP[arr[1].name] = {args: a2, code: a3};
  return "";
}

//////////////////////////////////////////////////////////////////////////////
//
function sf_not(arr) {
  assertArgs(arr, 2, "e0");
  evalSexp(arr);
  return "(!" + arr[1] + ")";
}



//////////////////////////////////////////////////////////////////////////////
//
function dbg(obj, hint) {
  if (isarray(obj)) {
    hint= hint || "block";
    console.log("<"+hint+">");
    for (var i=0; i < obj.length; ++i) {
      dbg(obj[i]);
    }
    console.log("</"+hint+">");
  } else if (isNode(obj)) {
    console.log("<node>");
    console.log(obj);
    dbg(obj.children,"subs");
    console.log("</node>");
  } else {
    console.log(obj);
  }
}

//////////////////////////////////////////////////////////////////////////////
//
function dbgAST(codeStr, fname) {
  let tree= toAST(codeStr, fname);
  dbg(tree, "tree");
}

//////////////////////////////////////////////////////////////////////////////
//
function compileCode(codeStr, fname, withSrcMap, a_include_dirs) {

  if (a_include_dirs) { include_dirs = a_include_dirs; }
  indent = -indentSize;

  let outNode = evalAST(toAST(codeStr, fname));
  outNode.prepend(banner);

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

//////////////////////////////////////////////////////////////////////////////
//
exports.transpileWithSrcMap=function(code,file,incDirs) {
  return compileCode(code,file,true,incDirs);
};
exports.transpile=function(code,file,incDirs) {
  return compileCode(code,file,false,incDirs);
};
exports.version = version;
exports.dbgAST=dbgAST;
exports.parseWithSourceMap = function(codeStr, fname) {
  let outNode = evalAST(toAST(codeStr, fname));
  outNode.prepend(banner);
  return outNode.toStringWithSourceMap();
};

//////////////////////////////////////////////////////////////////////////////
//EOF




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;EOF


