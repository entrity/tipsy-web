(function(){
	/* Depends on being included in angular module 'tipsy' */
	angular.module('tipsy.favourites', [])
	.run(['$rootScope', '$modal', function ($rootScope, $modal) {
		Object.defineProperties($rootScope, {
			/* Open modal */
			openFavourites: {
				configurable: false,
				value: function openFavourites (drink) {
					this.requireLoggedIn(function () {
						$rootScope.favouritesModal = $modal.open({
							animation: true,
							templateUrl: '/application/favourites.html',
							controller: 'FavouritesModalCtrl',
							size: 'med',
							resolve: {
								drink: function () { return drink },
							}
						});
					});
				},
			},
		});
	}])
	.factory('Favourite', ['$resource', function ($resource) {
		var Favourite = $resource('/favourites/:id.json');
		return Favourite;
	}])
	.factory('FavouritesCollection', ['$resource', function ($resource) {
		var Collection = $resource('/favourites_collections/:id.json');
		return Collection;
	}])
	.controller('FavouritesModalCtrl', ['$scope', '$http', 'RailsSupport', 'FavouritesCollection', 'drink',
	function ($scope, $http, RailsSupport, FavouritesCollection, drink) {
		$scope.collections = FavouritesCollection.query();
		$scope.newCollection = {};
		$scope.clickCollection = function (collection) {
			if (drink) {
				var collectionId = collection && collection.id;
				$http.post('/favourites.json', {drink_id:drink.id, collection_id:collectionId})
				.success(function (data) {
					drink._userFavId = data.id;
					$scope.$close();
				})
				.error(RailsSupport.errorAlert);
			}
			else
				(collection||$scope.newCollection)._show = !(collection||$scope.newCollection)._show;
		}
		$scope.saveCollection = function (collection) {
			$scope.requireLoggedIn(function () {
				if (collection && collection.id) {
					$http.put('/favourites_collections/'+collection.id+'.json')
					.success(function (data) { collection._toggled = false })
					.error(RailsSupport.errorAlert);
				} else {
					collection || (collection = $scope.newCollection);
					$http.post('/favourites_collections.json', collection)
					.success(function (data) {
						$scope.collections.push(data);
						$scope.newCollection = {};
						collection._toggled = false;
					})
					.error(RailsSupport.errorAlert);
				}
			});
		}
	}])
	.controller('FavouritesCollectionCtrl', ['$scope', '$http', 'Favourite', 'RailsSupport',
	function ($scope, $http, Favourite, RailsSupport) {
		$scope.favourites = Favourite.query({collection_id:($scope.collection && $scope.collection.id)}, function (data) {
			$scope.favourites.count = data.length;
		});
	}])
	;
})();
