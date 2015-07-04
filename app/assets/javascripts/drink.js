(function () {
	angular.module('tipsy.drink', [])
	.factory('Drink', ['$resource', function ($resource) {
		var Drink = $resource('/drinks/:id.json', {id:'@id'}, {
			ingredients: {method:'GET', isArray:true, url:'/drinks/:id/ingredients.json', cache:true},
			update: {method:'PUT'},
		});
		Object.defineProperties(Drink.prototype, {
		});
		return Drink;
	}])
	.factory('Revision', ['$resource', function ($resource) {
		var Revision = $resource('/revisions/:id.json', {id:'@id'});
		Object.defineProperties(Revision.prototype, {
			// Copy select attributes from drink
			loadDrink: {
				configurable: false,
				value: function (drink) {
					var sharedAttrs = ['name', 'description', 'ingredients', 'abv', 'calories', 'prep_time', 'profane', 'non_alcoholic'];
					for (var i = 0; i < sharedAttrs.length; i++) {
						var key = sharedAttrs[i];
						this[key] = drink[key];
					}
					Object.defineProperties(this, {
						drink_id: {
							configurable: false,
							enumerable: true,
							value: drink.id
						},
						parent_id: {
							configurable: false,
							enumerable: true,
							value: drink.revision_id
						},
					});
				},
			}
		});
		return Revision;
	}])
	.controller('DrinkCtrl', ['$scope', 'Drink', function ($scope, Drink) {
		$scope.drinkCtrl = new Object;
		$scope.loadEditView = function () {
			if ($scope.requireLoggedIn()) {
				var id = getDrinkId($scope);
				Turbolinks.visit('/drinks/'+id+'/edit.html');
			}
		};
	}])
	.controller('Drink.EditCtrl', ['$scope', 'Drink', 'Revision', function ($scope, Drink, Revision) {
		var id = getDrinkId($scope);
		$scope.drink = Drink.get({id:id});
		$scope.revision = new Revision();
		$scope.drink.$promise.then(function () {
			$scope.revision.loadDrink($scope.drink);
			$scope.revision.ingredients = Drink.ingredients({id:id});
		});
		$scope.addIngredient = function () {
			$scope.revision.ingredients.push(new Object);
		}
		$scope.removeIngredient = function (index) {
			if (!isNaN(index) && index >= 0) $scope.revision.ingredients.splice(index, 1);
		}
		$scope.save = function () {
			$scope.revision.$save(null, function (data) {
				// success
			}, function () {
				// failure
			});
		}
		$scope.visitDrink = function () {
			Turbolinks.visit('/drinks/'+id);
		}
		// Start description text editor
		new Markdown.Editor(Markdown.getSanitizingConverter()).run();
		// Start instructions text editor
		new Markdown.Editor(Markdown.getSanitizingConverter(), '-instructions').run();
	}])
	;

	function getDrinkId(scope) {
		var id;
		var match;
		if (scope.drink && scope.drink.id)
			id = $scope.drink.id;
		else if (window.drink && window.drink.id)
			id = window.drink.id;
		else if (match = /\/drinks\/(\d+)/.exec(window.location.pathname))
			id = match[1];
		return id;
	}
})();
