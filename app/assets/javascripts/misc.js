(function(){
	angular.module('tipsy.misc', [])
	.controller('LoginModalCtrl', ['$scope', 'message', '$location', function ($scope, message, $location) {
		$scope.message = message;
		$scope.redirect = $location.url();
	}])
	.controller('User.EditCtrl', ['$scope', '$modal', function ($scope, $modal) {
		$scope.user = $scope.getUser();
		$scope.user.$promise.then(function getUserSuccess () {
			$scope.user.thumbnail = $scope.user.photo_url.replace(/original/, 'thumb');
		});
		$scope.openAvatarModal = function openAvatarModal () {
			if ($scope.requireLoggedIn()) {
				$modal.open({
					animation: true,
					template: '<tipsy-image-editor data-save-image="saveImage"></tipsy-image-editor>',
					size: 'lg',
					controller: 'User.AvatarModalCtrl',
					resolve: {
						user: function () { return $scope.user }
					}
				});
			}
		}
	}])
	.directive('stopEvent', function () {
		return {
			restrict: 'A',
			link: function (scope, element, attr) {
				element.on(attr.stopEvent, function (e) {
					e.stopPropagation();
				});
			}
		};
	})
	;
})();
