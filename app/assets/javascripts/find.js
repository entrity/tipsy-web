(function () {
	angular.module('tipsy.find', [])
	.controller('FindCtrl', ['$rootScope', '$scope', '$resource', '$location', 'Drink', 'Ingredient', function ($rootScope, $scope, $resource, $location, Drink, Ingredient) {
		$rootScope.finder = {findables:[]};
		$scope.finder.ingredients = [];
		$scope.finder.options = new Object;
		$scope.finder.fetchFindables = function ($select) {
			var searchTerm = $select.search;
			if (searchTerm && searchTerm.length > 0) {
				var ingredientIds = this.ingredients.map(function (item) { return item.id });
				var params = {
					fuzzy: searchTerm,
					'exclude_ingredient_ids[]': ingredientIds,
					profane: !$scope.finder.options.noProfanity,
					drinks: !(this.ingredients && this.ingredients.length)
				}
				$scope.finder.findables = $resource('/fuzzy_find.json').query(params,
					function (data, responseHeaders) {
						$scope.finder.findables = $scope.finder.findables.sort(function (a,b) {
							var downcasedSearchTerm = searchTerm.toLowerCase();
							return compareFuzzyFindResults(a.name.toLowerCase(),b.name.toLowerCase(),downcasedSearchTerm);
						});
					});
			}
		}
		// callback when a selection is made
		$scope.finder.selected = function ($item, $select) {
			if ($item) {
				switch (parseInt($item.type)) {
					case window.DRINK:
						var url = new Drink($item).getUrl();
						$scope.visitNoTurbo(url); break;
					case window.INGREDIENT:
						this.findables = [];
						delete $select.search;
						delete $select.selected;
						if ($scope.onSplashScreen) $scope.visitNoTurbo('/?ingredient_id='+$item.id);
						else $scope.finder.addIngredient($item);
						break;
					default:
						console.error('Bad type for findable: '+type);
				}
			}
		}
		// Add ingredient to $scope.finder.ingredients and fetch drink results
		$scope.finder.addIngredient = function (ingredient) {
			this.ingredients.push(new Ingredient(ingredient));
			angular.element('body').animate({scrollTop:0}, 200);
			this.fetchDrinksForIngredients();
		}
		$scope.finder.removeIngredient = function (index) {
			if (index == null) {
				this.ingredients = [];
				this.drinks = [];
			} else {
				this.ingredients.splice(index, 1);
				this.fetchDrinksForIngredients();
			}
		}
		$scope.finder.loadNextPage = function () {
			var pageNumber = (this.drinks.page || 0) + 1;
			this.fetchDrinksForIngredients(pageNumber, true);
		}
		// Define array or (append if array already exists) $scope.finder.drinks
		$scope.finder.fetchDrinksForIngredients = function (pageNumber, append) {
			if (!($scope.finder.ingredients && $scope.finder.ingredients.length)) return;
			var ingredientIds = [], canonicalIngredientIds = [];
			$scope.finder.ingredients.forEach(function (ingredient) {
				if (isNaN(ingredient.canonical_id))
					ingredientIds.push(ingredient.id);
				else
					canonicalIngredientIds.push(ingredient.canonical_id);
			});
			var drinks = $resource('/drinks/:id.json').query({
				'ingredient_id[]':ingredientIds,
				'canonical_ingredient_id[]':canonicalIngredientIds,
				'select[]':['id', 'name', 'comment_ct', 'up_vote_ct', 'ingredient_ct'],
				page: (pageNumber || 1),
				profane: ($scope.finder.options.noProfanity ? false : null),
			}, function (data, responseHeaders) {
				// make Drinks from data
				drinks = drinks.map(function (datum) { return new Drink(datum) });
				if (append && $scope.finder.drinks)
					$scope.finder.drinks = $scope.finder.drinks.concat(drinks);
				else
					$scope.finder.drinks = drinks;
				$scope.finder.drinks.total     = parseInt(responseHeaders()['tipsy-count']);
				$scope.finder.drinks.page      = parseInt(responseHeaders()['tipsy-page']);
				$scope.finder.drinks.pages     = parseInt(responseHeaders()['tipsy-total_pages']);
				$scope.finder.drinks.pagesLeft = $scope.finder.drinks.pages - $scope.finder.drinks.page;
				$scope.finder.drinks.left      = $scope.finder.drinks.total - $scope.finder.drinks.length;
				var ingredientsCt = $scope.finder.ingredients.length;
				for (var i = 0; i < $scope.finder.drinks.length; i++) {
					var drink = $scope.finder.drinks[i];
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
		$scope.finder.hideIngredientCtls = function hideIngredientCtls () {
			this.ingredients.forEach(function (ingredient) {
				delete ingredient._ctlToggled;
			});
		}
		// Fetch ingredient and drinks if ingredient_id in params
		if (window.location.search) {
			var match = /ingredient_id=(\d+)/.exec(window.location.search);
			if (match) {
				var id = match[1];
				$resource('/ingredients/:id.json', {id:'@id'}).get({id:id},
					function (data) { $scope.finder.addIngredient(data) }
				);
			}
		}
	}])
	;

	function compareFuzzyFindResults (a, b, searchTerm) {
		var levenshteinDifference = a.distance - b.distance;
		if (levenshteinDifference != 0) return levenshteinDifference;
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
