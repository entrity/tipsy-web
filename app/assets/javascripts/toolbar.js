(function(){
	angular.module('tipsy.toolbar', [])
	.controller('ToolbarCtrl', ['$scope', function ($scope) {
		$scope.toolbar = new Object;
		$scope.openToolbarMenu = function (evt, menuName) {
			$scope.toolbar[menuName] = true;
			angular.element(document).one('click', function () {
				$scope.toolbar[menuName] = false;
				$scope.$apply();
			});
			evt.stopPropagation();
			evt.preventDefault();
		};
	}])
	;
})();
