// Generated by LispyScript v1.5.0
require("./require");
function evalMacro(mc,cmd,tree) {
  let args = mc["args"],
    code = mc["code"],
    vargs = false,
    tpos = 0,
    i = 0,
    frags = {};
  for (var i = 0; (i < (args)["length"]); i = (i + 1)) {
        (function() {
    tpos = (i + 1);
    return (((args[i])["name"] === VARGS) ?
            (function() {
      frags[TILDA_VARGS] = tree.slice(tpos);
      return vargs = true;
      })() :
      frags[[TILDA,(args[i])["name"]].join('')] = ((tpos >= tree.alen()) ?
        tnodeChunk("undefined") :
        tree[tpos]));
    })();
  }
;
  (((!vargs) && ((i + 1) < (tree)["length"])) ?
    synError("e16",tree,cmd) :
    undefined);
  let expand = function (source) {
    let ret = [],
      ename = "",
      a = null,
      hack = null;
    ret["_filename"] = (tree)["_filename"];
    ret["_line"] = (tree)["line"];
    (isNode_QUERY(source[0]) ?
      ename = (source[0])["name"] :
      undefined);
    (REGEX.macroOp.test(ename) ?
            (function() {
      let s1name = (source[1])["name"],
        g = null,
        frag = frags[[TILDA,s1name].join('')];
      ((ename === "#<<") ?
                (function() {
        ((!isarray_QUERY(frag)) ?
          synError("e13",tree,cmd) :
          undefined);
        a = frag.shift();
        (isUndef_QUERY(a) ?
          synError("e12",tree,cmd) :
          undefined);
        return hack = [
          a
        ];
        })() :
        undefined);
      ((ename === "#head") ?
                (function() {
        ((!isarray_QUERY(frag)) ?
          synError("e13",tree,cmd) :
          undefined);
        return hack = [
          frag[0]
        ];
        })() :
        undefined);
      ((ename === "#tail") ?
                (function() {
        ((!isarray_QUERY(frag)) ?
          synError("e13",tree,cmd) :
          undefined);
        return hack = [
                    (function() {
          let a = frag;
          return a[((a)["length"] - 1)];
          })()
        ];
        })() :
        undefined);
      (ename.startsWith("#slice@") ?
                (function() {
        ((!isarray_QUERY(frag)) ?
          synError("e13",tree,cmd) :
          undefined);
        g = REGEX.macroGet.exec(ename);
        ((true === (g && (2 === (g)["length"]) && (g[1] > 0))) ?
          ["Passed - ",["Invalid macro slice: ",ename].join('')].join('') :
          ["Failed - ",["Invalid macro slice: ",ename].join('')].join(''));
        a = frag.splice((g[1] - 1),1)[0];
        (isUndef_QUERY(a) ?
          synError("e12",tree,cmd) :
          undefined);
        return hack = [
          a
        ];
        })() :
        undefined);
      return ((ename === "#if") ?
                (function() {
        ((!isarray_QUERY(frag)) ?
          synError("e13",tree,cmd) :
          undefined);
        return (((frag)["length"] > 0) ?
          hack = [
            expand(source[2])
          ] :
          (source[3] ?
            hack = [
              expand(source[3])
            ] :
            hack = [
              undefined
            ]));
        })() :
        undefined);
      })() :
      undefined);
    for (var i = 0; ((Object.prototype.toString.call(hack) === "[object Null]") && (i < (source)["length"])); i = (i + 1)) {
            (function() {
      return (isarray_QUERY(source[i]) ?
                (function() {
        a = expand(source[i]);
        return (a ?
          ret.push(a) :
          undefined);
        })() :
                (function() {
        let token = source[i],
          bak = token,
          isATSign = false;
        (((token)["name"].indexOf("@") >= 0) ?
                    (function() {
          isATSign = true;
          return bak = tnode((token)["line"],(token)["column"],(token)["source"],(token)["name"].replace("@",""),(token)["name"].replace("@",""));
          })() :
          undefined);
        return (frags[(bak)["name"]] ?
                    (function() {
          a = frags[(bak)["name"]];
          return ((isATSign || ((bak)["name"] === TILDA_VARGS)) ?
            for (var j = 0; (j < (a)["length"]); j = (j + 1)) {
                            (function() {
              return ret.push(a[j]);
              })();
            }
 :
            ret.push(repl));
          })() :
          ret.push(token));
        })());
      })();
    }
;
    return ((Object.prototype.toString.call(hack) === "[object Array]") ?
      hack[0] :
      ret);
  };
  return expand(code);
}
function sf_compOp(list) {
  (((list)["length"] < 3) ?
    synError("e0",list) :
    undefined);
  evalSexp(list);
  ((list[0] == "!=") ?
    list[0] = "!==" :
    undefined);
  ((list[0] == "=") ?
    list[0] = "===" :
    undefined);
  let op = list.shift(),
    ret = tnode(),
    end = ((list)["length"] - 1);
  for (var i = 0; (i < end); i = (i + 1)) {
        (function() {
    return ret.add(tnodeChunk([
      list[i],
      " ",
      op,
      " ",
      list[(i + 1)]
    ]));
    })();
  }
;
  return   (function() {
    let ___x = ret;
      ___x.join(" && ");
      ___x.prepend("(");
      ___x.add(")");
    return ___x;
  })();
}
function sf_arithOp(list) {
  (((list)["length"] < 3) ?
    synError("e0",list) :
    undefined);
  evalSexp(list);
  let op = tnode(),
    ret = tnode();
  op.add([
    " ",
    list.shift(),
    " "
  ]);
  ret.add(list);
  ret.join(op);
  ret.prepend("(");
  ret.add(")");
  return ret;
}
function sf_logicalOp(list) {
  return sf_arithOp(list);
}
function sf_repeat(arr) {
  (((arr)["length"] !== 3) ?
    synError("e0",arr) :
    undefined);
  evalSexp(arr);
  let ret = tnode(),
    end = parseInt((arr[1])["name"]);
  for (var i = 0; (i < end); i = (i + 1)) {
        (function() {
    ((i !== 0) ?
      ret.add(",") :
      undefined);
    return ret.add(arr[2]);
    })();
  }
;
  ret.prepend("[");
  ret.add("]");
  return ret;
}
function sf_do(list) {
  let end = ((list)["length"] - 1),
    last = list[end],
    p = pad(gIndent),
    ret = tnode(),
    e = null;
  for (var i = 1; (i < end); i = (i + 1)) {
        (function() {
    e = list[i];
    return ret.add([
      p,
      evalForm(e),
      ";\n"
    ]);
    })();
  }
;
  e = (isform_QUERY(last) ?
    evalForm(last) :
    last);
  return   (function() {
    let ___x = ret;
      ___x.add([
    p,
    "return ",
    e,
    ";\n"
  ]);
      ___x.prepend([p,"(function() {\n"].join(''));
      ___x.add([p,"})()"].join(''));
    return ___x;
  })();
}
function sf_doto(list) {
  (((list)["length"] < 2) ?
    synError("e0",list) :
    undefined);
  let ret = tnode(),
    p = pad(gIndent),
    p2 = pad((gIndent + gIndentSize)),
    p3 = pad((gIndent + (2 * gIndentSize))),
    e = null,
    e1 = list[0];
  e1 = (isform_QUERY(e1) ?
    evalForm(e1) :
    e1);
  ret.add([
    p2,
    "let ___x = ",
    e1,
    ";\n"
  ]);
  for (var i = 2; (i < (list)["length"]); i = (i + 1)) {
        (function() {
    e = list[i];
    e.splice(1,0,"___x");
    return ret.add([
      p3,
      evalForm(e),
      ";\n"
    ]);
    })();
  }
;
  return   (function() {
    let ___x = ret;
      ___x.add([
    p2,
    "return ___x;\n"
  ]);
      ___x.prepend([p,"(function() {\n"].join(''));
      ___x.add([p,"})()"].join(''));
    return ___x;
  })();
}
function sf_range(arr) {
  ((((arr)["length"] < 2) || ((arr)["length"] > 4)) ?
    synError("e0",arr) :
    undefined);
  evalSexp(arr);
  let ret = tnode(),
    len = (arr)["length"],
    start = 0,
    step = 1,
    end = parseInt((arr[1])["name"]);
  ((len > 2) ?
        (function() {
    start = parseInt((arr[1])["name"]);
    return end = parseInt((arr[2])["name"]);
    })() :
    undefined);
  ((len > 3) ?
    step = parseInt((arr[3])["name"]) :
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
}
function sf_var(arr,cmd) {
  ((((arr)["length"] < 3) || (0 === ((arr)["length"] % 2))) ?
    synError("e0",arr) :
    undefined);
  (((arr)["length"] > 3) ?
    gIndent = (gIndent + gIndentSize) :
    undefined);
  evalSexp(arr);
  let ret = tnode();
  for (var i = 1; (i < (arr)["length"]); i = (i + 2)) {
        (function() {
    ((i > 1) ?
      ret.add([",\n",pad(gIndent)].join('')) :
      undefined);
    ((!REGEX.id.test(arr[i])) ?
      synError("e9",arr) :
      undefined);
    return ret.add([
      arr[i],
      " = ",
      arr[(i + 1)]
    ]);
    })();
  }
;
  ret.prepend(" ");
  ret.prepend(cmd);
  (((arr)["length"] > 3) ?
    gIndent = (gIndent - gIndentSize) :
    undefined);
  return ret;
}
function sf_new(arr) {
  (((arr)["length"] < 2) ?
    synError("e0",arr) :
    undefined);
  let ret = tnode();
  ret.add(evalForm(arr.slice(1)));
  ret.prepend("new ");
  return ret;
}
function sf_throw(arr) {
  assertArgs(arr,2,"e0");
  let ret = tnode();
  ret.add((isform_QUERY(arr[1]) ?
    evalForm(arr[1]) :
    arr[1]));
  ret.prepend("throw ");
  ret.add(";");
  return ret;
}
function sf_set(arr) {
  ((((arr)["length"] < 3) || ((arr)["length"] > 4)) ?
    synError("e0",arr) :
    undefined);
  (((arr)["length"] === 4) ?
        (function() {
    (isform_QUERY(arr[1]) ?
      arr[1] = evalForm(arr[1]) :
      undefined);
    (isform_QUERY(arr[2]) ?
      arr[2] = evalForm(arr[2]) :
      undefined);
    arr[1] = [arr[1],"[",arr[2],"]"].join('');
    return arr[2] = arr[3];
    })() :
    undefined);
  return tnodeChunk([
    arr[1],
    " = ",
    (isform_QUERY(arr[2]) ?
      evalForm(arr[2]) :
      arr[2])
  ]);
}
function sf_anonFunc(arr) {
  (((arr)["length"] < 2) ?
    synError("e0",arr) :
    undefined);
  ((!isform_QUERY(arr[1])) ?
    synError("e0",arr) :
    undefined);
  let fArgs = arr[1],
    fBody = arr.slice(2),
    ret = tnodeChunk(fArgs);
  ret.join(",");
  ret.prepend("function (");
  ret.add([
    ") {\n",
    evalAST(fBody),
    pad(gIndent),
    "}"
  ]);
  return ret;
}
function sf_func(arr,public_QUERY) {
  (((arr)["length"] < 2) ?
    synError("e0",arr) :
    undefined);
  let ret = null,
    fName = null,
    fArgs = null,
    fBody = null;
  (((!isform_QUERY(arr[1])) && isform_QUERY(arr[2])) ?
        (function() {
    fName = normalizeId((arr[1])["name"]);
    fArgs = arr[2];
    return fBody = arr.slice(3);
    })() :
    synError("e0",arr));
  ret = tnodeChunk(fArgs);
  ret.join(",");
  ret.prepend(["function ",fName,"("].join(''));
  ret.add([
    ") {\n",
    evalAST(fBody),
    pad(gIndent),
    "}"
  ]);
  gNoSemiColon = true;
  return ret;
}
function sf_try(arr) {
  let sz = (arr)["length"],
    t = null,
    f = null,
    c = null,
    ret = null,
    ind = pad(gIndent);
  f = arr[(sz - 1)];
  ((isform_QUERY(f) && ((f[0])["name"] === "finally")) ?
        (function() {
    f = arr.pop();
    return sz = (arr)["length"];
    })() :
    f = null);
  c = ((sz > 1) ?
    arr[(sz - 1)] :
    null);
  ((isform_QUERY(c) && ((c[0])["name"] === "catch")) ?
        (function() {
    ((((c)["length"] < 2) || (!isNode_QUERY(c[1]))) ?
      synError("e0",arr) :
      undefined);
    return c = arr.pop();
    })() :
    c = null);
  (((Object.prototype.toString.call(f) === "[object Null]") && (Object.prototype.toString.call(c) === "[object Null]")) ?
    synError("e0",arr) :
    undefined);
  ret = tnodeChunk([
    ["(function() {\n",ind,"try {\n"].join(''),
    evalAST(arr.slice(1)),
    ["\n",ind,"} "].join('')
  ]());
  (c ?
        (function() {
    t = c[1];
    c.splice(0,2,tnodeChunk("do","do"));
    return ret.add([
      ["catch (",t,") {\n"].join(''),
      evalForm(c),
      [";\n",ind,"}\n"].join('')
    ]);
    })() :
    undefined);
  (f ?
        (function() {
    f.splice(0,1,tnodeChunk("do","do"));
    return ret.add([
      "finally {\n",
      evalForm(f),
      [";\n",ind,"}\n"].join('')
    ]);
    })() :
    undefined);
  ret.add([ind,"})()"].join(''));
  return ret;
}
function sf_if(arr) {
  ((((arr)["length"] < 3) || ((arr)["length"] > 4)) ?
    synError("e0",arr) :
    undefined);
  gIndent = (gIndent + gIndentSize);
  evalSexp(arr);
  return (function() {
  try {
    return tnodeChunk([
      "(",
      arr[1],
      [" ?\n",pad(gIndent)].join(''),
      arr[2],
      [" :\n",pad(gIndent)].join(''),
      (arr[3] || "undefined"),
      ")"
    ]);

  } finally {
  (function() {
  return gIndent = (gIndent - gIndentSize);
  })();
  }
  })();
}
function sf_get(arr) {
  assertArgs(arr,3,"e0");
  evalSexp(arr);
  return tnodeChunk([
    arr[1],
    "[",
    arr[2],
    "]"
  ]);
}
function sf_str(arr) {
  (((arr)["length"] < 2) ?
    synError("e0",arr) :
    undefined);
  evalSexp(arr);
  return   (function() {
  let ret = tnode();
  return   (function() {
  ret.add(arr.slice(1));
  ret.join(",");
  ret.prepend("[");
  ret.add("].join('')");
  return ret;
  })();
  })();
}
function sf_array(arr) {
  let ret = tnode(),
    p = pad(gIndent),
    epilog = ["\n",p,"]"].join('');
  return ((1 === (arr)["length"]) ?
        (function() {
    ret.add("[]");
    return ret;
    })() :
    (function() {
    try {
      gIndent = (gIndent + gIndentSize);
      evalSexp(arr);
      p = pad(gIndent);
      ret.add(["[\n",p].join(''));
      for (var i = 1; (i < (arr)["length"]); i = (i + 1)) {
                (function() {
        ((i > 1) ?
          ret.add([",\n",p].join('')) :
          undefined);
        return ret.add(arr[i]);
        })();
      }
;
      ret.add(epilog);
      return ret;

    } finally {
    (function() {
    return gIndent = (gIndent - gIndentSize);
    })();
    }
    })());
}
function sf_object(arr) {
  let ret = tnode(),
    p = pad(gIndent),
    epilog = ["\n",p,"}"].join('');
  return ((1 === (arr)["length"]) ?
        (function() {
    ret.add("{}");
    return ret;
    })() :
    (function() {
    try {
      gIndent = (gIndent + gIndentSize);
      evalSexp(arr);
      p = pad(gIndent);
      ret.add(["{\n",p].join(''));
      for (var i = 1; (i < (arr)["length"]); i = (i + 2)) {
                (function() {
        ((i > 1) ?
          ret.add([",\n",p].join('')) :
          undefined);
        return ret.add([
          arr[i],
          ": ",
          arr[(i + 1)]
        ]);
        })();
      }
;
      ret.add(epilog);
      return ret;

    } finally {
    (function() {
    return gIndent = (gIndent - gIndentSize);
    })();
    }
    })());
}
function includeFile() {
  let icache = [];
  return function (fname) {
    return ((-1 !== icache.indexOf(fname)) ?
      "" :
            (function() {
      icache.push(fname);
      return evalAST(toAST(fs.readFileSync(fname),fname));
      })());
  };
}
function sf_include(arr) {
  assertArgs(arr,2,"e0");
  let found = false,
    fname = (arr[1])["name"];
  ((Object.prototype.toString.call(fname) === "[object String]") ?
    fname = fname.replace(new Regex("\"'","g"),"") :
    undefined);
  gIndent = (gIdent - gIndentSize);
  gIncludePaths.concat([
    path.dirname((arr)["_filename"])
  ]);
  ((!Array.prototype.some.call(gIncludePaths,function (elem) {
      return (function() {
      try {
        return         (function() {
        fname = fs.realpathSync([elem,"/",fname].join(''));
        return true;
        })();

      } catch (e) {
      (function() {
      return undefined;
      })();
      }
      })();
    })) ?
        (function() {
    return synError("e11",arr);
    })() :
    undefined);
  return (function() {
  try {
    return includeFile()(fname);

  } finally {
  (function() {
  return gIndent = (gIndent + gIndentSize);
  })();
  }
  })();
}
function sf_ns(arr) {
  return "";
}
function sf_comment(arr) {
  return "";
}
function sf_jscode(arr) {
  assertArgs(arr,2,"e0");
  gNoSemiColon = true;
  arr[1].replaceRight(new Regex("\"","g"),"");
  return arr[1];
}
function sf_macro(arr) {
  assertArgs(arr,4,"e0");
  assertNode(arr[1]);
  assertForm(arr[2]);
  (function () {
    let recur = null,
      ___xs = null,
      ___f = function (i,times) {
        return ((times > i) ?
                    (function() {
          ((((arr[2][i])["name"] === VARGS) && ((i + 1) !== (arr[2])["length"])) ?
            synError("e15",arr,(arr[1])["name"]) :
            undefined);
          return recur((i + 1),times);
          })() :
          undefined);
      },
      ___ret = ___f;
    recur = function () {
      ___xs = arguments;
      return ((!(typeof(___ret) === "undefined")) ?
                (function() {
        for (___ret=undefined; ___ret===undefined; ___ret=___f.apply(this,___xs));;
        return ___ret;
        })() :
        undefined)
    };
    return recur(0,(arr[2])["length"]);
  })();
  MACROS_MAP[(arr[1])["name"]] = {
    args: arr[2],
    code: arr[3]
  };
  return "";
}
function sf_not(arr) {
  assertArgs(arr,2,"e0");
  evalSexp(arr);
  return ["(!",arr[1],")"].join('');
}
function dbg(obj,hint) {
  return ((Object.prototype.toString.call(obj) === "[object Array]") ?
        (function() {
    hint = (hint || "block");
    console.log(["<",hint,">"].join(''));
    (function () {
      let recur = null,
        ___xs = null,
        ___f = function (i,times) {
          return ((times > i) ?
                        (function() {
            dbg(obj[i]);
            return recur((i + 1),times);
            })() :
            undefined);
        },
        ___ret = ___f;
      recur = function () {
        ___xs = arguments;
        return ((!(typeof(___ret) === "undefined")) ?
                    (function() {
          for (___ret=undefined; ___ret===undefined; ___ret=___f.apply(this,___xs));;
          return ___ret;
          })() :
          undefined)
      };
      return recur(0,(obj)["length"]);
    })();
    return console.log(["</",hint,">"].join(''));
    })() :
    (isNode_QUERY(obj) ?
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
  return dbg(toAST(codeStr,fname),"tree");
}
function compileCode(codeStr,fname,srcMap_QUERY,incPaths) {
  ((Object.prototype.toString.call(incPaths) === "[object Array]") ?
    gIncludePaths = incPaths :
    undefined);
  gIndent = (gIndent - gIndentSize);
  let outNode = evalAST(toAST(codeStr,fname));
  outNode.prepend(gBanner);
  return (srcMap_QUERY ?
        (function() {
    let outFile = [path.basename(fname,".lisp"),".js"].join(''),
      srcMap = [outFile,".map"].join(''),
      output = outNode.toStringWithSourceMap({
        file: outFile
      });
    fs.writeFileSync(srcMap,(output)["map"]);
    return [(output)["code"],"\n//# sourceMappingURL=",path.relative(path.dirname(fname),srcMap)].join('');
    })() :
    outNode.toString());
}
