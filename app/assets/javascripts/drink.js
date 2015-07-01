(function () {
	angular.module('tipsy.drink', [])
	.controller('DrinkCtrl', ['$scope', '$resource', function ($scope, $resource) {
		$scope.loadEditView = function () {
			if ($scope.requireLoggedIn() && $scope.requirePermission(PERMISSION_EDIT_DRINK)) {
			}
		};
	}])
	;
})();
