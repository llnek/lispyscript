/**
 * Copyright (c) 2013-2017, Kenneth Leung. All rights reserved.
 * The use and distribution terms for this software are covered by the
 * Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php)
 * which can be found in the file epl-v10.html at the root of this distribution.
 * By using this software in any fashion, you are agreeing to be bound by
 * the terms of this license.
 * You must not remove this notice, or any other, from this software.
 */

//////////////////////////////////////////////////////////////////////////////
//
function addToken(tree,token,state) {
  if (token) {
    if (":else" == token) { token="true"; }
    if ("nil" == token) { token="null";}
    if (token.startsWith(":") &&
        REGEX.id.test(token.substring(1))) {
      token="\"" + token.substring(1) + "\"";
    }
    tree.push(state.createToken(token));
    //tree.push(tnode(state.lineno, state.tknCol - 1, state.file, token, token));
  }
  return "";
}

//////////////////////////////////////////////////////////////////////////////
//
function lexer (codeSrc, state, prevToken) {
  let clen= codeSrc.length,
      comment = false,
      escStr= false,
      inStr = false,
      strType="",
      token = "",
      tree = [],
      ch,
      jsParen=0,
      jsArray=0,
      jsObject=0;

  tree._filename = state.filename;
  tree._line = state.lineno;

  if (prevToken) {
    addToken(tree,prevToken);
  }

  while (state.pos < clen) {
    ch = codeSrc.charAt(state.pos);
    ++state.colno;
    ++state.pos;

    if (ch === "\n") {
      comment= comment ? false : comment;
      ++state.lineno;
      state.colno = 1;
    }
    if (comment) { continue; }
    if (escStr) {
      escStr= false;
      token += ch;
      continue;
    }
    if (ch === "\"" || ch === "'") {
      if (! inStr) { strType= ch; inStr=true; } else {
        if (strType === ch) { inStr=false; }
      }
      token += ch;
      continue;
    }
    if (inStr) {
      if (ch === "\n") { ch= "\\n"; }
      else {
        if (ch === "\\") { escStr= true; }
      }
      token += ch;
      continue;
    }
    if (ch === "[") {
      token=addToken(tree,token);
      state.tknCol= state.colno;
      ++jsArray;
      ++jsParen;
      tree.push(lexer(codeSrc, state, ch));
      continue;
    }
    if (ch === "]") {
      token=addToken(tree,token);
      addToken(tree,ch);
      --jsArray;
      --jsParen;
      state.tknCol= state.colno;
      break;
    }
    if (ch === "{") {
      token=addToken(tree,token);
      state.tknCol= state.colno;
      ++jsObject;
      ++jsParen;
      tree.push(lexer(codeSrc, state, ch));
      continue;
    }
    if (ch === "}") {
      token=addToken(tree,token);
      addToken(tree,ch);
      --jsObject;
      --jsParen;
      state.tknCol= state.colno;
      break;
    }
    if (ch === ";") { comment = true; continue; }
    if (ch === "(") {
      token=addToken(tree,token);
      state.tknCol= state.colno;
      ++jsParen;
      tree.push(lexer(codeSrc, state));
      continue;
    }
    if (ch === ")") {
      token=addToken(tree,token);
      state.tknCol = state.colno;
      --jsParen;
      break;
    }
    if (REGEX.wspace.test(ch)) {
      if (ch === "\n") { --state.lineno; }
      token=addToken(tree,token);
      if (ch === "\n") { ++state.lineno; }
      state.tknCol= state.colno;
      continue;
    }
    token += ch;
  }
  if (inStr) { synError("e3", tree);}
  if (jsArray !== 0) { synError("e5", tree); }
  if (jsObject !== 0) { synError("e7", tree); }
  if (jsParen !== 0) { synError("e8", tree); }
  return tree;
}

//////////////////////////////////////////////////////////////////////////////
//
function toAST(code, state) {
  let codeStr = "(" + code + ")",
      ret = lexer(codeStr, state);
  return (state.pos < codeStr.length) ? handleError("e10") : ret;
}

//////////////////////////////////////////////////////////////////////////////
//EOF


