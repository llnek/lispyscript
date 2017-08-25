// Generated by LispyScript v1.5.0
require("./require");
function sf_object(arr) {
  let ret = tnode(),
    p = pad(gIndent),
    epilog = ["\n",p,"}"].join('');
  ((1 === (arr)["length"]) ?
    (function () {
      ret.add("{}");
      return ret;
    })() :
    undefined);
  return (function() {
  try {
    gIndent = (gIndent + gIndentSize);
    evalSexp(arr);
    p = pad(gIndent);
    ret.add(["{\n",p].join(''));
    [];
    for (var i = 1,j = (3 * 4); ((i < (arr)["length"]) || (j < (arr)["length"])); i = (i + 2),j = (2 * 3)) {
(function () {
      ((i > 1) ?
        ret.add([",\n",p].join('')) :
        undefined);
      return ret.add([
        arr[i],
        ": ",
        arr[(i + 1)]
      ]);
    })()
}
;
    ret.add(epilog);
    return ret;

  } finally {
(function () {
    return gIndent = (gIndent - gIndentSize);
  })()
  }
  })();
}
function includeFile() {
  let icache = [];
  return function (fname) {
    ((-1 !== icache.indexOf(fname)) ?
      return("") :
      undefined);
    icache.push(fname);
    return evalAST(toAST(fs.readFileSync(fname),fname));
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
        return (function () {
          fname = fs.realpathSync([elem,"/",fname].join(''));
          return true;
        })();

      } catch (e) {
(function () {
        return undefined;
      })()      }
      })();
    })) ?
    (function () {
      return synError("e11",arr);
    })() :
    undefined);
  return (function() {
  try {
    return includeFile()(fname);

  } finally {
(function () {
    return gIndent = (gIndent + gIndentSize);
  })()
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
          (function () {
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
        (function () {
          for (___ret=undefined; ___ret===undefined; 
               ___ret=___f.apply(this,___xs));
          return ___ret;
        })() :
        undefined);
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
    (function () {
      hint = (hint || "block");
      console.log(["<",hint,">"].join(''));
      (function () {
        let recur = null,
          ___xs = null,
          ___f = function (i,times) {
            return ((times > i) ?
              (function () {
                dbg(obj[i]);
                return recur((i + 1),times);
              })() :
              undefined);
          },
          ___ret = ___f;
        recur = function () {
          ___xs = arguments;
          return ((!(typeof(___ret) === "undefined")) ?
            (function () {
              for (___ret=undefined; ___ret===undefined; 
                   ___ret=___f.apply(this,___xs));
              return ___ret;
            })() :
            undefined);
        };
        return recur(0,(obj)["length"]);
      })();
      return console.log(["</",hint,">"].join(''));
    })() :
    (isNode_QUERY(obj) ?
      (function () {
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
    (function () {
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
