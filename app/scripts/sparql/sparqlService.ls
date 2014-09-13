'use strict'

angular.module('fi.seco.sparql',[])
  .factory('sparql', ($http,$q) ->
    service =
      check : (endpoint,params) ->
        deferred = $q.defer!
        $http(angular.extend({
          method: "GET"
          url : endpoint
          params: { query:"ASK {}" }
          headers: { 'Accept' : 'application/sparql-results+json' }
        },params)).then(
          (response) -> deferred.resolve(response.data.boolean?)
        , (response) -> deferred.reject(response)
        )
        deferred.promise
      checkUpdate : (endpoint,params) ->
        deferred = $q.defer!
        $http(angular.extend({
          method: "POST"
          url: endpoint
          headers: { 'Content-Type' : 'application/sparql-update' }
          data: "INSERT DATA {}"
        },params)).then(
          (response) -> deferred.resolve(response.status == 204)
        , (response) -> deferred.reject(response)
        )
        deferred.promise
      checkRest : (endpoint,params) ->
        deferred = $q.defer!
        $http(angular.extend({
          method: "POST"
          url : endpoint + "?default"
          data : ""
          headers: { 'Content-Type' : 'text/turtle' }
        },params)).then(
          (response) -> deferred.resolve(response.status == 204)
        , (response) -> deferred.reject(response)
        )
        deferred.promise
      get : (endpoint,graphIRI,params) ->
        $http(angular.extend({
          method: "GET"
          url : endpoint
          params: if graphIRI? then { graph:graphIRI } else {"default":""}
          headers: { 'Accept' : 'text/turtle' }
        },params))
      post : (endpoint,graph,graphIRI,params) ->
        $http(angular.extend({
          method: "POST"
          url : endpoint
          params: if graphIRI? then { graph:graphIRI } else {"default":""}
          data: graph
          headers: { 'Content-Type' : 'text/turtle' }
        },params))
      put : (endpoint,graph,graphIRI,params) ->
        $http(angular.extend({
          method: "PUT"
          url : endpoint
          params: if graphIRI? then { graph:graphIRI } else {"default":""}
          data: graph
          headers: { 'Content-Type' : 'text/turtle' }
        },params))
      delete : (endpoint,graphIRI,params) ->
        $http(angular.extend({
          method: "DELETE"
          url : endpoint
          params: if graphIRI? then { graph:graphIRI } else {"default":""}
        },params))
      construct : (endpoint,query,params) ->
        if (query.length<=2048)
          $http(angular.extend({
            method: "GET"
            url : endpoint
            params: { query:query }
            headers: { 'Accept' : 'text/turtle' }
          },params))
        else
          $http(angular.extend({
            method: "POST"
            url : endpoint
            data: query
            headers:
              'Content-Type': 'application/sparql-query'
              'Accept' : 'text/turtle'
          },params))
      query : (endpoint,query,params) ->
        if (query.length<=2048)
          $http(angular.extend({
            method: "GET"
            url : endpoint
            params: { query:query }
            headers: { 'Accept' : 'application/sparql-results+json' }
          },params))
        else
          $http(angular.extend({
            method: "POST"
            url : endpoint
            data: query
            headers:
              'Content-Type': 'application/sparql-query'
              'Accept' : 'application/sparql-results+json'
          },params))
      update : (endpoint,query,params) ->
        $http(angular.extend({
          method: "POST"
          url: endpoint
          headers: { 'Content-Type' : 'application/sparql-update' }
          data: query
        },params))
      bindingToString : (binding) ->
          if !binding? then "UNDEF"
          else
            value = binding.value.replace(/\\/g,'\\\\').replace(/\t/g,'\\t').replace(/\n/g,'\\n').replace(/\r/g,'\\r').replace(/[\b]/g,'\\b').replace(/\f/g,'\\f').replace(/\'/g,"\\'").replace(/\"/g,'\\"')
            if (binding.type == 'uri') then '<' + value + '>'
            else if (binding.type == 'bnode') then '_:' + value
            else
              if (binding.datatype?)
                switch binding.datatype
                  when 'http://www.w3.org/2001/XMLSchema#integer','http://www.w3.org/2001/XMLSchema#decimal','http://www.w3.org/2001/XMLSchema#double','http://www.w3.org/2001/XMLSchema#boolean' then value
                  when 'http://www.w3.org/2001/XMLSchema#string' then '"' + value + '"'
                  else '"' + value + '"^^<'+binding.datatype+'>'
              else if (binding['xml:lang']) then '"' + value + '"@' + binding['xml:lang']
              else '"' + value + '"'
  )
