(function(){
	angular.module('tipsy.ingredient', [])
	.factory('Ingredient', ['$resource', function ($resource) {
		var Ingredient = $resource('/ingredients/:id.json', {id:'@id'}, {
		});
		Object.defineProperties(Ingredient.prototype, {
			getUrl: {
				configurable: false,
				value: function getUrl () {
					return Ingredient.getUrl(this);
				}
			},
		});
		Object.defineProperties(Ingredient, {
			getUrl: {
				configurable: false,
				value: function getUrl (ingredient) {
					var nameSlug = ingredient.name ? '-' + ingredient.name.toLowerCase().replace(/[^\w]+/g, '-') : '';
					return '/ingredient/'+ingredient.id+nameSlug+'.html';
				}
			},
		});
		return Ingredient;
	}])
	.factory('IngredientRevision', ['$resource', function ($resource) {
		var Revision = $resource('/ingredient_revisions/:id.json', {id:'@id'});
		Object.defineProperties(Revision.prototype, {
			// Copy select attributes from drink
			loadIngredient: {
				configurable: false,
				value: function (ingredient) {
					var sharedAttrs = ['name', 'description', 'canonical_id'];
					for (var i = 0; i < sharedAttrs.length; i++) {
						var key = sharedAttrs[i];
						this[key] = ingredient[key];
					}
					this.ingredient_id     = ingredient.id;
					this.parent_id         = ingredient.revision_id;
					this.prev_description  = ingredient.description;
					this.prev_canonical_id = ingredient.canonical_id;
				},
			}
		});
		return Revision;
	}])
	.factory('IngredientSearch', ['Ingredient', function (Ingredient) {
		var IngredientSearch = function (ingredient, idsToExclude) {};
		Object.defineProperties(IngredientSearch.prototype, {
			choices: {
				get: function () {
					return IngredientSearch.choices; // defined in this.searchIngredients
				}
			},
			searchIngredients: {
				value: function (term) {
					if (term && term.length && term != IngredientSearch.term) {
						IngredientSearch.term = term;
						IngredientSearch.choices = Ingredient.query({fuzzy:term, 'exclude_ids[]':this.idsToExclude});
					}
				}
			},
			selected: {
				writable: true,
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
				scope.ingredientSearch = new IngredientSearch;
				if (attrs.ingredient) scope.ingredientSearch.choice       = scope.$eval(attrs.ingredient);
				if (attrs.excludeIds) scope.ingredientSearch.idsToExclude = scope.$eval(attrs.excludeIds);
				if (attrs.onSelected) scope.ingredientSearch.selected     = scope.$eval(attrs.onSelected);
			},
		}
	}])
	.controller('IngredientCtrl', ['$scope', '$modal', 'Ingredient', function ($scope, $modal, Ingredient) {
		$scope.ingredient = new Ingredient(window.ingredient);
		$scope.loadEditView = function () {
			if ($scope.requireLoggedIn()) {
				$scope.visit('/ingredients/'+$scope.ingredient.id+'/edit.html');
			}
		}; // loadEditView
		$scope.flag = function () {
			if ($scope.requireLoggedIn()) {
				$modal.open({
					animation: true,
					templateUrl: '/ingredients/flag-modal.html',
					size: 'lg',
				});
			}
		}; // flag
	}])
	.controller('Ingredient.EditCtrl', ['$scope', 'Ingredient', 'IngredientRevision', 'RailsSupport', function ($scope, Ingredient, IngredientRevision, RailsSupport) {
		var id = getUrlId();
		if (id == null) {
			$scope.ingredient = new Ingredient
			$scope.ingredient.$promise = $scope.createResolvedPromise($scope.ingredient);
		}
		else
			$scope.ingredient = Ingredient.get({id:id});
		$scope.revision = new IngredientRevision();
		$scope.editPage = {idsToExcludeFromSearch:(id == null ? [] : [id])};
		$scope.editPage.canonicalIngredientSelected = function canonicalIdSelected (item) {
			$scope.revision.canonical_id = item.id;
		};
		// Build description text editor
		var editor = new Markdown.Editor(Markdown.getSanitizingConverter());
		// Callback on ingredient loaded
		$scope.ingredient.$promise.then(function (data) {
			if (data.canonical_id && data.canonical_id != data.id)
				$scope.editPage.aliasNeeded = true;
			$scope.revision.loadIngredient(data);
			editor.run();
		});
		$scope.aliasCheckboxToggled = function () {
			if (!$scope.aliasNeeded) $scope.ingredient.canonical_id = null;
		}
		$scope.save = function () {
			$scope.revision.$save(null, function (data) {
				window.scrollTo(0,0);
			}, function (httpResponse) {
				RailsSupport.errorAlert(httpResponse);
			});
		}
	}])
	.controller('Ingredient.FlagModalCtrl', ['$scope', '$resource', 'Differ', 'Flagger', function ($scope, $resource, Differ, Flagger) {
		$scope.revisions = $resource('/ingredients/'+getUrlId()+'/revisions.json').query(null, function (data) {
			data.forEach(function(revision){
				revision.$descriptionDiff = new Differ(revision.prev_description, revision.description).prettyHtml();
			});
		});
		$scope.flagger = new Flagger($scope, null, 'IngredientRevision', false);
		$scope.submitFlag = function (revision) {
			$scope.flagger.createFlag(revision, revision._flagMotivation)
			.$promise.then(function () {
				$scope.$close();
			});
		}
	}])
	;

	function getUrlId () {
		var match = /\/ingredients\/(\d+)/.exec(window.location.pathname);
		if (match) return match[1];
	}
})();
