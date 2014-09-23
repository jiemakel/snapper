angular.module('app').controller('MainCtrl', ($scope, $http, toastr, $stateParams, $localStorage, prefixService, $q, sparql) ->
  $scope.config = {}
  # input initialization
  for param, value of $stateParams
    $scope[param]=value
  for param, value of $localStorage when !$stateParams[param]?
    $scope[param]=value
  $scope.sparqlEndpointInput=$scope.sparqlEndpoint
  $scope.restEndpointInput=$scope.restEndpoint
  $scope.graphIRIInput = if ($scope.graphIRI!=null) then $scope.graphIRI else 'default'

  #input watches
  $scope.$watch('config', (newValue,oldValue) ->
    if (newValue!=oldValue)
      $localStorage.confing=newValue
  )
  $scope.$watch('graphIRIInput', (newValue,oldValue) ->
    $scope.graphIRI = if (newValue!='default') then newValue else null
  )
  $scope.$watch('graphIRI', (newValue,oldValue) ->
    if (newValue!=oldValue)
      $localStorage.graphIRI=newValue
  )
  $scope.sparqlEndpointInputValid = true
  sparqlEndpointInputCheckCanceler = null
  $scope.$watch('sparqlEndpointInput', (newValue,oldValue) ->
    if (newValue?)
      if sparqlEndpointInputCheckCanceler? then sparqlEndpointInputCheckCanceler.resolve!
      sparqlEndpointInputCheckCanceler = $q.defer!
      sparql.check(newValue,{timeout: sparqlEndpointInputCheckCanceler.promise}).then((isValid) ->
        $scope.sparqlEndpointInputValid=isValid
      ,-> $scope.sparqlEndpointInputValid=false)
  )
  $scope.sparulEndpointInputValid = true
  sparulEndpointInputCheckCanceler = null
  $scope.$watch('sparulEndpointInput', (newValue,oldValue) ->
    if (newValue?)
      if sparulEndpointInputCheckCanceler? then sparulEndpointInputCheckCanceler.resolve!
      sparulEndpointInputCheckCanceler = $q.defer!
      sparql.checkUpdate(newValue,{timeout: sparulEndpointInputCheckCanceler.promise}).then((isValid) ->
        $scope.sparulEndpointInputValid=isValid
      ,-> $scope.sparulEndpointInputValid=false)
  )
  $scope.restEndpointInputValid = true
  restEndpointInputCheckCanceler = null
  $scope.$watch('restEndpointInput', (newValue,oldValue) ->
    if (newValue?)
      if restEndpointInputCheckCanceler? then restEndpointInputCheckCanceler.resolve!
      restEndpointInputCheckCanceler = $q.defer!
      sparql.checkRest(newValue,{timeout: restEndpointInputCheckCanceler.promise}).then((isValid) ->
        $scope.restEndpointInputValid=isValid
      ,-> $scope.restEndpointInputValid=false)
  )
  $scope.$watch('sparqlEndpoint', (newValue,oldValue) ->
    $scope.sparqlEndpointInput=newValue
    if (newValue!=oldValue)
      $localStorage.sparqlEndpoint=newValue
      if (!$scope.restEndpoint || $scope.restEndpoint == "")
        $scope.restEndpoint = newValue
      if (!$scope.sparulEndpoint || $scope.sparulEndpoint == "")
        $scope.sparulEndpoint = newValue
    if (newValue?) then updateGraphs!
  )
  $scope.$watch('restEndpoint', (newValue,oldValue) ->
    $scope.restEndpointInput=newValue
    if (newValue!=oldValue)
      $localStorage.restEndpoint=newValue
      if (!$scope.sparqlEndpoint || $scope.sparqlEndpoint == "")
        $scope.sparqlEndpoint = newValue
      if (!$scope.sparulEndpoint || $scope.sparulEndpoint == "")
        $scope.sparulEndpoint = newValue
  )
  $scope.$watch('sparulEndpoint', (newValue,oldValue) ->
    $scope.sparulEndpointInput=newValue
    if (newValue!=oldValue)
      $localStorage.sparulEndpoint=newValue
      if (!$scope.restEndpoint || $scope.restEndpoint == "")
        $scope.restEndpoint = newValue
      if (!$scope.sparqlEndpoint || $scope.sparqlEndpoint == "")
        $scope.sparqlEndpoint = newValue
  )
  $scope.$watch('data', (newValue,oldValue) ->
    if (newValue!=oldValue)
      $localStorage.data=newValue
      appendPrefixIfNeeded(cm)
  )
  # utility functions
  !function handleError(response)
    $scope.errorSource = response.config.url
    $scope.errorStatus = response.status + ( if (response.statusText) then " ("+response.statusText+")" else "")
    $scope.errorRequest = response.config.data ? response.config.params?.query
    $scope.errorMessage = response.data
    $scope.showError = true
  canceler = null
  $scope.$watch('graphIRI', (newValue,oldValue) ->
    if (!allGraphsFetched) then updateGraphs!
  )
  graphQuery = '''
    SELECT ?graphIRI ?triples {
      {
        SELECT ?graphIRI (COUNT(*) AS ?triples) {
          {
            {
              SELECT DISTINCT ?graphIRI {
                {
                  graph ?graphIRI {}
                  FILTER STRSTARTS(STR(?graphIRI), "<QUERY>")
                }
                UNION
                {
                  graph ?graphIRI {}
                }
              }
              LIMIT 500
            }
            GRAPH ?graphIRI { ?s ?p ?o }
          }
        }
        GROUP BY ?graphIRI
      }
      UNION
      {
        SELECT (COUNT(*) AS ?triples) {
          ?s ?p ?o
        }
      }
    }
    ORDER BY ?graphIRI'''
  allGraphsFetched = true
  !function updateGraphs
    if (canceler?) then canceler.resolve!
    canceler := $q.defer!
    response <-! sparql.query($scope.sparqlEndpoint,graphQuery.replace("<QUERY>",$scope.graphIRI ? ""),{timeout: canceler.promise}).then(_)
    $scope.graphs = response.data.results.bindings
    if ($scope.graphs.length<500) then allGraphsFetched := true else allGraphsFetched := false
  function getLineAfterPrefixes(data)
    pos = 0
    i = 0
    while pos!=-1 && (data.charAt(pos)=='@' && data.charAt(pos+1)=='p' && data.charAt(pos+2)=='r' && data.charAt(pos+3)=='e' && data.charAt(pos+4)=='f' && data.charAt(pos+5)=='i' && data.charAt(pos+6)=='x')
      i++
      pos=data.indexOf('\n',pos)
    i
  !function appendPrefix(cm,prefix,ns)
    cm.replaceRange("@prefix #{prefix}: <#{ns}> .\n", {line:getLineAfterPrefixes($scope.data),ch:0})
  baseRegex = new RegExp("^\\s*@base\\s+<(.+)>","i");
  prefixRegex = new RegExp("^\\s*@prefix\\s+([^:]+):\\s*<(.+)>","i");
  function getPrefixLinesFromData(data)
    prefixes = ""
    lines = data.split("\n")
    for line in lines when line.match(prefixRegex)?
      prefixes+=line+"\n"
    prefixes
  function getPrefixesFromData(data)
    queryPrefixes = {}
    lines = data.split("\n")
    for line in lines
      matches = line.match(prefixRegex)
      if (matches?)
        queryPrefixes[matches[1]] = matches[2]
      matches = line.match(baseRegex)
      if (matches?)
        queryPrefixes["base"] = matches[1]
    queryPrefixes
  !function appendPrefixIfNeeded(cm)
    pos = cm.getCursor!
    if(cm.getTokenTypeAt(pos)=="operator")
      prefix = cm.getTokenAt({line: pos.line, ch:pos.ch-1})
      if (prefix.type=="variable-3")
        currentPrefixes = getPrefixesFromData($scope.data)
        if (!currentPrefixes[prefix.string]?)
          ns = prefixService.getNs(prefix.string,true)
          if (ns?) then appendPrefix(cm,prefix.string,ns)
  !function applyAutocompletion(cm,data,completion)
    sf = prefixService.shortForm(completion.text,false,true)
    knownPrefixes = getPrefixesFromData($scope.data)
    cm.replaceRange(sf.shortForm, data.from, data.to, "complete")
    if (!knownPrefixes[sf.prefix]?)
      appendPrefix(cm,sf.prefix,sf.ns)
  function getNodeFromPosition(cm,cur)
    token = cm.getTokenAt(cur)
    switch token.type
      when "string", "keyword", "variable-2"
        prefix = cm.getTokenAt({line:cur.line,ch:token.start-2})
        node="<"+prefixService.expand(prefix.string+":"+token.string)+">"
        start=prefix.start
      when "string-2"
        node=token.string
      when "atom"
        node=token.string
        start=token.start
    {cur:{line:cur.line,ch:start},token:token,node:node}
  function getIRIFromPosition(cm,cur)
    ret = getNodeFromPosition(cm,cur)
    if (ret.token.type == "string-2") then null else ret
  function getIRIUnderCursor(cm)
    getIRIFromPosition(cm,cm.getCursor!)
  function getPreviousNode(cm,pos)
    if (pos.ch==-1)
      if (pos.line==0) then return
      pos.line--
      pos.ch=cm.getLine(pos.line).length
    token = cm.getTokenAt(pos)
    while (token.type!="string" && token.type!="keyword" && token.type!="variable-2" && token.type!="string-2")
      pos.ch = token.start - 1
      if (pos.ch==-1)
        if (pos.line==0) then return
        pos.line--
        pos.ch=cm.getLine(pos.line).length
      token = cm.getTokenAt(pos)
      if (token.type=='punctuation') then return
    { token: token, pos : pos }
  function getNextNode(cm,pos)
    token = cm.getTokenAt(pos)
    if (token.end==pos.ch-1)
      pos.ch=0
      pos.line++
      if (pos.line>cm.lastLine!) then return
      token = cm.getTokenAt(pos)
    while (token.type!="string" && token.type!="keyword" && token.type!="variable-2" && token.type!="string-2")
      pos.ch = token.end + 1
      token = cm.getTokenAt(pos)
      if (token.type=='punctuation') then return
      if (token.end==pos.ch-1)
        pos.ch=0
        pos.line++
        if (pos.line>cm.lastLine!) then return
        token = cm.getTokenAt(pos)
    { token: token, pos : pos }
  !function autocompleteHint(cm, callback, options)
    cur = cm.getCursor!
    token = cm.getTokenAt(cur)
    if (token.type=="string" || token.type=="keyword" || token.type=="variable-2")
      if (cm.getTokenAt({ line : cur.line, ch: token.start }).string==":")
        prefix = cm.getTokenAt({ line : cur.line, ch: token.start-2 })
    else if (token.type=="variable-3")
      prefix = token
      token = cm.getTokenAt({ line : cur.line, ch: prefix.end+2 })
    if (prefix?) # prefixed, first do lov search, then IRI substring search
      end = token.end
      type = if (token.type=="keyword") then "property" else "class"
      response <-! $http.get("http://lov.okfn.org/dataset/lov/api/v2/autocomplete/terms",
        params:
          q: prefix.string+":"+token.string
          type: type
      ).then(_,handleError)
      if (response.data.total_results==0)
        subject = property = object = subjectClasses = null
        prefixService.setPrefixNsMap(getPrefixesFromData($scope.data))
        qiri = prefixService.expand(prefix.string+":"+token.string)
        switch token.type
          when "variable-2"
            query = subjectIRIQuery.getValue!
            tmp = getNextNode(cm,{line:cur.line, ch:token.end + 1})
            if (tmp?)
              property = getIRIFromPosition(cm,tmp.pos).node
              tmp = getNextNode(cm,{line:tmp.pos.line, ch:tmp.token.end + 1})
              if (tmp?)
                object = getNodeFromPosition(cm,tmp.pos).node
          when "keyword"
            query = propertyIRIQuery.getValue!
            tmp = getPreviousNode(cm,{line:cur.line, ch:token.start - 1})
            if (tmp?)
              subject = getIRIFromPosition(cm,tmp.pos).node
            tmp = getNextNode(cm,{line:cur.line, ch:token.end + 1})
            if (tmp?)
              object = getNodeFromPosition(cm,tmp.pos).node
          when "string"
            query = objectIRIQuery.getValue!
            tmp = getPreviousNode(cm,{line:cur.line,ch:token.start - 1})
            if (tmp?)
              property = getNodeFromPosition(cm,tmp.pos).node
          else
            query = null
        if (query?)
          parts = query.split(/#\/?SUBJECTLIMIT/)
          if (parts.length==3)
            if (!subject) then query=parts[0]+parts[2]
            else query = parts[0]+parts[1].replace("<SUBJECT>",subject)+parts[2]
          parts = query.split(/#\/?SUBJECTCLASSLIMIT/)
          if (parts.length==3)
            if (!subjectClasses) then query=parts[0]+parts[2]
            else query = parts[0]+parts[1].replace("<SUBJECTCLASSES>",subjectClasses.join(" "))+parts[2]
          parts = query.split(/#\/?PROPERTYLIMIT/)
          if (parts.length==3)
            if (!property) then query=parts[0]+parts[2]
            else query = parts[0]+parts[1].replace("<PROPERTY>",property)+parts[2]
          parts = query.split(/#\/?OBJECTLIMIT/)
          if (parts.length==3)
            if (!object) then query=parts[0]+parts[2]
            else query = parts[0]+parts[1].replace("<OBJECT>",object)+parts[2]
          response <-! sparql.query($scope.sparqlEndpoint,replaceAll(query,"<QUERY>",qiri)).then(_,handleError)
          result = [{text:res.iri.value,displayText:prefixService.shortForm(res.iri.value,false,true).shortForm, hint:applyAutocompletion} for res in response.data.results.bindings]
          callback(
            list: result
            from: CodeMirror.Pos(cur.line, prefix.start)
            to: CodeMirror.Pos(cur.line, end)
          )
      else
        result = [res.prefixedName for res in response.data.results]
        callback(
          list: result
          from: CodeMirror.Pos(cur.line, prefix.start)
          to: CodeMirror.Pos(cur.line, end)
        )
    else # nonprefixed, do label search.
      # TODO: support atom IRI autocompletion, subject class restrictions
      subject = property = object = subjectClasses = null
      switch token.type
        when "variable-2"
          query = subjectLabelQuery.getValue!
          tmp = getNextNode(cm,{line:cur.line, ch:token.end + 1})
          if (tmp?)
            property = getIRIFromPosition(cm,tmp.pos).node
            tmp = getNextNode(cm,{line:tmp.pos.line, ch:tmp.token.end + 1})
            if (tmp?)
              object = getNodeFromPosition(cm,tmp.pos).node
        when "keyword"
          query = propertyLabelQuery.getValue!
          tmp = getPreviousNode(cm,{line:cur.line, ch:token.start - 1})
          if (tmp?)
            subject = getIRIFromPosition(cm,tmp.pos).node
          tmp = getNextNode(cm,{line:cur.line, ch:token.end + 1})
          if (tmp?)
            object = getNodeFromPosition(cm,tmp.pos).node
        when "string"
          query = objectLabelQuery.getValue!
          tmp = getPreviousNode(cm,{line:cur.line,ch:token.start - 1})
          if (tmp?)
            property = getNodeFromPosition(cm,tmp.pos).node
        else
          query = null
      if (query?)
        parts = query.split(/#\/?SUBJECTLIMIT/)
        if (parts.length==3)
          if (!subject) then query=parts[0]+parts[2]
          else query = parts[0]+parts[1].replace("<SUBJECT>",subject)+parts[2]
        parts = query.split(/#\/?SUBJECTCLASSLIMIT/)
        if (parts.length==3)
          if (!subjectClasses) then query=parts[0]+parts[2]
          else query = parts[0]+parts[1].replace("<SUBJECTCLASSES>",subjectClasses.join(" "))+parts[2]
        parts = query.split(/#\/?PROPERTYLIMIT/)
        if (parts.length==3)
          if (!property) then query=parts[0]+parts[2]
          else query = parts[0]+parts[1].replace("<PROPERTY>",property)+parts[2]
        parts = query.split(/#\/?OBJECTLIMIT/)
        if (parts.length==3)
          if (!object) then query=parts[0]+parts[2]
          else query = parts[0]+parts[1].replace("<OBJECT>",object)+parts[2]
        sparql.query($scope.sparqlEndpoint,replaceAll(query,"<QUERY>",token.string)).then((response) ->
          result = [{text:res.iri.value,displayText:res.label.value, hint:applyAutocompletion} for res in response.data.results.bindings]
          callback(
            list: result
            from: CodeMirror.Pos(cur.line, token.start)
            to: CodeMirror.Pos(cur.line, end)
          )
        ,handleError)
  autocompleteHint.async=true

  # CodeMirror initialization
  CodeMirror.registerHelper("wordChars","turtle", /[-\\w:<>\\#\\/\\.]/)
  cm = {}
  function cursorActivity(cm)
    d = getIRIUnderCursor(cm)
    if (d.node?)
      prefixService.setPrefixNsMap(getPrefixesFromData($scope.data))
      sparql.query($scope.sparqlEndpoint,replaceAll(labelQuery.getValue!,"<IRI>",d.node)).then((response) ->
        if (response.data.results.bindings.length>0)
          cm.markText({line: d.cur.line, ch:d.token.start},{line: d.cur.line, ch:d.token.end},{
            title:response.data.results.bindings[0].label.value
          })
      ,->)
  $scope.codemirrorLoaded = (editor) ->
    cm := editor
    cm.on("cursorActivity", cursorActivity)
  ctrl = if CodeMirror.keyMap["default"] == CodeMirror.keyMap.pcDefault then "Ctrl-" else "Cmd-"
  alt = if CodeMirror.keyMap["default"] == CodeMirror.keyMap.pcDefault then "Alt-" else "Option-"
  $scope.commands = []
  $scope.commands.push({key:"Ctrl-Space", command:"Autocomplete"})
  $scope.commands.push({key:ctrl+"F", command:"Find"})
  $scope.commands.push({key:ctrl+"G", command:"Find next"})
  $scope.commands.push({key:ctrl+"Shift-G", command:"Find previous"})
  $scope.commands.push({key:ctrl+(if alt=="Option-" then alt else "Shift")+"-F", command:"Replace"})
  $scope.commands.push({key:ctrl+(if alt=="Option-" then alt+"Shift-F" else "Shift-R"), command:"Replace all"})
  $scope.commands.push({key:ctrl+"J",command:"Toggle code folding"})
  $scope.commands.push({key:ctrl+"K",command:"Fold all"})
  $scope.commands.push({key:ctrl+"L",command:"Load IRI from endpoint"})
  $scope.commands.push({key:ctrl+alt+"L",command:"Load IRI direct"})
  $scope.commands.push({key:ctrl+"Enter",command:"Replace editor contents with IRI from endpoint"})
  $scope.commands.push({key:ctrl+alt+"Enter",command:"Replace editor contents with IRI direct"})
  $scope.commands.push({key:ctrl+"S",command:"Save current subject/selection to endpoint"})
  $scope.commands.push({key:ctrl+alt+"S",command:"Replace current subject/selection at endpoint"})
  $scope.commands.push({key:ctrl+alt+"Backspace",command:"Delete current subject/selection at endpoint"})
  $scope.commands.push({key:ctrl+alt+"O",command:"Toggle fullscreen mode"})
  extraKeys = {}
  extraKeys["Ctrl-Space"] = "autocomplete"
  extraKeys[ctrl+"J"] = (cm) -> cm.foldCode(cm.getCursor!)
  folded = false
  extraKeys[ctrl+"K"] = (cm) ->
    if (!folded) then CodeMirror.commands.foldAll(cm) else CodeMirror.commands.unfoldAll(cm)
    folded = !folded
  extraKeys[ctrl+"S"] = (cm) -> saveCurrentSubjects(cm)
  extraKeys[ctrl+"Alt-S"] = (cm) -> replaceCurrentSubjects(cm)
  extraKeys[ctrl+"Alt-Backspace"] = (cm) -> deleteCurrentSubjects(cm)
  extraKeys[ctrl+"L"] = (cm) -> loadResource(cm)
  extraKeys[ctrl+"Alt-L"] = (cm) -> loadResourceDirect(cm)
  extraKeys[ctrl+"Enter"] = (cm) -> loadResource(cm,true)
  extraKeys[ctrl+"Alt-Enter"] = (cm) -> loadResourceDirect(cm,true)
  extraKeys[ctrl+"Alt-O"] = (cm) -> cm.setOption("fullScreen",!cm.getOption("fullScreen"))
  extraKeys["ESC"] = (cm) -> if (cm.getOption("fullScreen")) then cm.setoption("fullScreen",false)
  $scope.editorOptions =
    lineWrapping : true
    lineNumbers: true
    matchBrackets: true
    autoCloseBrackets: true
    showTrailingSpace : true
    styleActiveLine : true
    syntaxErrorCheck : true
    hintOptions:
      hint: autocompleteHint
    highlightSelectionMatches: {showToken: /\w/}
    foldGutter : { rangeFinder: CodeMirror.fold.indent }
    gutters: [ 'CodeMirror-linenumbers', 'CodeMirror-foldgutter' ]
    extraKeys: extraKeys
  function processIRIs(data)
    matches = data.match(iriMatchRegex)
    newPrefixes = ""
    for iri in matches when !prefixService.getPrefix(iri.substring(1,iri.length-1))
      sf = prefixService.shortForm(iri,false,true)
      if (sf.newPrefix)
        newPrefixes += "@prefix #{sf.prefix}: <#{sf.ns}> .\n"
      data = replaceAll(data,iri,sf.shortForm)
    {newPrefixes:newPrefixes,data:data}
  function processWhitespace(data)
    data.replace(wsRegex1,"    ").replace(wsRegex2,"  ")
  function processResource(data)
    newPrefixes = ""
    lines = data.split("\n")
    ndata = ""
    prefixesToReplace = {}
    base = ""
    for line in lines
      matches = line.match(baseRegex)
      if (matches?)
        base = matches[1]
      else
        line = line.replace(relativeIRIMatchRegex,base+"\1")
        matches = line.match(prefixRegex)
        if (matches?)
          curprefix = prefixService.getPrefix(matches[2])
          if (!curprefix?)
            prefixService.setPrefixNs(matches[1],matches)
            newPrefixes += line+"\n"
          else if (curprefix!=matches[1])
            prefixesToReplace[matches[1]]=curprefix
        else
          ndata+=line+"\n"
    for prefix,curprefix of prefixesToReplace
      ndata = ndata.replace(new RegExp("(?:^|\s)"+(escapeRegexp(prefix)+":"),"g"),"$1"+curprefix+":")
    ret = processIRIs(processWhitespace(ndata))
    ret.newPrefixes+=newPrefixes
    ret
  escapeRegexpRegexp = new RegExp("[-\/\\^$*+?.!|[\]{}]","g")
  function escapeRegexp(string)
    string.replace(escapeRegexpRegexp, '\\$&')
  function replaceAll(string,replace,replaceWith)
    string.replace(new RegExp(escapeRegexp(replace),"g"),replaceWith)
  function getCurrentSubjects(cm)
    if (cm.getSelection!)
      pos = cm.getCursor("from")
      pos2 = cm.getCursor("to")
      if (pos2.line<pos.line || (pos2.line==pos.line && pos2.ch<pos.ch)) then [pos, pos2] = [pos2,pos]
    else
      pos = cm.getCursor!
      if (pos.ch==0) then pos.ch=1
      token = cm.getTokenAt(pos)
      if (token.type=='variable-3')
        pos.ch=token.end+2
        token = cm.getTokenAt(pos)
      else if (token.type=='operator' && token.string==':')
        pos.ch+=1
        token = cm.getTokenAt(pos)
      while ((token.type!='atom' && token.type!='variable-2') || token.state.curPos!="property")
        pos.ch=token.start-1
        if (pos.ch==-1)
          if (pos.line==0) then return
          pos.line--
          pos.ch=cm.getLine(pos.line).length
        token = cm.getTokenAt(pos)
      pos = getNodeFromPosition(cm,pos).cur
      pos2 = {line: pos.line, ch:pos.ch }
      while ((token.type!='punctuation' || token.string!='.'))
        pos2.ch=token.end+1
        token = cm.getTokenAt(pos2)
        if (token.end==pos2.ch-1)
          pos2.ch=0
          pos2.line++
          if (pos2.line>cm.lastLine!) then return
          token = cm.getTokenAt(pos2)
    iris = []
    data = cm.getRange(pos,pos2)
    while (pos.line<pos2.line || (pos.line==pos2.line && pos.ch<pos2.ch))
      token = cm.getTokenAt(pos)
      if (token.end==pos.ch-1)
        pos.ch=0
        pos.line++
        token = cm.getTokenAt(pos)
      if ((token.type=='atom' || token.type=='variable-2') && token.state.curPos=="property")
        iris.push(getIRIFromPosition(cm,pos).node)
      pos.ch=token.end+1
    {iris:iris,data:data}
  # actions
  function deleteCurrentSubjects(cm)
    currentSubjects = getCurrentSubjects(cm)
    if (!currentSubjects)
      toastr.error("Couldn't find subject IRI(s)")
    else
      query = replaceAll(replaceAll(deleteResourceQuery.getValue!,"<IRIS>",currentSubjects.iris.join(" ")),"<GRAPHIRI>",$scope.graphIRI)
      <-! sparql.update($scope.sparulEndpoint,query).then(_,handleError)
      updateGraphs!
      toastr.success("Successfully deleted #{currentSubjects.iris.join(", ")} in #{if ($scope.graphIRI) then "graph "+$scope.graphIRI else "default graph" } at endpoint #{$scope.restEndpoint} .")
  function replaceCurrentSubjects(cm)
    currentSubjects = getCurrentSubjects(cm)
    if (!currentSubjects)
      toastr.error("Couldn't find subject IRI(s)")
    else
      query = replaceAll(replaceAll(deleteResourceQuery.getValue!,"<IRIS>",currentSubjects.iris.join(" ")),"<GRAPHIRI>",$scope.graphIRI)
      <-! sparql.update($scope.sparulEndpoint,query).then(_,handleError)
      <-! sparql.post($scope.restEndpoint,getPrefixLinesFromData($scope.data)+currentSubjects.data,$scope.graphIRI).then(_,handleError)
      updateGraphs!
      toastr.success("Successfully replaced #{currentSubjects.iris.join(", ")} in #{if ($scope.graphIRI) then "graph "+$scope.graphIRI else "default graph" } at endpoint #{$scope.restEndpoint} .")
  function saveCurrentSubjects(cm)
    if (cm.getSelection!)
      data = cm.getSelection!
      value = "selection"
    else
      tmp = getCurrentSubjects(cm)
      data = tmp.data
      value = tmp.iris[0]
    if (data)
      sparql.post($scope.restEndpoint,getPrefixLinesFromData($scope.data)+data,$scope.graphIRI).then((response) ->
        updateGraphs!
        toastr.success("Successfully inserted #{value} into #{if ($scope.graphIRI) then "graph "+$scope.graphIRI else "default graph" } at endpoint #{$scope.restEndpoint} .")
      ,handleError)
    else toastr.error("No data to save")
  function loadResource(cm,replace)
    d = getIRIUnderCursor(cm)
    if (d.node?)
      sparql.construct($scope.sparqlEndpoint,replaceAll(describeQuery.getValue!,"<IRI>",d.node)).then((response) ->
        toastr.success("Successfully loaded #{d.node} from #{if ($scope.graphIRI) then "graph "+$scope.graphIRI else "default graph" } at endpoint #{$scope.restEndpoint} .")
        if (replace?)
          prefixService.setPrefixNsMap(getPrefixesFromData(response.data))
          tmp = processIRIs(processWhitespace(response.data))
          $scope.data = tmp.newPrefixes+tmp.data
        else
          prefixService.setPrefixNsMap(getPrefixesFromData($scope.data))
          toAdd = processResource(response.data)
          cm.replaceRange(toAdd.newPrefixes, {line:getLineAfterPrefixes($scope.data),ch:0})
          cm.replaceRange(toAdd.data, {line:cm.lastLine!+1,ch:0})
      ,handleError)
    else toastr.error("No IRI under cursor")
  function loadResourceDirect(cm,replace)
    d = getIRIUnderCursor(cm)
    if (d.node?)
      $http.get(d.node.substring(1,d.node.length-1),{
        headers: { 'Accept' : 'text/turtle' }
      }).then((response) ->
        toastr.success("Successfully loaded #{d.node}.")
        if (replace?)
          prefixService.setPrefixNsMap(getPrefixesFromData(response.data))
          tmp = processIRIs(processWhitespace(response.data))
          $scope.data = tmp.newPrefixes+tmp.data
        else
          prefixService.setPrefixNsMap(getPrefixesFromData($scope.data))
          toAdd = processResource(response.data)
          cm.replaceRange(toAdd.newPrefixes, {line:getLineAfterPrefixes($scope.data),ch:0})
          cm.replaceRange(toAdd.data, {line:cm.lastLine!+1,ch:0})
      ,handleError)
    else toastr.error("No IRI under cursor")
  relativeIRIMatchRegex = new RegExp("<(?:[^:]*?|[^:]*?[/#].*?)>","g")
  iriMatchRegex = new RegExp("<.*?>","g")
  wsRegex1 = new RegExp("        ","g")
  wsRegex2 = new RegExp("    ","g")
  $scope.loadGraph = ->
    if (!$scope.loading)
      $scope.loading=true
      sparql.get($scope.restEndpoint,$scope.graphIRI).then((response) ->
        $scope.loading=false
        prefixService.setPrefixNsMap(getPrefixesFromData(response.data))
        tmp = processIRIs(processWhitespace(response.data))
        $scope.data = tmp.newPrefixes+tmp.data
        toastr.success("Successfully loaded #{if ($scope.graphIRI) then "graph "+$scope.graphIRI else "default graph" } from endpoint #{$scope.restEndpoint} .")
      ,(response) ->
        $scope.loading=false
        handleError(response)
      )
  $scope.postGraph = ->
    if (!$scope.inserting)
      $scope.inserting=true
      sparql.post($scope.restEndpoint,$scope.data,$scope.graphIRI).then((response) ->
        $scope.inserting=false
        updateGraphs!
        toastr.success("Successfully inserted data into #{if ($scope.graphIRI) then "graph "+$scope.graphIRI else "default graph" } at endpoint #{$scope.restEndpoint} .")
      ,(response) ->
        $scope.inserting=false
        handleError(response)
      )
  $scope.putGraph = ->
    if (!$scope.replacing)
      $scope.replacing=true
      if ($scope.data && $scope.data!='')
        sparql.put($scope.restEndpoint,$scope.data,$scope.graphIRI).then((response) ->
          $scope.replacing=false
          updateGraphs!
          toastr.success("Successfully replaced #{if ($scope.graphIRI) then "graph "+$scope.graphIRI else "default graph" } at endpoint #{$scope.restEndpoint} .")
        ,(response) ->
          $scope.replacing=false
          handleError(response)
        )
      else
        sparql.delete($scope.restEndpoint,$scope.graphIRI).then((response) ->
          $scope.replacing=false
          updateGraphs!
          toastr.success("Successfully deleted #{if ($scope.graphIRI) then "graph "+$scope.graphIRI else "default graph" } at endpoint #{$scope.restEndpoint} .")
        ,(response) ->
          $scope.replacing=false
          handleError(response)
        )
  # query configuration
  looseDefaultQueries =
    describeQuery : '''CONSTRUCT { <IRI> ?p ?o } WHERE { <IRI> ?p ?o }'''
    deleteResourceQuery : '''DELETE { ?s ?p ?o } WHERE {
      VALUES ?s { <IRIS> }
      ?s ?p ?o .
    }'''
    labelQuery : '''
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      SELECT ?label {
        <IRI> rdfs:label|skos:prefLabel|skos:altLabel ?label .
      }
      LIMIT 1
    '''
    subjectLabelQuery : '''
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      SELECT DISTINCT ?iri ?label {
        ?iri rdfs:label|skos:prefLabel|skos:altLabel ?label .
        FILTER(STRSTARTS(LCASE(?label),LCASE("<QUERY>")))
      }
      ORDER BY ?label
    '''
    subjectIRIQuery : '''
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      SELECT DISTINCT ?iri {
        { ?iri ?p ?o }
        UNION
        { ?s ?iri ?o }
        UNION
        { ?s ?p ?iri }
        FILTER(STRSTARTS(LCASE(STR(?iri)),LCASE("<QUERY>")))
      }
      ORDER BY ?iri
    '''
    propertyLabelQuery : '''
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX owl: <http://www.w3.org/2002/07/owl#>
      SELECT DISTINCT ?iri ?label {
        ?iri rdfs:label|skos:prefLabel|skos:altLabel ?label .
        FILTER(STRSTARTS(LCASE(?label),LCASE("<QUERY>")))
        {
          ?iri a rdf:Property .
        } UNION {
          ?iri a owl:DatatypeProperty .
        } UNION {
          ?iri a owl:ObjectProperty .
        } UNION {
          ?s ?iri ?o .
        }
      }
      ORDER BY ?label
    '''
    propertyIRIQuery : '''
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX owl: <http://www.w3.org/2002/07/owl#>
      SELECT DISTINCT ?iri {
        {
          ?iri a rdf:Property .
        } UNION {
          ?iri a owl:DatatypeProperty .
        } UNION {
          ?iri a owl:ObjectProperty .
        } UNION {
          ?s ?iri ?o .
        }
        FILTER(STRSTARTS(LCASE(STR(?iri)),LCASE("<QUERY>")))
      }
      ORDER BY ?iri
    '''
    objectLabelQuery : '''
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      SELECT DISTINCT ?iri ?label {
        ?iri rdfs:label|skos:prefLabel|skos:altLabel ?label .
        FILTER(STRSTARTS(LCASE(?label),LCASE("<QUERY>")))
      }
      ORDER BY ?label
    '''
    objectIRIQuery : '''
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      SELECT DISTINCT ?iri {
        { ?iri ?p ?o }
        UNION
        { ?s ?iri ?o }
        UNION
        { ?s ?p ?iri }
        FILTER(STRSTARTS(LCASE(STR(?iri)),LCASE("<QUERY>")))
      }
      ORDER BY ?iri
    '''
  strictDefaultQueries =
    describeQuery : '''CONSTRUCT { <IRI> ?p ?o } WHERE { <IRI> ?p ?o }'''
    deleteResourceQuery : '''DELETE { ?s ?p ?o } WHERE {
      VALUES ?s { <IRIS> }
      ?s ?p ?o .
    }'''
    labelQuery : '''
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      SELECT ?label {
        <IRI> rdfs:label|skos:prefLabel|skos:altLabel ?label .
      }
      LIMIT 1
    '''
    subjectLabelQuery : '''
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      SELECT DISTINCT ?iri ?label {
        #PROPERTYLIMIT
          <PROPERTY> rdfs:domain ?domain .
          ?iri a/rdfs:subClassOf* ?domain .
        #/PROPERTYLIMIT
        #OBJECTLIMIT
          <OBJECT> a ?objectClass .
          ?property rdfs:range ?objectClass .
        #/OBJECTLIMIT
        ?iri rdfs:label|skos:prefLabel|skos:altLabel ?label .
        FILTER(STRSTARTS(LCASE(?label),LCASE("<QUERY>")))
      }
      ORDER BY ?label
    '''
    subjectIRIQuery : '''
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      SELECT DISTINCT ?iri {
        #PROPERTYLIMIT
          <PROPERTY> rdfs:domain ?domain .
          ?iri a/rdfs:subClassOf* ?domain .
        #/PROPERTYLIMIT
        #OBJECTLIMIT
          <OBJECT> a ?objectClass .
          ?property rdfs:range ?objectClass .
        #/OBJECTLIMIT
        { ?iri ?p ?o }
        UNION
        { ?s ?iri ?o }
        UNION
        { ?s ?p ?iri }
        FILTER(STRSTARTS(LCASE(STR(?iri)),LCASE("<QUERY>")))
      }
      ORDER BY ?iri
    '''
    propertyLabelQuery : '''
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX owl: <http://www.w3.org/2002/07/owl#>
      SELECT DISTINCT ?iri ?label {
        #SUBJECTLIMIT
          <SUBJECT> a ?subjectClass .
          ?iri rdfs:domain ?subjectClass .
        #/SUBJECTLIMIT
        #SUBJECTCLASSLIMIT
          VALUES ?subjectClass {
            <SUBJECTCLASSES>
          }
          ?iri rdfs:domain ?subjectClass .
        #/SUBJECTCLASSLIMIT
        #OBJECTLIMIT
          <OBJECT> a ?objectClass .
          ?iri rdfs:range ?objectClass .
        #/OBJECTLIMIT
        ?iri rdfs:label|skos:prefLabel|skos:altLabel ?label .
        FILTER(STRSTARTS(LCASE(?label),LCASE("<QUERY>")))
        {
          ?iri a rdf:Property .
        } UNION {
          ?iri a owl:DatatypeProperty .
        } UNION {
          ?iri a owl:ObjectProperty .
        } UNION {
          ?s ?iri ?o .
        }
      }
      ORDER BY ?label
    '''
    propertyIRIQuery : '''
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX owl: <http://www.w3.org/2002/07/owl#>
      SELECT DISTINCT ?iri {
        #SUBJECTLIMIT
          <SUBJECT> a ?subjectClass .
          ?iri rdfs:domain ?subjectClass .
        #/SUBJECTLIMIT
        #SUBJECTCLASSLIMIT
          VALUES ?subjectClass {
            <SUBJECTCLASSES>
          }
          ?iri rdfs:domain ?subjectClass .
        #/SUBJECTCLASSLIMIT
        #OBJECTLIMIT
          <OBJECT> a ?objectClass .
          ?iri rdfs:range ?objectClass .
        #/OBJECTLIMIT
        {
          ?iri a rdf:Property .
        } UNION {
          ?iri a owl:DatatypeProperty .
        } UNION {
          ?iri a owl:ObjectProperty .
        } UNION {
          ?s ?iri ?o .
        }
        FILTER(STRSTARTS(LCASE(STR(?iri)),LCASE("<QUERY>")))
      }
      ORDER BY ?iri
    '''
    objectLabelQuery : '''
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      SELECT DISTINCT ?iri ?label {
        #PROPERTYLIMIT
          <PROPERTY> rdfs:range ?domain .
          ?iri a/rdfs:subClassOf* ?domain .
        #/PROPERTYLIMIT
        ?iri rdfs:label|skos:prefLabel|skos:altLabel ?label .
        FILTER(STRSTARTS(LCASE(?label),LCASE("<QUERY>")))
      }
      ORDER BY ?label
    '''
    objectIRIQuery : '''
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      SELECT DISTINCT ?iri {
        #PROPERTYLIMIT
          <PROPERTY> rdfs:range ?domain .
          ?iri a/rdfs:subClassOf* ?domain .
        #/PROPERTYLIMIT
        { ?iri ?p ?o }
        UNION
        { ?s ?iri ?o }
        UNION
        { ?s ?p ?iri }
        FILTER(STRSTARTS(LCASE(STR(?iri)),LCASE("<QUERY>")))
      }
      ORDER BY ?iri
    '''
  describeQuery = new YASQE(document.getElementById('describeQuery'),
    value : looseDefaultQueries.describeQuery
    createShareLink : null
  )
  if $stateParams.config?.describeQuery? then describeQuery.setValue($stateParams.config.describeQuery)
  deleteResourceQuery = new YASQE(document.getElementById('deleteResourceQuery'),
    value : looseDefaultQueries.deleteResourceQuery
    createShareLink : null
  )
  labelQuery = new YASQE(document.getElementById('labelQuery'),
    value : looseDefaultQueries.labelQuery
    createShareLink : null
  )
  if $stateParams.config?.labelQuery? then labelQuery.setValue($stateParams.config.labelQuery)
  subjectLabelQuery = new YASQE(document.getElementById('subjectLabelQuery'),
    value : looseDefaultQueries.subjectLabelQuery
    createShareLink : null
  )
  if $stateParams.config?.subjectLabelQuery? then subjectLabelQuery.setValue($stateParams.config.subjectLabelQuery)
  subjectIRIQuery = new YASQE(document.getElementById('subjectIRIQuery'),
    value : looseDefaultQueries.subjectIRIQuery
    createShareLink : null
  )
  if $stateParams.config?.subjectIRIQuery? then subjectIRIQuery.setValue($stateParams.config.subjectIRIQuery)
  propertyLabelQuery = new YASQE(document.getElementById('propertyLabelQuery'),
    value : looseDefaultQueries.propertyLabelQuery
    createShareLink : null
  )
  if $stateParams.config?.propertyLabelQuery? then propertyLabelQuery.setValue($stateParams.config.propertyLabelQuery)
  propertyIRIQuery = new YASQE(document.getElementById('propertyIRIQuery'),
    value : looseDefaultQueries.propertyIRIQuery
    createShareLink : null
  )
  if $stateParams.config?.propertyIRIQuery? then propertyIRIQuery.setValue($stateParams.config.propertyIRIQuery)
  objectLabelQuery = new YASQE(document.getElementById('objectLabelQuery'),
    value : looseDefaultQueries.objectLabelQuery
    createShareLink : null
  )
  if $stateParams.config?.objectLabelQuery? then objectLabelQuery.setValue($stateParams.config.objectLabelQuery)
  objectIRIQuery = new YASQE(document.getElementById('objectIRIQuery'),
    value : looseDefaultQueries.objectIRIQuery
    createShareLink : null
  )
  if $stateParams.config?.objectIRIQuery? then objectIRIQuery.setValue($stateParams.config.objectIRIQuery)
  $scope.loadLooseDefaults = ->
    describeQuery.setValue(looseDefaultQueries.describeQuery)
    deleteResourceQuery.setValue(looseDefaultQueries.deleteResourceQuery)
    labelQuery.setValue(looseDefaultQueries.labelQuery)
    subjectLabelQuery.setValue(looseDefaultQueries.subjectLabelQuery)
    subjectIRIQuery.setValue(looseDefaultQueries.subjectIRIQuery)
    propertyLabelQuery.setValue(looseDefaultQueries.propertyLabelQuery)
    propertyIRIQuery.setValue(looseDefaultQueries.propertyIRIQuery)
    objectLabelQuery.setValue(looseDefaultQueries.objectLabelQuery)
    objectIRIQuery.setValue(looseDefaultQueries.objectIRIQuery)
  $scope.loadStrictDefaults = ->
    describeQuery.setValue(strictDefaultQueries.describeQuery)
    deleteResourceQuery.setValue(strictDefaultQueries.deleteResourceQuery)
    labelQuery.setValue(strictDefaultQueries.labelQuery)
    subjectLabelQuery.setValue(strictDefaultQueries.subjectLabelQuery)
    subjectIRIQuery.setValue(strictDefaultQueries.subjectIRIQuery)
    propertyLabelQuery.setValue(strictDefaultQueries.propertyLabelQuery)
    propertyIRIQuery.setValue(strictDefaultQueries.propertyIRIQuery)
    objectLabelQuery.setValue(strictDefaultQueries.objectLabelQuery)
    objectIRIQuery.setValue(strictDefaultQueries.objectIRIQuery)
)
