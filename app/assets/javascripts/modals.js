(function(){
	angular.module('tipsy.modals', [])
	.controller('LoginModalCtrl', ['$scope', 'message', '$location', function ($scope, message, $location) {
		$scope.message = message;
		$scope.redirect = $location.url();
	}])
	;
})();
