// Generated by LispyScript v1.5.0
var TreeNode = (require("source-map"))["SourceNode"];
var fs = null,
  path = null;
((typeof(window) === "undefined") ?
    (function() {
  path = require("path");
  return fs = require("fs");
  })() :
  undefined);
var VERSION = "1.0.0",
  includePaths = [],
  noSemi_QUERY = false,
  indentSize = 2,
  VARGS = "&args",
  TILDA = "~",
  indentWidth = -indentSize,
  TILDA_VARGS = [TILDA,VARGS].join('');
var REGEX = {
  macroGet: new RegExp("^#slice@(\\d+)"),
  noret: new RegExp("^def\\b|^var\\b|^set!\\b|^throw\\b"),
  id: new RegExp("^[a-zA-Z_$][?\\-*!0-9a-zA-Z_$]*$"),
  id2: new RegExp("^[*][?\\-*!0-9a-zA-Z_$]+$"),
  func: new RegExp("^function\\b"),
  query: new RegExp("\\?","g"),
  bang: new RegExp("!","g"),
  dash: new RegExp("-","g"),
  star: new RegExp("\\*","g"),
  wspace: new RegExp("\\s")
};
var SPECIAL_OPS = {};
var MACROS_MAP = {};
var ERRORS_MAP = {
  e0: "Syntax Error",
  e1: "Empty statement",
  e2: "Invalid characters in function name",
  e3: "End of File encountered, unterminated string",
  e4: "Closing square bracket, without an opening square bracket",
  e5: "End of File encountered, unterminated array",
  e6: "Closing curly brace, without an opening curly brace",
  e7: "End of File encountered, unterminated javascript object '}'",
  e8: "End of File encountered, unterminated parenthesis",
  e9: "Invalid character in var name",
  e10: "Extra chars at end of file. Maybe an extra ')'.",
  e11: "Cannot Open include File",
  e12: "Invalid no of arguments to ",
  e13: "Invalid Argument type to ",
  e14: "End of File encountered, unterminated regular expression",
  e15: "Invalid vararg position, must be last argument.",
  e16: "Invalid arity (args > expected) to ",
  e17: "Invalid arity (args < expected) to "
};
function eval_QUERY_QUERY(x) {
  return ((Object.prototype.toString.call(x) === "[object Array]") ?
    evalList(~x) :
    ~x);
}
function conj_BANG_BANG(tree,obj) {
  (obj ?
    tree.push(obj) :
    undefined);
  return tree;
}
function testid(name) {
  return (REGEX.id.test(name) || REGEX.id2.test(name));
}
function normalizeId(name) {
  let pfx = "";
  (((Object.prototype.toString.call(name) === "[object String]") && ('-' === name.charAt(0))) ?
    pfx = "-" :
    name = name.slice(1));
  return (testid(name) ?
    [pfx,name.replace(REGEX.query,"_QUERY").replace(REGEX.bang,"_BANG").replace(REGEX.dash,"_").replace(REGEX.star,"_STAR")].join('') :
    ((pfx === "") ?
      name :
      [pfx,name].join('')));
}
function assert(cond,msg) {
  return ((!cond) ?
    throw new Error(msg); :
    undefined);
}
function node_QUERY(obj) {
  return ((Object.prototype.toString.call(obj) === "[object Object]") && (true === obj["$$$isSourceNode$$$"]));
}
function error_BANG(e,line,file,msg) {
  throw new Error([ERRORS_MAP[e],(msg ?
    [" : ",msg].join('') :
    undefined),(line ?
    ["\nLine no ",line].join('') :
    undefined),(file ?
    ["\nFile ",file].join('') :
    undefined)].join(''));;
}
var attr_file = "_file";
var attr_line = "_line";
function syntax_BANG(c,expr,cmd) {
  return error_BANG(c,expr[attr_line],expr[attr_file],cmd);
}
function pad(z) {
  return " ".repeat(z);
}
function tnodeString() {
  return   (function() {
  let s = "";
  return   (function() {
  this.walk(function (chunk,hint) {
    ((((hint)["name"] === chunk) && (Object.prototype.toString.call(chunk) === "[object String]")) ?
      chunk = normalizeId(chunk) :
      undefined);
    return s += chunk;
  });
  return s;
  })();
  })();
}
function tnode(ln,col,src,chunk,name) {
  return   (function() {
  let n = null;
  return   (function() {
  (((arguments)["length"] > 0) ?
    n = (name ?
      new TreeNode(ln,col,src,chunk,name) :
      new TreeNode(ln,col,src,chunk)) :
    n = new TreeNode());
  n[toString] = tnodeString;
  return n;
  })();
  })();
}
function tnodeChunk(chunk,name) {
  return tnode(null,null,null,chunk,name);
}
function toASTree(code,fname) {
  let codeStr = ["(",code,")"].join(''),
    state = {
      file: fname,
      lineno: 1,
      colno: 1,
      pos: 1,
      tknCol: 1
    };
  return   (function() {
  let ret = lexer(codeStr,state);
  return   (function() {
  (((state)["pos"] < (codeStr)["length"]) ?
    error_BANG("e10") :
    undefined);
  return ret;
  })();
  })();
}
function parseTree(root) {
  let pstr = "",
    endx = ((root)["length"] - 1),
    treeSize = (root)["length"];
  indentWidth += indentSize;
  pstr = pad(indentWidth);
  return   (function() {
  let ret = tnode();
  return   (function() {
  root.forEach(function (expr,i,tree) {
    let name = "",
      tmp = null,
      r = "";
    ((Object.prototype.toString.call(expr) === "[object Array]") ?
            (function() {
      let e = expr[0];
      (node_QUERY(e) ?
        name = (e)["name"] :
        undefined);
      tmp = evalList(expr);
      return ((name === "include") ?
                (function() {
        ret.add(tmp);
        return tmp = null;
        })() :
        undefined);
      })() :
      tmp = expr);
    (((i === endx) && (0 !== indentWidth) && (!REGEX.noret.test(name))) ?
      r = "return " :
      undefined);
    return (tmp ?
            (function() {
      ret.add([
        [pstr,r].join(''),
        tmp,
        ((!noSemi_QUERY) ?
          ";" :
          undefined),
        "\n"
      ]);
      return noSemi_QUERY = false;
      })() :
      undefined);
  });
  indentWidth -= indentSize;
  return ret;
  })();
  })();
}
function evalList2(expr) {
  let s = null,
    ename = "";
  evalConCells(expr);
  ename = expr[0];
  ((!ename) ?
    syntax_BANG("e1",expr) :
    undefined);
  (REGEX.fn.test(ename) ?
    ename = tnodeChunk([
      "(",
      ename,
      ")"
    ]) :
    undefined);
  return tnodeChunk([
    ename,
    "(",
    tnodeChunk(expr.slice(1)).join(","),
    ")"
  ]);
}
function evalList(expr) {
  let cmd = "",
    tmp = null,
    mc = null;
  ((true === (expr)["_object"]) ?
    cmd = "{" :
    ((true === (expr)["_array"]) ?
      cmd = "[" :
      ((((expr && ((expr)["length"] > 0)) ?
          expr :
          null) && node_QUERY(expr[0])) ?
                (function() {
        cmd = (expr[0])["name"];
        return mc = MACROS_MAP[cmd];
        })() :
        undefined)));
  return (Array.prototype.some.call(mc) ?
    eval_QUERY_QUERY(evalMacro(mc,expr)) :
    ((Object.prototype.toString.call(cmd) === "[object String]") ?
      (cmd.startsWith(".-") ?
                (function() {
        let ret = tnode();
        return         (function() {
        ret.add(eval_QUERY_QUERY(expr[1]));
        ret.prepend("(");
        ret.add([
          ")[\"",
          cmd.slice(2),
          "\"]"
        ]);
        return ret;
        })();
        })() :
        ((cmd.charAt(0) === '.') ?
                    (function() {
          let ret = tnode();
          return           (function() {
          ret.add(eval_QUERY_QUERY(expr[1]));
          ret.add([
            expr[0],
            "("
          ]);
          for (var i = 2; (i < (expr)["length"]); i = (i + 1)) {
                        (function() {
            ((i !== 2) ?
              ret.add(",") :
              undefined);
            return ret.add(eval_QUERY_QUERY(expr[i]));
            })();
          }
;
          ret.add(")");
          return ret;
          })();
          })() :
          (SPECIAL_OPS.hasOwnProperty(cmd) ?
            SPECIAL_OPS[cmd](expr) :
            (true ?
              evalList2(expr) :
              undefined)))) :
      (true ?
        evalList2(expr) :
        undefined)));
}
function evalConCells(cells) {
  return cells.forEach(function (cell,i,cc) {
    return ((Object.prototype.toString.call(cell) === "[object Array]") ?
      cc[i] = evalList(cell) :
      undefined);
  });
}
function expandMacro(code,data) {
  let ret = [],
    ename = "",
    s1name = "",
    tmp = null;
  ret["_filename"] = data["_filename"];
  ret["_line"] = data["_line"];
  (((Object.prototype.toString.call(code) === "[object Array]") && ((code)["length"] > 1)) ?
        (function() {
    s1name = (code[1])["name"];
    return frag = frags[[TILDA,s1name].join('')];
    })() :
    undefined);
  (((Object.prototype.toString.call(code) === "[object Array]") && ((code && ((code)["length"] > 0)) ?
      code :
      null)) ?
    ename = (code[0])["name"] :
    undefined);
  ((true === (code)["_object"]) ?
    ret["_object"] = true :
    ((true === (code)["_array"]) ?
      ret["_array"] = true :
      undefined));
  return ((ename === "#<<") ?
    ((!(Object.prototype.toString.call(frag) === "[object Array]")) ?
      syntax_BANG("e13",data,cmd) :
      frag.shift()) :
    ((ename === "#head") ?
      ((!(Object.prototype.toString.call(frag) === "[object Array]")) ?
        syntax_BANG("e13",data,cmd) :
        (((frag && ((frag)["length"] > 0)) ?
            frag :
            null) ?
          frag[0] :
          undefined)) :
      ((ename === "#tail") ?
        ((!(Object.prototype.toString.call(frag) === "[object Array]")) ?
          syntax_BANG("e13",data,cmd) :
          (((frag && ((frag)["length"] > 0)) ?
              frag :
              null) ?
                        (function() {
            let a = frag;
            return a[((a)["length"] - 1)];
            })() :
            undefined)) :
        (ename.startsWith("#evens") ?
                    (function() {
          let r = [];
          return           (function() {
          for (var i = 0; (i < (frag)["length"]); i = (i + 2)) {
                        (function() {
            return conj_BANG_BANG(r,frag[i]);
            })();
          }
;
          (ename.endsWith("*") ?
            r["___split"] = true :
            undefined);
          return r;
          })();
          })() :
          (ename.startsWith("#odds") ?
                        (function() {
            let r = [];
            return             (function() {
            for (var i = 1; (i < (frag)["length"]); i = (i + 2)) {
                            (function() {
              return conj_BANG_BANG(r,frag[i]);
              })();
            }
;
            (ename.endsWith("*") ?
              r["___split"] = true :
              undefined);
            return r;
            })();
            })() :
            (ename.startsWith("#slice@") ?
                            (function() {
              ((!(Object.prototype.toString.call(frag) === "[object Array]")) ?
                syntax_BANG("e13",data,cmd) :
                undefined);
              tmp = REGEX.macroGet.exec(ename);
              return frag.splice((tmp[1] - 1),1)[0];
              })() :
              ((ename === "#if") ?
                                (function() {
                ((!(Object.prototype.toString.call(frag) === "[object Array]")) ?
                  syntax_BANG("e13",data,cmd) :
                  undefined);
                return (((frag && ((frag)["length"] > 0)) ?
                    frag :
                    null) ?
                  expand(code[2]) :
                  ((((code)["length"] > 3) && code[3]) ?
                    expand(code[3]) :
                    (true ?
                      undefined :
                      undefined)));
                })() :
                (true ?
                                    (function() {
                  let cell = null;
                  for (var i = 0; (i < (code)["length"]); i = (i + 1)) {
                                        (function() {
                    cell = code[i];
                    return ((Object.prototype.toString.call(cell) === "[object Array]") ?
                                            (function() {
                      let c = expandMacro(cell);
                      return (((Object.prototype.toString.call(c) === "[object Array]") && (true === c["___split"])) ?
                        for (var k = 0; (k < (c)["length"]); k = (k + 1)) {
                                                    (function() {
                          return conj_BANG_BANG(ret,c[k]);
                          })();
                        }
 :
                        conj_BANG_BANG(ret,c));
                      })() :
                                            (function() {
                      let tn = (cell)["name"],
                        atSign_QUERY = false;
                      tmp = cell;
                      (tn.includes("@") ?
                                                (function() {
                        atSign_QUERY = true;
                        return tmp = tnode((token)["line"],(token)["column"],(token)["source"],tn.replace("@",""),tn.replace("@",""));
                        })() :
                        undefined);
                      return                       (function() {
                      let repl = frags[(tmp)["name"]];
                      return (Array.prototype.some.call(repl) ?
                                                (function() {
                        return ((atSign_QUERY || ((tmp)["name"] === TILDA_VARGS)) ?
                          for (var j = 0; (j < (repl)["length"]); j = (j + 1)) {
                                                        (function() {
                            return conj_BANG_BANG(ret,repl[j]);
                            })();
                          }
 :
                          conj_BANG_BANG(ret,repl));
                        })() :
                        conj_BANG_BANG(ret,cell));
                      })();
                      })());
                    })();
                  }
;
                  return ret;
                  })() :
                  undefined))))))));
}
function evalMacro(mc,data) {
  let args = mc["args"],
    cmd = mc["name"],
    code = mc["code"],
    vargs = false,
    tpos = 0,
    i = 0,
    frags = {};
  for (var i = 0,tpos = (i + 1); (i < (args)["length"]); i = (i + 1),tpos = (i + 1)) {
        (function() {
    return (((args[i])["name"] === VARGS) ?
            (function() {
      vargs = true;
      return frags[TILDA_VARGS] = data.slice(tpos);
      })() :
      frags[[TILDA,(args[i])["name"]].join('')] = ((tpos >= (data)["length"]) ?
        tnodeChunk("undefined") :
        data[tpos]));
    })();
  }
;
  (((!vargs) && ((i + 1) < (data)["length"])) ?
    syntax_BANG("e16",data,cmd) :
    undefined);
  return expandMacro(code,data);
}
function sf_compOp(expr) {
  (((expr)["length"] < 3) ?
    syntax_BANG("e0",expr) :
    undefined);
  evalConCells(expr);
  ((expr[0] == "!=") ?
    expr[0] = "!==" :
    undefined);
  ((expr[0] == "=") ?
    expr[0] = "===" :
    undefined);
  return   (function() {
  let ret = tnode();
  return   (function() {
  for (var i = 0,op = expr.shift(); (i < ((expr)["length"] - 1)); i = (i + 1)) {
        (function() {
    return ret.add(tnodeChunk([
      expr[i],
      " ",
      op,
      " ",
      expr[(i + 1)]
    ]));
    })();
  }
;
  ret.join(" && ");
  ret.prepend("(");
  ret.add(")");
  return ret;
  })();
  })();
}
[
  "!=",
  "==",
  "=",
  ">",
  ">=",
  "<",
  "<="
].forEach(function (k) {
  return SPECIAL_OPS[k] = sf_compOp;
});
function sf_arithOp(expr) {
  (((expr)["length"] < 3) ?
    syntax_BANG("e0",expr) :
    undefined);
  evalConCells(expr);
  let op = tnode();
  return   (function() {
  let ret = tnode();
  return   (function() {
  op.add([
    " ",
    expr.shift(),
    " "
  ]);
  ret.add(expr);
  ret.join(op);
  ret.prepend("(");
  ret.add(")");
  return ret;
  })();
  })();
}
[
  "+",
  "-",
  "*",
  "/",
  "%"
].forEach(function (k) {
  return SPECIAL_OPS[k] = sf_arithOp;
});
function sf_logicalOp(expr) {
  return sf_arithOp(expr);
}
[
  "||",
  "&&",
  "^",
  "|",
  "&",
  ">>>",
  ">>",
  "<<"
].forEach(function (k) {
  return SPECIAL_OPS[k] = sf_logicalOp;
});
function sf_repeat(expr) {
  (((expr)["length"] !== 3) ?
    syntax_BANG("e0",expr) :
    undefined);
  evalConCells(expr);
  return   (function() {
  let ret = tnode();
  return   (function() {
  for (var i = 0,end = parseInt((expr[1])["name"]); (i < end); i = (i + 1)) {
        (function() {
    ((i !== 0) ?
      ret.add(",") :
      undefined);
    return ret.add(expr[2]);
    })();
  }
;
  ret.prepend("[");
  ret.add("]");
  return ret;
  })();
  })();
}
SPECIAL_OPS["repeat-n"] = sf_repeat;
function sf_do(expr) {
  let end = ((expr)["length"] - 1),
    e = null,
    p = pad(indentWidth);
  return   (function() {
  let ret = tnode();
  return   (function() {
  for (var i = 1; (i < end); i = (i + 1)) {
        (function() {
    e = expr[i];
    return ret.add([
      p,
      evalList(e),
      ";\n"
    ]);
    })();
  }
;
  ((end > 0) ?
        (function() {
    e = eval_QUERY_QUERY(    (function() {
    let a = expr;
    return a[((a)["length"] - 1)];
    })());
    ret.add([
      p,
      "return ",
      e,
      ";\n"
    ]);
    ret.prepend([p,"(function() {\n"].join(''));
    return ret.add([p,"})()"].join(''));
    })() :
    undefined);
  return ret;
  })();
  })();
}
SPECIAL_OPS["do"] = sf_do;
function sf_doto(expr) {
  (((expr)["length"] < 2) ?
    syntax_BANG("e0",expr) :
    undefined);
  let p = pad(indentWidth),
    p2 = pad((indentWidth + indentSize)),
    p3 = pad((indentWidth + (2 * indentSize))),
    e = null,
    e1 = eval_QUERY_QUERY(expr[1]);
  return   (function() {
  let ret = tnode();
  return   (function() {
  ret.add([
    p2,
    "let ___x = ",
    e1,
    ";\n"
  ]);
  for (var i = 2; (i < (expr)["length"]); i = (i + 1)) {
        (function() {
    e = expr[i];
    e.splice(1,0,"___x");
    return ret.add([
      p3,
      evalList(e),
      ";\n"
    ]);
    })();
  }
;
  ret.add([
    p2,
    "return ___x;\n"
  ]);
  ret.prepend([p,"(function() {\n"].join(''));
  ret.add([p,"})()"].join(''));
  return ret;
  })();
  })();
}
SPECIAL_OPS["doto"] = s_doto;
function sf_range(expr) {
  ((((expr)["length"] < 2) || ((expr)["length"] > 4)) ?
    syntax_BANG("e0",expr) :
    undefined);
  let len = 0,
    start = 0,
    step = 1,
    end = 0;
  evalConCells(expr);
  len = (expr)["length"];
  end = parseInt((expr[1])["name"]);
  return   (function() {
  let ret = tnode();
  return   (function() {
  ((len > 2) ?
        (function() {
    start = parseInt((expr[1])["name"]);
    return end = parseInt((expr[2])["name"]);
    })() :
    undefined);
  ((len > 3) ?
    step = parseInt((expr[3])["name"]) :
    undefined);
  for (var i = start; (i < end); i = (i + step)) {
        (function() {
    ((i !== start) ?
      ret.add(",") :
      undefined);
    return ret.add(["",i].join(''));
    })();
  }
;
  ret.prepend("[");
  ret.add("]");
  return ret;
  })();
  })();
}
SPECIAL_OPS["range"] = sf_range;
function sf_var(expr,cmd) {
  ((((expr)["length"] < 3) || (0 === ((expr)["length"] % 2))) ?
    syntax_BANG("e0",expr) :
    undefined);
  (((expr)["length"] > 3) ?
    indentWidth += indentSize :
    undefined);
  evalConCells(expr);
  return   (function() {
  let ret = tnode();
  return   (function() {
  for (var i = 1; (i < (expr)["length"]); i = (i + 2)) {
        (function() {
    ((i > 1) ?
      ret.add([",\n",pad(indentWidth)].join('')) :
      undefined);
    ((!testid(expr[i])) ?
      syntax_BANG("e9",expr) :
      undefined);
    return ret.add([
      expr[i],
      " = ",
      expr[(i + 1)]
    ]);
    })();
  }
;
  ret.prepend(" ");
  ret.prepend(cmd);
  (((expr)["length"] > 3) ?
    indentWidth -= indentSize :
    undefined);
  return ret;
  })();
  })();
}
SPECIAL_OPS["var"] = function (x) {
  return sf_var(x,"let");
};
SPECIAL_OPS["def"] = function (x) {
  return sf_var(x,"var");
};
SPECIAL_OPS["def-"] = SPECIAL_OPS["def"];
function sf_new(expr) {
  (((expr)["length"] < 2) ?
    syntax_BANG("e0",expr) :
    undefined);
  return   (function() {
  let ret = tnode();
  return   (function() {
  ret.add(evalList(expr.slice(1)));
  ret.prepend("new ");
  return ret;
  })();
  })();
}
SPECIAL_OPS["new"] = sf_new;
function sf_throw(expr) {
  (((expr)["length"] !== 2) ?
    syntax_BANG("e0",expr,undefined) :
    undefined);
  return   (function() {
  let ret = tnode();
  return   (function() {
  ret.add(eval_QUERY_QUERY(expr[1]));
  ret.prepend("throw ");
  return ret;
  })();
  })();
}
SPECIAL_OPS["throw"] = sf_throw;
function sf_while(expr) {
  let f1 = expr[1];
  expr.splice(0,2,tnodeChunk("do","do"));
  return tnodeChunk([
    "while ",
    eval_QUERY_QUERY(f1),
    " {\n",
    evalList(expr),
    ";\n}\n"
  ]);
}
SPECIAL_OPS["while"] = sf_while;
function sf_x_opop(expr,op) {
  (((expr)["length"] !== 2) ?
    syntax_BANG("e0",expr) :
    undefined);
  return tnodeChunk([
    op,
    eval_QUERY_QUERY(expr[1])
  ]);
}
SPECIAL_OPS["dec!!"] = function (x) {
  return sf_x_opop(x,"--");
};
SPECIAL_OPS["inc!!"] = function (x) {
  return sf_x_opop(x,"++");
};
function sf_x_eq(expr,op) {
  (((expr)["length"] !== 3) ?
    syntax_BANG("e0",expr) :
    undefined);
  return tnodeChunk([
    expr[1],
    [" ",op,"= "].join(''),
    eval_QUERY_QUERY(expr[2])
  ]);
}
SPECIAL_OPS["dec!"] = function (x) {
  return sf_x_eq(x,"-");
};
SPECIAL_OPS["inc!"] = function (x) {
  return sf_x_eq(x,"+");
};
function sf_set(expr) {
  ((((expr)["length"] < 3) || ((expr)["length"] > 4)) ?
    syntax_BANG("e0",expr) :
    undefined);
  (((expr)["length"] === 4) ?
        (function() {
    ((Object.prototype.toString.call(expr[1]) === "[object Array]") ?
      expr[1] = evalList(expr[1]) :
      undefined);
    ((Object.prototype.toString.call(expr[2]) === "[object Array]") ?
      expr[2] = evalList(expr[2]) :
      undefined);
    expr[1] = [expr[1],"[",expr[2],"]"].join('');
    return expr[2] = expr[3];
    })() :
    undefined);
  return tnodeChunk([
    expr[1],
    " = ",
    eval_QUERY_QUERY(expr[2])
  ]);
}
SPECIAL_OPS["set!"] = sf_set;
function sf_anonFunc(expr) {
  (((expr)["length"] < 2) ?
    syntax_BANG("e0",expr) :
    undefined);
  ((!(Object.prototype.toString.call(expr[1]) === "[object Array]")) ?
    syntax_BANG("e0",expr) :
    undefined);
  let fArgs = expr[1],
    fBody = expr.slice(2);
  return   (function() {
  let ret = tnodeChunk(fArgs);
  return   (function() {
  ret.join(",");
  ret.prepend("function (");
  ret.add([
    ") {\n",
    parseTree(fBody),
    pad(indentWidth),
    "}"
  ]);
  return ret;
  })();
  })();
}
SPECIAL_OPS["fn"] = sf_anonFunc;
function sf_func(expr,public_QUERY) {
  (((expr)["length"] < 2) ?
    syntax_BANG("e0",expr) :
    undefined);
  let fName = null,
    fArgs = null,
    fBody = null;
  return   (function() {
  let ret = null;
  return   (function() {
  (((!(Object.prototype.toString.call(expr[1]) === "[object Array]")) && (Object.prototype.toString.call(expr[2]) === "[object Array]")) ?
        (function() {
    fName = normalizeId((expr[1])["name"]);
    fArgs = expr[2];
    return fBody = expr.slice(3);
    })() :
    syntax_BANG("e0",expr));
  ret = tnodeChunk(fArgs);
  ret.join(",");
  ret.prepend(["function ",fName,"("].join(''));
  ret.add([
    ") {\n",
    parseTree(fBody),
    pad(indentWidth),
    "}"
  ]);
  noSemi_QUERY = true;
  return ret;
  })();
  })();
}
SPECIAL_OPS["defn-"] = function (x) {
  return sf_func(x,false);
};
SPECIAL_OPS["defn"] = function (x) {
  return sf_func(x,true);
};
function sf_try(expr) {
  let sz = (expr)["length"],
    t = null,
    f = null,
    c = null,
    ind = pad(indentWidth);
  f =   (function() {
  let a = expr;
  return a[((a)["length"] - 1)];
  })();
  (((Object.prototype.toString.call(f) === "[object Array]") && ((f[0])["name"] === "finally")) ?
        (function() {
    f = expr.pop();
    return sz = (expr)["length"];
    })() :
    f = null);
  c = ((sz > 1) ?
    expr[(sz - 1)] :
    null);
  (((Object.prototype.toString.call(c) === "[object Array]") && ((c[0])["name"] === "catch")) ?
        (function() {
    ((((c)["length"] < 2) || (!node_QUERY(c[1]))) ?
      syntax_BANG("e0",expr) :
      undefined);
    return c = expr.pop();
    })() :
    c = null);
  (((Object.prototype.toString.call(f) === "[object Null]") && (Object.prototype.toString.call(c) === "[object Null]")) ?
    syntax_BANG("e0",expr) :
    undefined);
  return   (function() {
  let ret = tnodeChunk([
    ["(function() {\n",ind,"try {\n"].join(''),
    parseTree(expr.slice(1)),
    ["\n",ind,"} "].join('')
  ]);
  return   (function() {
  (c ?
        (function() {
    t = c[1];
    c.splice(0,2,tnodeChunk("do","do"));
    return ret.add([
      ["catch (",t,") {\n"].join(''),
      "return ",
      evalList(c),
      [";\n",ind,"}\n"].join('')
    ]);
    })() :
    undefined);
  (f ?
        (function() {
    f.splice(0,1,tnodeChunk("do","do"));
    return ret.add([
      "finally {\n",
      evalList(f),
      [";\n",ind,"}\n"].join('')
    ]);
    })() :
    undefined);
  ret.add([ind,"})()"].join(''));
  return ret;
  })();
  })();
}
SPECIAL_OPS["try"] = sf_try;
function sf_if(expr) {
  ((((expr)["length"] < 3) || ((expr)["length"] > 4)) ?
    syntax_BANG("e0",expr) :
    undefined);
  indentWidth += indentSize;
  evalConCells(expr);
  return (function() {
  try {
    return tnodeChunk([
      "(",
      expr[1],
      [" ?\n",pad(indentWidth)].join(''),
      expr[2],
      [" :\n",pad(indentWidth)].join(''),
      (expr[3] || "undefined"),
      ")"
    ]);

  } finally {
  (function() {
  return indentWidth -= indentSize;
  })();
  }
  })();
}
SPECIAL_OPS["if"] = sf_if;
function sf_get(expr) {
  (((expr)["length"] !== 3) ?
    syntax_BANG("e0",expr,undefined) :
    undefined);
  evalConCells(expr);
  return tnodeChunk([
    expr[1],
    "[",
    expr[2],
    "]"
  ]);
}
SPECIAL_OPS["get"] = sf_get;
SPECIAL_OPS["aget"] = SPECIAL_OPS["get"];
function sf_str(expr) {
  (((expr)["length"] < 2) ?
    syntax_BANG("e0",expr) :
    undefined);
  evalConCells(expr);
  return   (function() {
  let ret = tnode();
  return   (function() {
  ret.add(expr.slice(1));
  ret.join(",");
  ret.prepend("[");
  ret.add("].join('')");
  return ret;
  })();
  })();
}
SPECIAL_OPS["str"] = sf_str;
function sf_array(expr) {
  let p = pad(indentWidth),
    epilog = ["\n",p,"]"].join('');
  return   (function() {
  let ret = tnode();
  return   (function() {
  ((expr ?
      (0 === (expr)["length"]) :
      false) ?
    ret.add("[]") :
    (function() {
    try {
      ((!(true === (expr)["_array"])) ?
        expr.splice(0,1) :
        undefined);
      indentWidth += indentSize;
      evalConCells(expr);
      p = pad(indentWidth);
      ret.add(["[\n",p].join(''));
      for (var i = 0; (i < (expr)["length"]); i = (i + 1)) {
                (function() {
        ((i > 0) ?
          ret.add([",\n",p].join('')) :
          undefined);
        return ret.add(expr[i]);
        })();
      }
;
      return ret.add(epilog);

    } finally {
    (function() {
    return indentWidth -= indentSize;
    })();
    }
    })());
  return ret;
  })();
  })();
}
SPECIAL_OPS["["] = sf_array;
SPECIAL_OPS["vec"] = SPECIAL_OPS["["];
function sf_object(expr) {
  let p = pad(indentWidth),
    epilog = ["\n",p,"}"].join('');
  return   (function() {
  let ret = tnode();
  return   (function() {
  ((expr ?
      (0 === (expr)["length"]) :
      false) ?
    ret.add("{}") :
    (function() {
    try {
      ((!(true === (expr)["_object"])) ?
        expr.splice(0,1) :
        undefined);
      indentWidth += indentSize;
      evalConCells(expr);
      p = pad(indentWidth);
      ret.add(["{\n",p].join(''));
      for (var i = 0; (i < (expr)["length"]); i = (i + 2)) {
                (function() {
        ((i > 0) ?
          ret.add([",\n",p].join('')) :
          undefined);
        return ret.add([
          expr[i],
          ": ",
          expr[(i + 1)]
        ]);
        })();
      }
;
      return ret.add(epilog);

    } finally {
    (function() {
    return indentWidth -= indentSize;
    })();
    }
    })());
  return ret;
  })();
  })();
}
SPECIAL_OPS["{"] = sf_object;
SPECIAL_OPS["hash-map"] = SPECIAL_OPS["{"];
var includeFile = (function () {
  let icache = [];
  return function (fname) {
    return ((icache.indexOf(fname) !== -1) ?
      "" :
            (function() {
      icache.push(fname);
      return processTree(toASTree(fs.readFileSync(fname),fname));
      })());
  };
})();
function sf_include(expr) {
  (((expr)["length"] !== 2) ?
    syntax_BANG("e0",expr,undefined) :
    undefined);
  let found = false,
    fname = (expr[1])["name"];
  ((Object.prototype.toString.call(fname) === "[object String]") ?
    fname = fname.replace(new RegExp("[\"']",,"g"),"") :
    undefined);
  indentWidth -= indentSize;
  includePaths.concat([
    path.dirname((expr)["_file"])
  ]).forEach(function (pfx) {
    return (function() {
    try {
      return ((!found) ?
                (function() {
        fname = fs.realpathSync([pfx,"/",fname].join(''));
        return found = true;
        })() :
        undefined);

    } catch (err) {
return     (function() {
    return null;
    })();
    }
    })();
  });
  ((!found) ?
    syntax_BANG("e11",expr) :
    undefined);
  return (function() {
  try {
    return includeFile(fname);

  } finally {
  (function() {
  return indentWidth += indentSize;
  })();
  }
  })();
}
SPECIAL_OPS["include"] = sf_include;
function sf_ns(expr) {
  return "";
}
SPECIAL_OPS["ns"] = sf_ns;
function sf_comment(expr) {
  return "";
}
SPECIAL_OPS["comment"] = sf_comment;
function sf_floop(expr) {
  (((expr)["length"] < 2) ?
    syntax_BANG("e0",expr) :
    undefined);
  let c1 = null,
    c2 = null,
    c3 = null,
    c = expr[1],
    ind = pad(indentWidth);
  return   (function() {
  let ret = tnodeChunk("for (");
  return   (function() {
  (((!(Object.prototype.toString.call(c) === "[object Array]")) || ((c)["length"] !== 3)) ?
    syntax_BANG("e0",expr) :
    undefined);
  c1 = c[0];
  c2 = c[1];
  c3 = c[2];
  indentWidth += indentSize;
  for (var i = 0; (i < (c1)["length"]); i = (i + 2)) {
        (function() {
    ((i === 0) ?
      ret.add("var ") :
      undefined);
    ((i !== 0) ?
      ret.add(",") :
      undefined);
    return ret.add([
      c1[i],
      " = ",
      eval_QUERY_QUERY(c1[(i + 1)])
    ]);
    })();
  }
;
  ret.add("; ");
  ret.add(evalList(c2));
  ret.add("; ");
  for (var i = 0; (i < (c3)["length"]); i = (i + 2)) {
        (function() {
    ((i !== 0) ?
      ret.add(",") :
      undefined);
    return ret.add([
      c3[i],
      " = ",
      eval_QUERY_QUERY(c3[(i + 1)])
    ]);
    })();
  }
;
  ret.add(") {\n");
  (((expr)["length"] > 2) ?
        (function() {
    expr.splice(0,2,tnodeChunk("do","do"));
    return ret.add([
      ind,
      pad(indentSize),
      evalList(expr),
      ";"
    ]);
    })() :
    undefined);
  ret.add(["\n",ind,"}\n"].join(''));
  indentWidth -= indentSize;
  return ret;
  })();
  })();
}
SPECIAL_OPS["for"] = sf_floop;
function sf_jscode(expr) {
  (((expr)["length"] !== 2) ?
    syntax_BANG("e0",expr,undefined) :
    undefined);
  noSemi_QUERY = true;
  expr[1].replaceRight(new RegExp("\"","g"),"");
  return expr[1];
}
SPECIAL_OPS["js#"] = sf_jscode;
function sf_macro(expr) {
  (((expr)["length"] !== 4) ?
    syntax_BANG("e0",expr,undefined) :
    undefined);
  let a2 = expr[2],
    a3 = expr[3],
    cmd = (expr[1])["name"];
  return   (function() {
  let ret = "";
  return   (function() {
  for (var i = 0; (i < (a2)["length"]); i = (i + 1)) {
        (function() {
    return ((((a2[i])["name"] === VARGS) && ((i + 1) !== (a2)["length"])) ?
      syntax_BANG("e15",expr,cmd) :
      undefined);
    })();
  }
;
  MACROS_MAP[cmd] = {
    args: a2,
    code: a3,
    name: cmd
  };
  return ret;
  })();
  })();
}
SPECIAL_OPS["defmacro"] = sf_macro;
function sf_not(expr) {
  (((expr)["length"] !== 2) ?
    syntax_BANG("e0",expr,undefined) :
    undefined);
  evalConCells(expr);
  return ["(!",expr[1],")"].join('');
}
SPECIAL_OPS["!"] = sf_not;
function dbg(obj,hint) {
  return ((Object.prototype.toString.call(obj) === "[object Array]") ?
        (function() {
    hint = (hint || "block");
    console.log(["<",hint,">"].join(''));
    for (var i = 0; (i < (obj)["length"]); i = (i + 1)) {
            (function() {
      return dbg(obj[i]);
      })();
    }
;
    return console.log(["</",hint,">"].join(''));
    })() :
    (node_QUERY(obj) ?
            (function() {
      console.log("<node>");
      console.log(obj);
      dbg((obj)["children"],"subs");
      return console.log("</node>");
      })() :
      (true ?
        console.log(obj) :
        undefined)));
}
function dbgAST(codeStr,fname) {
  return dbg(toASTree(codeStr,fname),"tree");
}
function compileCode(codeStr,fname,withSrcMap_QUERY,incPaths) {
  ((Object.prototype.toString.call(incPaths) === "[object Array]") ?
    includePaths = incPaths :
    undefined);
  indentWidth = -indentSize;
  let outNode = parseTree(toASTree(codeStr,fname));
  outNode.prepend(banner);
  return (withSrcMap_QUERY ?
        (function() {
    let outFile = [path.basename(fname,".lisp"),".js"].join(''),
      srcMap = [outFile,".map"].join(''),
      output = outNode.toStringWithSourceMap({
        file: outFile
      });
    fs.writeFileSync(srcMap,(output)["map"]);
    [(output)["code"],"\n//# sourceMappingURL=",path.relative(path.dirname(fname),srcMap)].join('');
    return outNode.toString();
    })() :
    undefined);
}
exports["transpileWithSrcMap"] = function (code,file,incDirs) {
  return compileCode(code,file,true,incDirs);
};
exports["transpile"] = function (code,file,incDirs) {
  return compileCode(code,file,false,incDirs);
};
exports["version"] = version;
exports["dbgAST"] = dbgAST;
exports["parseWithSourceMap"] = function (codeStr,fname) {
  let outNode = processTree(toASTree(codeStr,fname));
  outNode.prepend(banner);
  return outNode.toStringWithSourceMap();
};
