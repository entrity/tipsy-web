(function(){
	angular.module('tipsy.toolbar', [])
	.controller('ToolbarCtrl', ['$scope', '$http', function ($scope, $http) {
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
		$scope.openRepChangesMenu = function (evt) {
			$scope.openToolbarMenu(evt, 'repChangesMenu');
			var viewedPointDistributionIds = $scope.toolbar.repChanges.map(function (change) {
				return change.id;
			});
			$http.put('/users/viewed_point_distributions.json', {id:viewedPointDistributionIds})
			.success(function (data, status, headers, config) {
				$scope.toolbar.repChangesDelta = 0;
				delete $scope.toolbar.repChangesDeltaWithSign;
			});
		}
		$scope.fetchOpenReviewCt();
		$scope.getUser().$promise.then(function () {
			if ($scope.isLoggedIn()) {
				$http.get('/users/unviewed_point_distributions.json')
				.success(function (data, status, headers, config) {
					$scope.toolbar.repChanges = data;
					$scope.toolbar.repChangesDelta = 0;
					data.forEach(function (change) {
						change.pointsWithSign = addSignToNum(change.points);
						$scope.toolbar.repChangesDelta += (change.points || 0);
					});
					$scope.toolbar.repChangesDeltaWithSign = addSignToNum($scope.toolbar.repChangesDelta);
				});
			}
		});
	}])
	;

	function addSignToNum (num) {
		var sign = num <= 0 ? '' : '+';
		return sign + num;
	}
})();
