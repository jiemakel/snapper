'use strict'

angular.module('fi.seco.prefix',[]).factory('prefixService', ($http) ->
  defaultNsPrefixMap = {}
  defaultPrefixNsMap = {}
  prefixNsMap = {}
  nsPrefixMap = {}
  newNss = 0
  $http.get("http://prefix.cc/popular/all.file.json").success((data) ->
    for prefix,ns of data
      defaultNsPrefixMap[ns]=prefix
      defaultPrefixNsMap[prefix]=ns
  )
  getLastSplit = (string,pos) ->
    p1 = string.lastIndexOf('#',pos)
    p2 = string.lastIndexOf('/',pos)
    if (p1>p2) then p1 else p2
  {
    reset : () -> 
      prefixNsMap = {}
      nsPrefixMap = {}
    setPrefixNsMap : (newPrefixNsMap) -> 
      prefixNsMap = newPrefixNsMap
      nsPrefixMap = new ->
        @[ns] = prefix for prefix, ns of prefixNsMap
        this
    invert : (map) ->
      new ->
        @[ns] = prefix for prefix, ns of map
        this
    setPrefixNs : (prefix,ns) -> 
      nsPrefixMap[ns]=prefix
      prefixNsMap[prefix]=ns
    expand : (prefixed) ->
      pos = prefixed.indexOf(':')
      if (prefixNsMap[prefixed.substring(0,pos)]?)
        ns = prefixNsMap[prefixed.substring(0,pos)]
        prefixNsMap[prefixed.substring(0,pos)] + prefixed.substring(pos+1)
      else prefixed
    getPrefix : (ns,checkdefault) ->
      if (!checkdefault)
        nsPrefixMap[ns]
      nsPrefixMap[ns] ? defaultNsPrefixMap[ns]
    getNs : (prefix,checkdefault) ->
      if (!checkdefault)
        prefixNsMap[prefix]
      prefixNsMap[prefix] ? defaultPrefixNsMap[prefix]
    shortForm : (iuri,allocate) ->
      if (iuri.charAt(iuri.length-1)=='>' && iuri.indexOf('"^^<')!=-1) # datatyped literal
        uri = iuri.substring(iuri.indexOf('"^^<')+4,iuri.length-1)
        tmp = this.sshortForm(uri)
        return { shortForm: iuri.substring(0,iuri.indexOf('"^^<')+3) + tmp.shortForm, ns : tmp.ns, prefix : tmp.prefix }
      if (iuri.charAt(0)=='"') then return { shortForm: iuri }
      if (iuri.charAt(0)=='<' && iuri.charAt(iuri.length-1)=='>') then uri = iuri.substring(1,iuri.length-1) else uri = iuri
      pos = getLastSplit(uri,uri.length)
      if (pos!=-1)
        while (pos>0)
          if (nsPrefixMap[uri.substring(0,pos+1)]?)
            prefix = nsPrefixMap[uri.substring(0,pos+1)]
            return { shortForm: prefix+':'+uri.substring(pos+1), ns : uri.substring(0,pos+1), prefix : prefix }
          pos = getLastSplit(uri,pos-1)
        if (!allocate) then return { shortForm: iuri }
        while (pos>0)
          if (defaultNsPrefixMap[uri.substring(0,pos+1)]?)
            prefix = defaultNsPrefixMap[uri.substring(0,pos+1)]
            nsPrefixMap[ns]=prefix
            prefixNsMap[prefix]=ns
            return { shortForm: prefix+':'+uri.substring(pos+1), ns : uri.substring(0,pos+1), prefix : prefix, newPrefix : true }
          pos = getLastSplit(uri,pos-1)
        pos = getLastSplit(uri,uri.length)
        pos2 = getLastSplit(uri,pos-1)
        if (pos2!=-1 && (uri.charAt(pos2+1)<'0' || uri.charAt(pos2+1)>'9'))
          newPrefix = uri.substring(pos2+1,pos)
          if (prefixNsMap[newPrefix]) then newPrefix = "ns"+(++newNss)
        else
          newPrefix = "ns"+(++newNss)
        newNs = uri.substring(0,pos+1)
        nsPrefixMap[newNs]=newPrefix
        prefixNsMap[newPrefix]=newNs
        return { shortForm: newPrefix+':'+uri.substring(pos+1), ns: newNs, prefix:newPrefix, newPrefix:true }
      { shortForm: iuri }
  }
)