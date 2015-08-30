(function(){
	angular.module('tipsy.misc', [])
	.controller('Home.AuthedCtrl', ['$scope', '$http', 'Drink', function ($scope, $http, Drink) {
		$http.get('/home/drinks.json').then(
			function (response) {
				$scope.topDrinks      = response.data.general.map(function (obj) { return new Drink(obj) });
				$scope.topGinDrinks   = response.data.gin_drinks.map(function (obj) { return new Drink(obj) });
				$scope.topVodkaDrinks = response.data.vodka_drinks.map(function (obj) { return new Drink(obj) });
				$scope.topMargaritas  = response.data.margaritas.map(function (obj) { return new Drink(obj) });
			},
			function (response) {
				console.error(response.status, response.data);
			}
		);
	}])
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
