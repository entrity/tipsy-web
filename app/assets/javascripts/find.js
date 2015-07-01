(function () {
	angular.module('tipsy.find', [])
	.controller('FindCtrl', ['$scope', '$resource', function ($scope, $resource) {
		$scope.ingredients = [];
		$scope.findOptions = new Object;
		$scope.findOptions.noProfanity = !!parseInt(localStorage.getItem('noProfanity'));
		$scope.$watch('findOptions.noProfanity', function (newVal, oldVal) {
			localStorage.setItem('noProfanity', newVal ? 1 : 0);
		});
		$scope.fetchFindables = function (searchTerm) {
			if (searchTerm && searchTerm.length > 0) {
				var profanity = $scope.findOptions.noProfanity ? false : null;
				$scope.findables = $resource('/fuzzy_find.json').query({fuzzy:searchTerm, profane:profanity},
					function (data, responseHeaders) {
						$scope.findables = $scope.findables.sort(function (a,b) {
							var downcasedSearchTerm = searchTerm.toLowerCase();
							return compareFuzzyFindResults(a.name.toLowerCase(),b.name.toLowerCase(),downcasedSearchTerm);
						});
					});
			}
		}
		$scope.fuzzyFindSelected = function (item, model) {
			switch (parseInt(model.type)) {
				case window.DRINK:
					window.location.href = '/drinks/'+model.id; break;
				case window.INGREDIENT:
					$scope.addIngredient(model);
					$scope.findables = [];
					break;
				default:
					console.error('Bad type for findable: '+type);
			}
		}
		// Add ingredient to $scope.ingredients and fetch drink results
		$scope.addIngredient = function (ingredient) {
			$scope.ingredients.push(ingredient);
			fetchDrinksForIngredients();
		}
		$scope.removeIngredient = function (index) {
			$scope.ingredients.splice(index, 1);
			fetchDrinksForIngredients();
		}
		$scope.loadNextPage = function () {
			var pageNumber = ($scope.drinks.page || 0) + 1;
			fetchDrinksForIngredients(pageNumber);
		}
		$scope.navigateToDrink = function (drink) {
			window.location.href = '/drinks/'+drink.id;
		}
		// Define array or (append if array already exists) $scope.drinks
		function fetchDrinksForIngredients (pageNumber) {
			if (!$scope.ingredients.length) return;
			var ingredientIds = $scope.ingredients.map(function (ingredient) {
				return ingredient.id;
			});
			var drinks = $resource('/drinks/:id.json').query({
				ingredient_id:ingredientIds,
				'select[]':['id', 'name', 'comment_ct', 'vote_ct', 'score'],
				page: (pageNumber || 1),
				profane: ($scope.findOptions.noProfanity ? false : null),
			}, function (data, responseHeaders) {
				if (!$scope.drinks)
					$scope.drinks = drinks;
				else
					$scope.drinks = $scope.drinks.concat(drinks);
				$scope.drinks.total     = parseInt(responseHeaders()['tipsy-count']);
				$scope.drinks.page      = parseInt(responseHeaders()['tipsy-page']);
				$scope.drinks.pages     = parseInt(responseHeaders()['tipsy-total_pages']);
				$scope.drinks.pagesLeft = $scope.drinks.pages - $scope.drinks.page;
				$scope.drinks.left      = $scope.drinks.total - $scope.drinks.length;
				var ingredientsCt = $scope.ingredients.length;
				for (var i = 0; i < $scope.drinks.length; i++) {
					var drink = $scope.drinks[i];
					// calculate how many more ingredients the user needs for each search result
					drink._moreIngredients =  drink.ingredient_ct - ingredientsCt;
					// calculate classes for vote stars for each drink
					drink._stars = new Array(5);
					for (var j = 0; j < drink._stars.length; j++) {
						if (drink.score < j + 0.25)
							drink._stars[j] = 'fa-star-o';
						else if (drink.score >= j + 0.75)
							drink._stars[j] = 'fa-star';
						else
							drink._stars[j] = 'fa-star-half-o';
					}
				}
			});
		}
	}])
	;
	
	function compareFuzzyFindResults (a, b, searchTerm) {
		var searchTermIndex = 0;
		var length = Math.min(a.length, b.length);
		for (var i = 0; i < length; i++) {
			var aIsMatch = a[searchTermIndex] === searchTerm[searchTermIndex];
			var bIsMatch = b[searchTermIndex] === searchTerm[searchTermIndex];
			if (aIsMatch && bIsMatch) {
				searchTermIndex ++;
				if (searchTermIndex >= searchTerm.length)
					return compareStrings(a, b, length);
			}
			else if (aIsMatch)
				return -1;
			else if (bIsMatch)
				return 1;
		}
		return a.length - b.length;
	}

	function compareStrings (a, b, length) {
		for (var i = 0; i < length; i++) {
			var diff = a.charCodeAt(i) - b.charCodeAt(i);
			if (diff) return diff;
		}
		return a.length - b.length;
	}
	
})();
