(function(){
	angular.module('tipsy.routes', ['ngRoute'])
	.config(['$routeProvider', function ($routeProvider) {
		$routeProvider
		.when('/review', {
			controller: 'ReviewCtrl',
			templateUrl: '/reviews/show.html'
		})
		.when('/review/empty', {
			templateUrl: '/reviews/empty.html'
		})
		.when('/review/thank-you', {
			templateUrl: '/reviews/thank-you.html'
		})
		;
	}])
	;
})();
