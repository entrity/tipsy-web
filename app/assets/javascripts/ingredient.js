(function(){
	angular.module('tipsy.ingredient', [])
	.factory('Ingredient', ['$resource', function ($resource) {
		var Ingredient = $resource('/ingredients/:id.json', {id:'@id'}, {
		});
		return Ingredient;
	}])
	.factory('IngredientSearch', ['Ingredient', function (Ingredient) {
		var IngredientSearch = function (ingredient) {
			this.choice = ingredient;
		};
		Object.defineProperties(IngredientSearch.prototype, {
			choices: {
				get: function () {
					return IngredientSearch.choices;
				}
			},
			searchIngredients: {
				value: function (term) {
					if (term && term.length && term != IngredientSearch.term) {
						IngredientSearch.term = term;
						IngredientSearch.choices = Ingredient.query({fuzzy:term});
					}
				}
			},
			selected: {
				value: function (item, ingredient) {
					ingredient.ingredient_id = item.id;
				}
			},
		});
		return IngredientSearch;
	}])
	.directive('ingredientFinder', ['IngredientSearch', function (IngredientSearch) {
		return {
			template: '<ui-select theme="bootstrap" ng-model="ingredientSearch.choice" on-select="ingredientSearch.selected($item, ingredient)" reset-search-input="true" search-enabled="true" > \
					<ui-select-match data-placeholder="Search ingredients" allow-clear="false">{{ingredientSearch.choice.name}}</ui-select-match> \
					<ui-select-choices repeat="item in ingredientSearch.choices" refresh-delay="100" refresh="ingredientSearch.searchIngredients($select.search)"> \
						<div ng-bind-html="item.name | highlight: $select.search"></div> \
					</ui-select-choices> \
				</ui-select>',
			link: function (scope, elem, attrs) {
				var ingredient;
				if (attrs.ingredient) ingredient = scope.$eval(attrs.ingredient);
				scope.ingredientSearch = new IngredientSearch(ingredient);
			}
		}
	}])
	;
})();
