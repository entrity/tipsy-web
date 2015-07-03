(function () {
	angular.module('tipsy.find', [])
	.run(['$rootScope', '$resource', function ($rootScope, $resource) {
		$rootScope.finder = new Object;
		$rootScope.finder.ingredients = [];
		$rootScope.finder.options = new Object;
		$rootScope.finder.options.noProfanity = !!parseInt(localStorage.getItem('noProfanity'));
		$rootScope.$watch('finder.options.noProfanity', function (newVal, oldVal) {
			localStorage.setItem('noProfanity', newVal ? 1 : 0);
		});
		$rootScope.finder.fetchFindables = function (searchTerm) {
			if (searchTerm && searchTerm.length > 0) {
				var profanity = $rootScope.finder.options.noProfanity ? false : null;
				$rootScope.finder.findables = $resource('/fuzzy_find.json').query({fuzzy:searchTerm, profane:profanity},
					function (data, responseHeaders) {
						$rootScope.finder.findables = $rootScope.finder.findables.sort(function (a,b) {
							var downcasedSearchTerm = searchTerm.toLowerCase();
							return compareFuzzyFindResults(a.name.toLowerCase(),b.name.toLowerCase(),downcasedSearchTerm);
						});
					});
			}
		}
		$rootScope.finder.selected = function (item, model) {
			switch (parseInt(model.type)) {
				case window.DRINK:
					window.location.href = '/drinks/'+model.id; break;
				case window.INGREDIENT:
					$rootScope.finder.addIngredient(model);
					$rootScope.finder.findables = [];
					break;
				default:
					console.error('Bad type for findable: '+type);
			}
		}
		// Add ingredient to $rootScope.finder.ingredients and fetch drink results
		$rootScope.finder.addIngredient = function (ingredient) {
			$rootScope.finder.ingredients.push(ingredient);
			fetchDrinksForIngredients();
		}
		$rootScope.finder.removeIngredient = function (index) {
			$rootScope.finder.ingredients.splice(index, 1);
			fetchDrinksForIngredients();
		}
		$rootScope.finder.loadNextPage = function () {
			var pageNumber = ($rootScope.finder.drinks.page || 0) + 1;
			fetchDrinksForIngredients(pageNumber);
		}
		$rootScope.finder.navigateToDrink = function (drink) {
			window.location.href = '/drinks/'+drink.id;
		}
		// Define array or (append if array already exists) $rootScope.finder.drinks
		function fetchDrinksForIngredients (pageNumber) {
			if (!$rootScope.finder.ingredients.length) return;
			var ingredientIds = $rootScope.finder.ingredients.map(function (ingredient) {
				return ingredient.id;
			});
			var drinks = $resource('/drinks/:id.json').query({
				ingredient_id:ingredientIds,
				'select[]':['id', 'name', 'comment_ct', 'score'],
				page: (pageNumber || 1),
				profane: ($rootScope.finder.options.noProfanity ? false : null),
			}, function (data, responseHeaders) {
				if (!$rootScope.finder.drinks)
					$rootScope.finder.drinks = drinks;
				else
					$rootScope.finder.drinks = $rootScope.finder.drinks.concat(drinks);
				$rootScope.finder.drinks.total     = parseInt(responseHeaders()['tipsy-count']);
				$rootScope.finder.drinks.page      = parseInt(responseHeaders()['tipsy-page']);
				$rootScope.finder.drinks.pages     = parseInt(responseHeaders()['tipsy-total_pages']);
				$rootScope.finder.drinks.pagesLeft = $rootScope.finder.drinks.pages - $rootScope.finder.drinks.page;
				$rootScope.finder.drinks.left      = $rootScope.finder.drinks.total - $rootScope.finder.drinks.length;
				var ingredientsCt = $rootScope.finder.ingredients.length;
				for (var i = 0; i < $rootScope.finder.drinks.length; i++) {
					var drink = $rootScope.finder.drinks[i];
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
