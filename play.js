// Generated by LispyScript v1.5.0
(function () {
  let ___ret = !undefined,
    ___xs = null,
    recur = null,
    ___f = function (a,times) {
      return ((times > a) ?
        (function () {
          (4 + 5);
          console.log(["a=",a].join(''));
          return recur((a + 1),times);
        })() :
        undefined);
    };
  recur = function () {
    ___xs = arguments;
    return ((typeof(___ret) !== "undefined") ?
      (function () {
        ___ret = undefined;
        while (___ret===undefined) ___ret=___f.apply(this,___xs);
        return ___ret;
      })() :
      undefined);
  };
  return recur(0,(3 * 4));
})();
