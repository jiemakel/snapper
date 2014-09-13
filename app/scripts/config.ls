angular.module('app', ['http-auth-interceptor','toastr','ngAnimate','ngStorage', 'ui.router', 'ui.codemirror', 'fi.seco.prefix', 'fi.seco.sparql'])
	.run ($rootScope,$http,authService) ->
		$rootScope.setAuth = ->
			$rootScope.authOpen = false
			$http.defaults.headers.common['Authorization'] = 'Basic '+btoa($rootScope.username+':'+$rootScope.password)
			authService.loginConfirmed()
		$rootScope.dismissAuth = ->
			$rootScope.authOpen = false
			authService.loginCancelled({status:401},"Authentication required")
		$rootScope.$on 'event:auth-loginRequired', ->
			$rootScope.authOpen = true
	.config ($stateProvider, $urlRouterProvider) ->
		$stateProvider
		.state 'home',
			url: '/?data&restEndpoint&sparqlEndpoint&graphIRI&configuration',
			templateUrl: 'partials/main.html',
			controller: 'MainCtrl'
		$urlRouterProvider.otherwise('/')
	.config (toastrConfig) ->
		angular.extend toastrConfig,
			allowHtml: false
			closeButton: false
			closeHtml: '<button>&times;</button>'
			containerId: 'toast-container'
			extendedTimeOut: 1000
			iconClasses:
				error: 'toast-error'
				info: 'toast-info'
				success: 'toast-success'
				warning: 'toast-warning'
			messageClass: 'toast-message'
			positionClass: 'toast-top-full-width'
			tapToDismiss: true
			timeOut: 1500
			titleClass: 'toast-title'
			toastClass: 'toast'
