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
(defn- conj!! (list obj)
  (if obj (.push list obj)) list)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defn- testid (name)
  (or (REGEX.id.test name) (REGEX.id2.test name)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;(if (typeof window === "undefined") {
;;path = require("path"); fs = require("fs"); }

//////////////////////////////////////////////////////////////////////////////
//
function normalizeId(name) {
  let pfx="";
  if (name && name.charAt(0) === "-") {
    pfx="-";
    name=name.slice(1);
  }
  if (testid(name)) {
    return pfx + name.replace(/\?/g, "_QUERY").
                      replace(/!/g, "_BANG").
                      replace(/-/g, "_").
                      replace(/\*/g, "_STAR");
  } else {
    return pfx === "" ? name : pfx + name;;
  }
}

//////////////////////////////////////////////////////////////////////////////
//
function assert(cond, msg) {
  if (! cond) { throw new Error(msg); }
}

//////////////////////////////////////////////////////////////////////////////
//
function whatis(obj) {
  return Object.prototype.toString.call(obj);
}

//////////////////////////////////////////////////////////////////////////////
//
function isObject(obj) {
  return whatis(obj) === "[object Object]";
}

//////////////////////////////////////////////////////////////////////////////
//
function isArray(obj) {
  return whatis(obj) === "[object Array]";
}

//////////////////////////////////////////////////////////////////////////////
//
function isStr(obj) {
  return whatis(obj) === "[object String]";
}

//////////////////////////////////////////////////////////////////////////////
//
function isUndef(obj) {
  return whatis(obj) === "[object Undefined]";
}

//////////////////////////////////////////////////////////////////////////////
//
function isNode(obj,tree) {
  try {
    if (obj === null) {
      throw "poo";
    }
    return isObject(obj) && obj["$$$isSourceNode$$$"] === true;
  } catch (e) {
    console.log("DUDE");
    console.log("tree = " + tree._line);
    throw e;
  }
}

//////////////////////////////////////////////////////////////////////////////
//
function handleError(no, line, filename, extra) {
  throw new Error(ERRORS_MAP[no] +
                  ((extra) ? " : " + extra : "") +
                  ((line) ? "\nLine no " + line : "") +
                  ((filename) ? "\nFile " + filename : ""));
}

//////////////////////////////////////////////////////////////////////////////
//
function synError(c,arr,cmd) {
  return handleError(c, arr._line, arr._filename,cmd);
}

//////////////////////////////////////////////////////////////////////////////
//
function assertArgs(arr, cnt, err) {
  if (arr.length !== cnt) { synError(err, arr); }
}

//////////////////////////////////////////////////////////////////////////////
//
function assertForm(f) {
  if (! isform(f)) {
    console.log("expecting form, got: " + whatis(f));
  }
}

//////////////////////////////////////////////////////////////////////////////
//
function assertNode(n, tree) {
  if (! isNode(n, tree)) {
    console.log("expecting node, got: " + whatis(n));
    if (isform(n)) {
      console.log("expecting node, line: " + n._line);
    }
    assert(false, "source node expected");
  }
}

//////////////////////////////////////////////////////////////////////////////
//
function inst(obj) { return typeof obj; }

//////////////////////////////////////////////////////////////////////////////
//
function isarray(a) { return Array.isArray(a); }
function isform(a) { return Array.isArray(a); }

//////////////////////////////////////////////////////////////////////////////
//
function pad(z) { return " ".repeat(z); }

//////////////////////////////////////////////////////////////////////////////
//
function tnodeString() {
  let str = "";
  this.walk(function (chunk,hint) {
    if (hint.name === chunk && isStr(chunk)) {
      chunk= normalizeId(chunk);
    }
    str += chunk;
  });
  return str;
}

//////////////////////////////////////////////////////////////////////////////
//
function tnode(ln,col,fn,chunk,name) {
  let n;
  if (arguments.length > 0) {
    n= name ? new TreeNode(ln, col, fn, chunk, name)
            : new TreeNode(ln, col, fn, chunk);
  } else {
    n= new TreeNode();
  }
  n.toString= tnodeString;
  return n;
}

//////////////////////////////////////////////////////////////////////////////
//
function tnodeChunk(chunk,name) {
  return name ? tnode(null,null,null,chunk,name)
              :tnode(null,null,null,chunk);
}

//////////////////////////////////////////////////////////////////////////////
//
function toAST(codeStr, filename) {
  let codeArray = Array.from("(" + codeStr + ")");
  let jsArray = 0,
      jsObject = 0,
      pos = 1,
      lineno = 1,
      colno = 1,
      tknCol = 1,
      addToken = function(tree,token) {
        if (token) {
          if (":else" == token) { token="true";}
          if ("nil" == token) { token="null";}
          if (token.startsWith(":") &&
              testid(token.substring(1))) {
            token="\"" + token.substring(1) + "\"";
          }
          tree.push(tnode(lineno,
                          tknCol - 1,
                          filename, token, token));
        }
        return "";
      },
      parseError=function(c,tree) {
        synError(c, tree);
      };
  let lexer = function(prevToken) {
    let tree = [],
        token = "",
        c,
        isArray=false,
        isObject=false,
        isEsc= false,
        isStr = false,
        isSQStr = false,
        isRegex = false,
        isComment = false,
        isEndForm = false;
    tree._filename = filename;
    tree._line = lineno;
    if (prevToken === "[") {
      tree._array=true;
    } else if (prevToken === "{") {
      tree._object=true;
    }

    while (pos < codeArray.length) {
      c = codeArray[pos];
      ++colno;
      ++pos;
      if (c === "\n") {
        ++lineno;
        gLINE=lineno;
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
        token=addToken(tree,token); // catch e.g. "blah["
        tknCol = colno;
        isArray=true;
        tree.push(lexer("["));
        continue;
      }
      if (c === "]") {
        token=addToken(tree,token);
        //token=addToken(tree,"]");
        isArray = false;
        isEndForm=true;
        tknCol = colno;
        break;
      }
      if (c === "{") {
        token=addToken(tree,token);
        tknCol = colno;
        isObject=true;
        tree.push(lexer("{"));
        continue;
      }
      if (c === "}") {
        token=addToken(tree,token);
        //token=addToken(tree,"}");
        isObject = false;
        isEndForm=true;
        tknCol = colno;
        break;
      }
      if (c === ";") {
        isComment = true; continue; }
      // regex
      // regex in function position with first char " " is a prob. Use \s instead.
      if (c === "/"&&
          !(tree.length === 0 &&
            token.length === 0 &&
            REGEX.wspace.test(codeArray[pos]))) {
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
        gLINE=lineno;
        continue;
      }
      token += c;
    }
    if (isStr || isSQStr) { parseError("e3", tree);}
    if (isRegex) { parseError("e14", tree); }
    if (jsArray) { parseError("e5", tree); }
    //if (jsObject > 0) { parseError("e7", tree); }
    if (!isEndForm) { parseError("e8", tree); }
    return tree;
  },
  ret = lexer();
  return (pos < codeArray.length) ? handleError("e10") : ret;
}

//////////////////////////////////////////////////////////////////////////////
// [expr,...] -> TreeNode
function evalAST(astTree) {
  let ret = tnode(),
      pstr = "",
      len = astTree.length;

  indent += indentSize;
  pstr = pad(indent);

  astTree.forEach(function(expr, i, tree) {
    let name="", tmp = null, r = "";
    if (isform(expr)) {
      if (isNode(expr[0], expr)) {
        name = expr[0].name;
      }
      tmp = evalForm(expr) ;
      if (name === "include") {
        ret.add(tmp);
        tmp=null;
      }
    } else {
      tmp = expr;
    }
    if (i === len - 1 &&
        indent &&
        !REGEX.noret.test(name)) {
      r = "return ";
    }
    if (tmp) {
      ret.add([pstr + r,
               tmp, noSemiColon ? "\n" : ";\n"]);
      noSemiColon = false;
    }
  });

  indent -= indentSize;
  return ret;
}

//////////////////////////////////////////////////////////////////////////////
//
function evalForm(form) {

  let cmd = "",
      mc=null;

  if (form._array === true) { cmd="["; }
  else if (form._object === true) { cmd="{"; }
  else if (!form[0]) { return null; }
  else if (isNode(form[0], form)) {
    cmd=form[0].name;
    mc= MACROS_MAP[cmd];
  }

  if (mc) {
    let m = evalMacro(mc, cmd, form);
    return isform(m) ? evalForm(m) : m;
  }

  if (isStr(cmd)) {
    if (cmd.startsWith(".-")) {
      let ret = tnode();
      ret.add(isform(form[1])
              ? evalForm(form[1]) : form[1]);
      ret.prepend("(");
      ret.add([")[\"", cmd.slice(2), "\"]"]);
      return ret;
    }
    if (cmd.charAt(0) === ".") {
      let ret = tnode();
      ret.add(isform(form[1])
              ? evalForm(form[1]) : form[1]);
      ret.add([form[0], "("]);
      for (var i=2; i < form.length; ++i) {
        if (i !== 2) { ret.add(","); }
        ret.add(isform(form[i])
                ? evalForm(form[i]) : form[i]);
      }
      ret.add(")");
      return ret;
    }
    switch (cmd) {
      case "comment": return sf_comment(form);
      case "repeat-n": return sf_repeat(form);
      case "doto": return sf_doto(form);
      case "do": return sf_do(form);
      case "for": return sf_floop(form);
      case "ns": return sf_ns(form);
      case "range": return sf_range(form);
      case "while": return sf_while(form);
      case "var": return sf_var(form, "let");
      case "def-":
      case "def": return sf_var(form, "var");
      case "new": return sf_new(form);
      case "throw": return sf_throw(form);
      case "set!": return sf_set(form);
      case "dec!": return sf_x_eq(form, "-");
      case "inc!": return sf_x_eq(form, "+");
      case "dec!!": return sf_x_opop(form, "--");
      case "inc!!": return sf_x_opop(form, "++");
      case "aget":
      case "get": return sf_get(form);
      case "defn-": return sf_func(form, false);
      case "defn": return sf_func(form, true);
      case "fn": return sf_anonFunc(form);
      case "try": return sf_try(form);
      case "if": return sf_if(form);
      case "str": return sf_str(form);
      case "[":
      case "vec": return sf_array(form);
      case "{":
      case "hash-map": return sf_object(form);
      case "include": return sf_include(form);
      case "js#": return sf_jscode(form);
      case "defmacro": return sf_macro(form);
      case "+":
      case "-":
      case "*":
      case "/":
      case "%":
        return sf_arithOp(form);
      break;
      case "||":
      case "&&":
      case "^":
      case "|":
      case "&":
      case ">>>":
      case ">>":
      case "<<":
        return sf_logicalOp(form);
      break;
      case "!=":
      case "==":
      case "=":
      case ">":
      case ">=":
      case "<":
      case "<=":
        return sf_compOp(form);
      break;
      case "!":
        return sf_not(form);
      break;
    }
  }

  evalSexp(form);

  let s,fName = form[0];
  if (!fName) {
    handleError(1, form._line);
  }
  if (REGEX.fn.test(fName)) {
    fName = tnodeChunk(["(", fName, ")"]);
  }

  return tnodeChunk([fName, "(",
                     tnodeChunk(form.slice(1)).join(","), ")"]);
}

//////////////////////////////////////////////////////////////////////////////
//
function evalSexp(sexp) {
  sexp.forEach(function(part, i, t) {
    if (isform(part)) { t[i] = evalForm(part); }
  });
}

//////////////////////////////////////////////////////////////////////////////
//
function evalMacro(mc, cmd, tree) {
  let args = mc["args"],
      code = mc["code"],
      vargs=false,
      tpos, i, frags = {};

  for (i = 0; i < args.length; ++i) {
    tpos=i+1; // skip the cmd at 0
    if (args[i].name === VARGS) {
      frags[TILDA_VARGS] = tree.slice(tpos);
      vargs=true;
      break;
    }
    //if (tpos >= tree.length) { synError("e17", tree, cmd); }
    frags[TILDA + args[i].name] =
      (tpos >= tree.length) ? tnodeChunk("undefined") : tree[tpos];
  }
  if (!vargs && (i+1) < tree.length) {
    synError("e16", tree, cmd);
  }

  // handle homoiconic expressions in macro
  let expand = function(source) {
    let ret= [],
        ename = "";

    ret._filename = tree._filename;
    ret._line = tree._line;

    if (source._array === true) {
      ret._array=true;
    }
    else if (source._object === true) {
      ret._object=true;
    }
    else
    if (isNode(source[0], source)) {
      ename=source[0].name;
    }

    if (REGEX.macroOp.test(ename)) {
      let s1name= source[1].name,
          a, g,
          frag = frags[TILDA + s1name];
      if (ename === "#<<") {
        if (!isarray(frag)) {
          synError("e13", tree, cmd);
        }
        return a = frag.shift();
        //if (a) { return a; }
        //synError("e12", tree, cmd);
      }
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


