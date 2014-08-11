"use strict"
CodeMirror.defineMode "turtle", (config) ->
  wordRegexp = (words) ->
    new RegExp("^(?:" + words.join("|") + ")$", "i")
  escapeAcceptingEatWhile = (stream, regex) ->
    stream.eatWhile(regex)
    loop
      if stream.peek! is '\\'
        stream.next!
        stream.next!
        stream.eatWhile(regex)
      else break
  tokenBase = (stream, state) ->
    if (state.curPos == "MLL")
        stream.eatWhile(/[^"]/)
        if (stream.match(/"""/))
          state.curPos = "EOS"
        return "string-2"
    ch = stream.next!
    error = false
    curPunc = null
    lastWasColon = state.lastWasColon
    state.lastWasColon = false
    if (!lastWasColon && (ch == '.' and stream.match(/\d/) || ((ch > "0" and ch < "9") || ch == "-" || ch == "+") and stream.match(/[\d.+-eE]*\W/)))
      stream.eatWhile /[\d]/
      if state.curPos is "object"
        state.curPos = "EOS"  if state.inLists is 0
      else
        error = true
      return (if error then "number error" else "number")
    if ch is "<" and not stream.match(/^[\s\u00a0=]/, false)
      stream.match /^[^\s\u00a0>]*>?/
      if state.curPos is "subject"
        state.curPos = "property"
      else if state.curPos is "property"
        state.curPos = "object"
      else if state.curPos is "object"
        state.curPos = "EOS"  if state.inLists is 0
      else
        error = true
      (if error then "atom error" else "atom")
    else if ch is "\"" or ch is "'"
      error = true  unless state.curPos is "object"
      state.curPos = "EOS"  if state.inLists is 0
      if (ch=="\"") && stream.match(/""/)
        state.curPos = "MLL"
        stream.eatWhile(/[^"]/)
        "string-2"
      else 
        state.tokenize = tokenLiteral(ch)
        (if error then state.tokenize(stream, state) + " error" else state.tokenize(stream, state))
    else if /[{}\(\),\.;\[\]]/.test(ch)
      curPunc = ch
      if curPunc is ";"
        error = true  unless state.curPos is "EOS"
        state.curPos = "property"
      else if curPunc is "."
        state.curPos = "subject"
      else if curPunc is ","
        error = true  unless state.curPos is "EOS"
        state.curPos = "object"
      else if curPunc is "["
        error = true  unless state.curPos is "object"
        state.curPos = "property"
      else if curPunc is "]"
        state.curPos = "EOS"
      else if curPunc is "("
        state.inLists++
      else state.inLists--  if curPunc is ")"
      (if error then "punctuation error" else "punctuation")
    else if ch is "#"
      stream.skipToEnd!
      "comment"
    else if operatorChars.test(ch)
      stream.eatWhile operatorChars
      "operator"
    else if ch is ":"
      state.lastWasColon = true
      "operator"
    else
      if (lastWasColon) then escapeAcceptingEatWhile(stream,/[_\w\d:-]/)
      else stream.eatWhile /[_\w\d\\-]/
      if stream.peek! is ":"
        return "variable-3"
      else
        word = stream.current!
        if !lastWasColon && keywords.test(word)
          if word is "a"
            error = true  unless state.curPos is "property"
            state.curPos = "object"
          return (if error then "meta error" else "meta")
        return "variable-2"  if ch is "@"
        if ch is "^"
          if stream.peek! is "^"
            stream.next!
            stream.eatWhile /[_\w\d:]/
            return "qualifier"
        ret = undefined
        if state.curPos is "subject"
          ret = "variable-2"
        else if state.curPos is "property"
          ret = "keyword"
        else if state.curPos is "object"
          ret = "string"
        else
          ret = "error"
        if state.curPos is "subject"
          state.curPos = "property"
        else if state.curPos is "property"
          state.curPos = "object"
        else state.curPos = "EOS"  if state.curPos is "object" and state.inLists is 0
        return ret
      word = stream.current!
      if ops.test(word)
        null
      else if keywords.test(word)
        if word is "a"
          error = true  unless state.curPos is "property"
          state.curPos = "object"
        (if error then "meta error" else "meta")
      else
        "variable"
  tokenLiteral = (quote) ->
    (stream, state) ->
      escaped = false
      ch = undefined
      while (ch = stream.next!)?
        if ch is quote and not escaped
          state.tokenize = tokenBase
          break
        escaped = not escaped and ch is "\\"
      "string-2"
  pushContext = (state, type, col) ->
    state.context =
      prev: state.context
      indent: state.indent
      col: col
      type: type

    return
  popContext = (state) ->
    state.indent = state.context.indent
    state.context = state.context.prev
    return
  indentUnit = config.indentUnit
  curPunc = undefined
  ops = wordRegexp([])
  keywords = wordRegexp([
    "@prefix"
    "@base"
    "a"
  ])
  operatorChars = /[*+\-<>=&|]/
  startState: ->
    tokenize: tokenBase
    context: null
    curPos: "subject"
    lastWasColon : false
    inLists: 0
    indent: 0
    col: 0

  token: (stream, state) ->
    if stream.sol!
      state.context.align = false  if state.context and not state.context.align?
      state.indent = stream.indentation!
    if stream.eatSpace!
      if (state.lastWasColon)
        state.lastWasColon = false
        if state.curPos is "subject"
          state.curPos = "property"
        else if state.curPos is "property"
          state.curPos = "object"
        else state.curPos = "EOS"  if state.curPos is "object" and state.inLists is 0
      return null
    style = state.tokenize(stream, state)
    state.context.align = true  if style isnt "string" and state.context and not state.context.align? and state.context.type isnt "pattern"
    if curPunc is "("
      pushContext state, ")", stream.column!
    else if curPunc is "["
      pushContext state, "]", stream.column!
    else if curPunc is "{"
      pushContext state, "}", stream.column!
    else if /[\]\}\)]/.test(curPunc)
      while state.context and state.context.type is "pattern" then popContext state 
      popContext state if state.context and curPunc is state.context.type
    else if curPunc is "." and state.context and state.context.type is "pattern"
      popContext state
    else if /atom|string|variable/.test(style) and state.context
      if /[\}\]]/.test(state.context.type)
        pushContext state, "pattern", stream.column!
      else if state.context.type is "pattern" and not state.context.align
        state.context.align = true
        state.context.col = stream.column!
    style
  fold: "indent"
  indent: (state, textAfter) ->
    firstChar = textAfter and textAfter.charAt(0)
    context = state.context
    while context and context.type is "pattern" then if /[\]\}]/.test(firstChar) then context = context.prev 
    closing = context and firstChar is context.type
    unless context
      return (if state.indent isnt 0 then state.indent else indentUnit)  if curPunc is ";"
      0
    else if context.type is "pattern"
      context.col
    else if context.align
      context.col + ((if closing then 0 else 1))
    else
      context.indent + ((if closing then 0 else indentUnit))

CodeMirror.defineMIME "text/turtle", "turtle"