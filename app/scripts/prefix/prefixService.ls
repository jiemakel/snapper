'use strict'

angular.module('fi.seco.prefix',[]).factory('prefixService', ($http) ->
  defaultNsPrefixMap = {}
  defaultPrefixNsMap = {}
  prefixNsMap = {}
  nsPrefixMap = {}
  newNss = 0
  do
    data <-! $http.get("http://prefix.cc/popular/all.file.json").then
    for prefix,ns of data.data
      defaultNsPrefixMap[ns]=prefix
      defaultPrefixNsMap[prefix]=ns
  function getLastSplit(string,pos)
    p1 = string.lastIndexOf('#',pos)
    p2 = string.lastIndexOf('/',pos)
    if (p1>p2) then p1 else p2
  {
    reset : ->
      newNss := 0
      prefixNsMap := {}
      nsPrefixMap := {}
    setPrefixNsMap : (newPrefixNsMap) ->
      prefixNsMap := newPrefixNsMap
      nsPrefixMap := {}
      for prefix, ns of prefixNsMap then nsPrefixMap[ns]=prefix
    invert : (map) ->
      ret = {}
      for prefix, ns of map then ret[ns]=prefix
      ret
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
    unescapeLocalName : (lname) ->
      lname.replace(/\\/g,"")
    escapeLocalName : (lname) ->
      lname.replace(/\\.$/,"\\.").replace(/^([.-])/,"\\$1").replace(/([\\~!$&'()*+,;=\/?#@%])/g,'\\$1')
    shortForm : (iuri,allowShorter,allocate) ->
      if (iuri.charAt(iuri.length-1)=='>' && iuri.indexOf('"^^<')!=-1) # datatyped literal
        uri = iuri.substring(iuri.indexOf('"^^<')+4,iuri.length-1)
        tmp = this.shortForm(uri)
        return { shortForm: iuri.substring(0,iuri.indexOf('"^^<')+3) + tmp.shortForm, ns : tmp.ns, prefix : tmp.prefix }
      if (iuri.charAt(0)=='"') then return { shortForm: iuri }
      if (iuri.charAt(0)=='<' && iuri.charAt(iuri.length-1)=='>') then uri = iuri.substring(1,iuri.length-1) else uri = iuri
      pos = getLastSplit(uri,uri.length)
      if (pos!=-1)
        if (allowShorter)
          while (pos>0)
            if (nsPrefixMap[uri.substring(0,pos+1)]?)
              prefix = nsPrefixMap[uri.substring(0,pos+1)]
              return { shortForm: prefix+':'+this.escapeLocalName(uri.substring(pos+1)), ns : uri.substring(0,pos+1), prefix : prefix }
            pos = getLastSplit(uri,pos-1)
        else if (nsPrefixMap[uri.substring(0,pos+1)]?)
          prefix = nsPrefixMap[uri.substring(0,pos+1)]
          return { shortForm: prefix+':'+this.escapeLocalName(uri.substring(pos+1)), ns : uri.substring(0,pos+1), prefix : prefix }
        if (!allocate) then return { shortForm: iuri }
        pos = getLastSplit(uri,uri.length)
        if (allowShorter)
          while (pos>0)
            if (defaultNsPrefixMap[uri.substring(0,pos+1)]?)
              ns = uri.substring(0,pos+1)
              prefixO = defaultNsPrefixMap[uri.substring(0,pos+1)]
              prefix = prefixO
              nss = 1
              while (prefixNsMap[prefix]) then prefix = prefixO+(++nss)
              nsPrefixMap[ns]=prefix
              prefixNsMap[prefix]=ns
              return { shortForm: prefix+':'+this.escapeLocalName(uri.substring(pos+1)), ns : uri.substring(0,pos+1), prefix : prefix, newPrefix : true }
            pos = getLastSplit(uri,pos-1)
        else if (defaultNsPrefixMap[uri.substring(0,pos+1)]?)
          ns = uri.substring(0,pos+1)
          prefixO = defaultNsPrefixMap[uri.substring(0,pos+1)]
          prefix = prefixO
          nss = 1
          while (prefixNsMap[prefix]) then prefix = prefixO+(++nss)
          nsPrefixMap[ns]=prefix
          prefixNsMap[prefix]=ns
          return { shortForm: prefix+':'+this.escapeLocalName(uri.substring(pos+1)), ns : uri.substring(0,pos+1), prefix : prefix, newPrefix : true }
        pos = getLastSplit(uri,uri.length)
        pos2 = getLastSplit(uri,pos-1)
        if (pos2!=-1 && uri.charAt(pos2+1)!='_' && (uri.charAt(pos2+1)<'0' || uri.charAt(pos2+1)>'9'))
          newPrefixO = uri.substring(pos2+1,pos)
          newPrefix = newPrefixO
          nss = 1
          while (prefixNsMap[newPrefix]) then newPrefix = newPrefixO+(++nss)
        else
          newPrefix = "ns"+(++newNss)
        newNs = uri.substring(0,pos+1)
        nsPrefixMap[newNs]=newPrefix
        prefixNsMap[newPrefix]=newNs
        return { shortForm: newPrefix+':'+this.escapeLocalName(uri.substring(pos+1)), ns: newNs, prefix:newPrefix, newPrefix:true }
      { shortForm: iuri }
  }
)
