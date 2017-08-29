// Generated by LispyScript v1.5.0
var testTemplate = function (one,two,three) {
  return ["1",one,"2",two,"3",three].join('');
};
function namedFn(x,y) {
  return (x + y);
}
function namedFnNoSpaceBeforeArgs(x,y) {
  return (x - y);
}
let lispyscript = function () {
  return [
    ((true === (true === true)) ?
      ["Passed - ","(true? true)"].join('') :
      ["Failed - ","(true? true)"].join('')),
    ((true === (false === false)) ?
      ["Passed - ","(false? false)"].join('') :
      ["Failed - ","(false? false)"].join('')),
    ((true === (false === (true === {}))) ?
      ["Passed - ","(false? (true? {}))"].join('') :
      ["Failed - ","(false? (true? {}))"].join('')),
    ((true === (typeof(undefined) === "undefined")) ?
      ["Passed - ","(undefined? undefined)"].join('') :
      ["Failed - ","(undefined? undefined)"].join('')),
    ((true === (false === (typeof(null) === "undefined"))) ?
      ["Passed - ","(false? (undefined? null))"].join('') :
      ["Failed - ","(false? (undefined? null))"].join('')),
    ((true === (Object.prototype.toString.call(null) === "[object Null]")) ?
      ["Passed - ","(null? null)"].join('') :
      ["Failed - ","(null? null)"].join('')),
    ((true === (false === (Object.prototype.toString.call(undefined) === "[object Null]"))) ?
      ["Passed - ","(false? (null? undefined))"].join('') :
      ["Failed - ","(false? (null? undefined))"].join('')),
    ((true === (0 === 0)) ?
      ["Passed - ","(zero? 0)"].join('') :
      ["Failed - ","(zero? 0)"].join('')),
    ((true === (false === (0 === ''))) ?
      ["Passed - ","(false? (zero? ''))"].join('') :
      ["Failed - ","(false? (zero? ''))"].join('')),
    ((true === (Object.prototype.toString.call(true) === "[object Boolean]")) ?
      ["Passed - ","(boolean? true)"].join('') :
      ["Failed - ","(boolean? true)"].join('')),
    ((true === (false === (Object.prototype.toString.call(0) === "[object Boolean]"))) ?
      ["Passed - ","(false? (boolean? 0))"].join('') :
      ["Failed - ","(false? (boolean? 0))"].join('')),
    ((true === (Object.prototype.toString.call(1) === "[object Number]")) ?
      ["Passed - ","(number? 1)"].join('') :
      ["Failed - ","(number? 1)"].join('')),
    ((true === (false === (Object.prototype.toString.call('') === "[object Number]"))) ?
      ["Passed - ","(false? (number? ''))"].join('') :
      ["Failed - ","(false? (number? ''))"].join('')),
    ((true === (Object.prototype.toString.call('') === "[object String]")) ?
      ["Passed - ","(string? '')"].join('') :
      ["Failed - ","(string? '')"].join('')),
    ((true === (Object.prototype.toString.call([]) === "[object Array]")) ?
      ["Passed - ","(array? []])"].join('') :
      ["Failed - ","(array? []])"].join('')),
    ((true === (false === (Object.prototype.toString.call({}) === "[object Array]"))) ?
      ["Passed - ","(false? (array? {}))"].join('') :
      ["Failed - ","(false? (array? {}))"].join('')),
    ((true === (Object.prototype.toString.call({}) === "[object Object]")) ?
      ["Passed - ","(object? {})"].join('') :
      ["Failed - ","(object? {})"].join('')),
    ((true === (false === (Object.prototype.toString.call([]) === "[object Object]"))) ?
      ["Passed - ","(object? [])"].join('') :
      ["Failed - ","(object? [])"].join('')),
    ((true === (false === (Object.prototype.toString.call(null) === "[object Object]"))) ?
      ["Passed - ","(false? (object? null))"].join('') :
      ["Failed - ","(false? (object? null))"].join('')),
    ((true === (6 === (1 + 2 + 3))) ?
      ["Passed - ","variadic arithmetic operator"].join('') :
      ["Failed - ","variadic arithmetic operator"].join('')),
    ((true === (true === (3 > 2 && 2 > 1))) ?
      ["Passed - ","variadic >"].join('') :
      ["Failed - ","variadic >"].join('')),
    ((true === (true === (1 === 1 && 1 === 1))) ?
      ["Passed - ","variadic ="].join('') :
      ["Failed - ","variadic ="].join('')),
    ((true === (false === (1 !== 1 && 1 !== 2))) ?
      ["Passed - ","variadic !="].join('') :
      ["Failed - ","variadic !="].join('')),
    ((true === (true === (true && true && true))) ?
      ["Passed - ","variadic logical operator"].join('') :
      ["Failed - ","variadic logical operator"].join('')),
    ((true === (10 === (true ?
                (function() {
        let ret = 10;
        return ret;
        })() :
        undefined))) ?
      ["Passed - ","when test"].join('') :
      ["Failed - ","when test"].join('')),
    ((true === (10 === ((!false) ?
                (function() {
        let ret = 10;
        return ret;
        })() :
        undefined))) ?
      ["Passed - ","unless test"].join('') :
      ["Failed - ","unless test"].join('')),
    ((true === (-10 ===       (function() {
      let i = -1;
      return ((i < 0) ?
        -10 :
        ((0 === i) ?
          0 :
          ((i > 0) ?
            10 :
            undefined)));
      })())) ?
      ["Passed - ","condition test less than"].join('') :
      ["Failed - ","condition test less than"].join('')),
    ((true === (10 ===       (function() {
      let i = 1;
      return ((i < 0) ?
        -10 :
        ((0 === i) ?
          0 :
          ((i > 0) ?
            10 :
            undefined)));
      })())) ?
      ["Passed - ","condition test greater than"].join('') :
      ["Failed - ","condition test greater than"].join('')),
    ((true === (0 ===       (function() {
      let i = 0;
      return ((i < 0) ?
        -10 :
        ((0 === i) ?
          0 :
          ((i > 0) ?
            10 :
            undefined)));
      })())) ?
      ["Passed - ","condition test equal to"].join('') :
      ["Failed - ","condition test equal to"].join('')),
    ((true === (10 ===       (function() {
      let i = Infinity;
      return ((i < 0) ?
        -10 :
        ((0 === i) ?
          0 :
          (true ?
            10 :
            undefined)));
      })())) ?
      ["Passed - ","condition test default"].join('') :
      ["Failed - ","condition test default"].join('')),
    ((true === (10 === (function () {
        let recur = null,
          ___xs = null,
          ___f = function (i) {
            return ((i === 10) ?
              i :
              recur(++i));
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
        return recur(1);
      })())) ?
      ["Passed - ","loop recur test"].join('') :
      ["Failed - ","loop recur test"].join('')),
    ((true === (10 ===       (function() {
      let ret = 0;
      [
        1,
        2,
        3,
        4
      ].forEach(function (val) {
        return ret = (ret + val);
      });
      return ret;
      })())) ?
      ["Passed - ","each test"].join('') :
      ["Failed - ","each test"].join('')),
    ((true === (10 ===       (function() {
      let ret = 0;
      (function (o,f,s) {
        let _k = Object.keys(o);
        return _k.forEach(function (elem) {
          return f.call(s,o[elem],elem,o);
        });
      })({
        a: 1,
        b: 2,
        c: 3,
        d: 4
      },function (val) {
        return ret = (ret + val);
      });
      return ret;
      })())) ?
      ["Passed - ","eachKey test"].join('') :
      ["Failed - ","eachKey test"].join('')),
    ((true === (10 === [
        1,
        2,
        3,
        4
      ].reduce(function (accum,val) {
        return (accum + val);
      },0))) ?
      ["Passed - ","reduce test with init"].join('') :
      ["Failed - ","reduce test with init"].join('')),
    ((true === (10 === [
        1,
        2,
        3,
        4
      ].reduce(function (accum,val) {
        return (accum + val);
      }))) ?
      ["Passed - ","reduce test without init"].join('') :
      ["Failed - ","reduce test without init"].join('')),
    ((true === (20 === [
        1,
        2,
        3,
        4
      ].map(function (val) {
        return (val * 2);
      }).reduce(function (accum,val) {
        return (accum + val);
      },0))) ?
      ["Passed - ","map test"].join('') :
      ["Failed - ","map test"].join('')),
    ((true === ("112233" === testTemplate(1,2,3))) ?
      ["Passed - ","template test"].join('') :
      ["Failed - ","template test"].join('')),
    ((true === ("112233" ===       (function() {
      let ___ret = "";
      (function (o,f,s) {
        let _k = Object.keys(o);
        return _k.forEach(function (elem) {
          return f.call(s,o[elem],elem,o);
        });
      })({
        "1": 1,
        "2": 2,
        "3": 3
      },function (value,key) {
        return ___ret = (___ret + [key,value].join(''));
      });
      return ___ret;
      })())) ?
      ["Passed - ","template repeat key test"].join('') :
      ["Failed - ","template repeat key test"].join('')),
    ((true === (10 === (function() {
      try {
        let i = 10;
        return i;

      } catch (err) {
return       (function() {
      return err;
      })();
      }
      })())) ?
      ["Passed - ","try catch test - try block"].join('') :
      ["Failed - ","try catch test - try block"].join('')),
    ((true === (10 === (function() {
      try {
        throw 10;;

      } catch (err) {
return       (function() {
      return err;
      })();
      }
      })())) ?
      ["Passed - ","try catch test - catch block"].join('') :
      ["Failed - ","try catch test - catch block"].join('')),
    ((true === (3 === (function (___m) {
        let ___u = function (v) {
          return (((typeof(v) === "undefined") && (!(typeof(___m.zero) === "undefined"))) ?
            ___m.zero :
            ___m.unit(v));
        };
        return ___m.bind(1,function (a) {
          return ___m.bind((a * 2),function (b) {
            return (function () {
              return ___u((a + b));
            })();
          });
        });
      })({
        bind: function (mv,mf) {
          return mf(mv);
        },
        unit: function (v) {
          return v;
        }
      }))) ?
      ["Passed - ","Identity Monad Test"].join('') :
      ["Failed - ","Identity Monad Test"].join('')),
    ((true === (3 === (function (___m) {
        let ___u = function (v) {
          return (((typeof(v) === "undefined") && (!(typeof(___m.zero) === "undefined"))) ?
            ___m.zero :
            ___m.unit(v));
        };
        return ___m.bind(1,function (a) {
          return ___m.bind((a * 2),function (b) {
            return (function () {
              return ___u((a + b));
            })();
          });
        });
      })({
        bind: function (mv,mf) {
          return ((Object.prototype.toString.call(mv) === "[object Null]") ?
            null :
            mf(mv));
        },
        unit: function (v) {
          return v;
        },
        zero: null
      }))) ?
      ["Passed - ","maybe Monad Test"].join('') :
      ["Failed - ","maybe Monad Test"].join('')),
    ((true === (null === (function (___m) {
        let ___u = function (v) {
          return (((typeof(v) === "undefined") && (!(typeof(___m.zero) === "undefined"))) ?
            ___m.zero :
            ___m.unit(v));
        };
        return ___m.bind(null,function (a) {
          return ___m.bind((a * 2),function (b) {
            return (function () {
              return ___u((a + b));
            })();
          });
        });
      })({
        bind: function (mv,mf) {
          return ((Object.prototype.toString.call(mv) === "[object Null]") ?
            null :
            mf(mv));
        },
        unit: function (v) {
          return v;
        },
        zero: null
      }))) ?
      ["Passed - ","maybe Monad null Test"].join('') :
      ["Failed - ","maybe Monad null Test"].join('')),
    ((true === (54 === (function (___m) {
        let ___u = function (v) {
          return (((typeof(v) === "undefined") && (!(typeof(___m.zero) === "undefined"))) ?
            ___m.zero :
            ___m.unit(v));
        };
        return ___m.bind([
          1,
          2,
          3
        ],function (a) {
          return ___m.bind([
            3,
            4,
            5
          ],function (b) {
            return (function () {
              return ___u((a + b));
            })();
          });
        });
      })({
        bind: function (mv,mf) {
          return mv.map(mf).reduce(function (accum,val) {
            return accum.concat(val);
          },[]);
        },
        unit: function (v) {
          return [
            v
          ];
        },
        zero: [],
        plus: function () {
          return Array.prototype.slice.call(arguments).reduce(function (accum,val) {
            return accum.concat(val);
          },[]);
        }
      }).reduce(function (accum,val) {
        return (accum + val);
      },0))) ?
      ["Passed - ","arrayMonad test"].join('') :
      ["Failed - ","arrayMonad test"].join('')),
    ((true === (32 === (function (___m) {
        let ___u = function (v) {
          return (((typeof(v) === "undefined") && (!(typeof(___m.zero) === "undefined"))) ?
            ___m.zero :
            ___m.unit(v));
        };
        return ___m.bind([
          1,
          2,
          3
        ],function (a) {
          return ___m.bind([
            3,
            4,
            5
          ],function (b) {
            return (function () {
              return ___u((((a + b) <= 6) ?
                                (function() {
                return (a + b);
                })() :
                undefined));
            })();
          });
        });
      })({
        bind: function (mv,mf) {
          return mv.map(mf).reduce(function (accum,val) {
            return accum.concat(val);
          },[]);
        },
        unit: function (v) {
          return [
            v
          ];
        },
        zero: [],
        plus: function () {
          return Array.prototype.slice.call(arguments).reduce(function (accum,val) {
            return accum.concat(val);
          },[]);
        }
      }).reduce(function (accum,val) {
        return (accum + val);
      },0))) ?
      ["Passed - ","arrayMonad when test"].join('') :
      ["Failed - ","arrayMonad when test"].join('')),
    ((true === (6 === (function (___m) {
        let ___u = function (v) {
          return (((typeof(v) === "undefined") && (!(typeof(___m.zero) === "undefined"))) ?
            ___m.zero :
            ___m.unit(v));
        };
        return ___m.bind([
          1,
          2,
          0,
          null,
          3
        ],function (a) {
          return (function () {
            return ___u((a ?
                            (function() {
              return a;
              })() :
              undefined));
          })();
        });
      })({
        bind: function (mv,mf) {
          return mv.map(mf).reduce(function (accum,val) {
            return accum.concat(val);
          },[]);
        },
        unit: function (v) {
          return [
            v
          ];
        },
        zero: [],
        plus: function () {
          return Array.prototype.slice.call(arguments).reduce(function (accum,val) {
            return accum.concat(val);
          },[]);
        }
      }).reduce(function (accum,val) {
        return (accum + val);
      },0))) ?
      ["Passed - ","arrayMonad when null values test"].join('') :
      ["Failed - ","arrayMonad when null values test"].join('')),
    ((true === (13 === namedFn(7,6))) ?
      ["Passed - ","named function test"].join('') :
      ["Failed - ","named function test"].join('')),
    ((true === (7 === namedFnNoSpaceBeforeArgs(13,6))) ?
      ["Passed - ","named function no space test"].join('') :
      ["Failed - ","named function no space test"].join(''))
  ];
};
function browserTest() {
  let el = document.getElementById("testresult");
  return (el.outerHTML ?
    el.outerHTML = ["<pre>",(function (groupname,desc) {
      let start = new Date(),
        tests = groupname(),
        passed = 0,
        failed = 0;
      tests.forEach(function (elem) {
        return (elem.match(/^Passed/) ?
          ++passed :
          ++failed);
      });
      return [["\n",desc,"\n",start,"\n\n"].join(''),tests.reduce(function (___memo,elem,index) {
        return (___memo + [elem,"\n"].join(''));
      },""),"\nTotal tests ",tests.length,"\nPassed ",passed,"\nFailed ",failed,"\nDuration ",(new Date() - start),"ms\n"].join('');
    })(lispyscript,"LispyScript Testing"),"</pre>"].join('') :
    el.innerHTML = (function (groupname,desc) {
      let start = new Date(),
        tests = groupname(),
        passed = 0,
        failed = 0;
      tests.forEach(function (elem) {
        return (elem.match(/^Passed/) ?
          ++passed :
          ++failed);
      });
      return [["\n",desc,"\n",start,"\n\n"].join(''),tests.reduce(function (___memo,elem,index) {
        return (___memo + [elem,"\n"].join(''));
      },""),"\nTotal tests ",tests.length,"\nPassed ",passed,"\nFailed ",failed,"\nDuration ",(new Date() - start),"ms\n"].join('');
    })(lispyscript,"LispyScript Testing"));
}
((typeof(window) === "undefined") ?
  console.log((function (groupname,desc) {
    let start = new Date(),
      tests = groupname(),
      passed = 0,
      failed = 0;
    tests.forEach(function (elem) {
      return (elem.match(/^Passed/) ?
        ++passed :
        ++failed);
    });
    return [["\n",desc,"\n",start,"\n\n"].join(''),tests.reduce(function (___memo,elem,index) {
      return (___memo + [elem,"\n"].join(''));
    },""),"\nTotal tests ",tests.length,"\nPassed ",passed,"\nFailed ",failed,"\nDuration ",(new Date() - start),"ms\n"].join('');
  })(lispyscript,"LispyScript Testing")) :
  window.onload = browserTest);
