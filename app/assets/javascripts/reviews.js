(function () {
	angular.module('tipsy.review', [])
	.factory('ReviewDiff', ['Differ', function (Differ) {
		var ReviewDiff = function (prevObj, postObj) {
			this._prevObj = prevObj;
			this._postObj = postObj;
			for (key in prevObj) {
				if (key in postObj) this.set(key);
			}
		};
		Object.defineProperties(ReviewDiff.prototype, {
			set: {
				value: function set (key, prev, post, isDiffable) {
					if (prev != null) this._prevObj[key] = prev;
					if (post != null) this._postObj[key] = post;
					if (isDiffable) this._prevObj[key] = new Differ(this._prevObj[key]||'', this._postObj[key]||'').prettyHtml();
				}
			},
			prev: {
				value: function prev (key) {
					if (this._prevObj[key] == this._postObj[key] || (!this._prevObj[key] && !this._postObj[key]))
						return '(no change)'
					else
						return this._prevObj[key];

				}
			},
			post: {
				value: function post (key) {
				if (!this._postObj[key] || typeof(this._postObj[key]) === 'string' && !this._postObj[key].trim())
					return 'empty';
				else
					return this._postObj[key];
				}
			},
		});
		return ReviewDiff;
	}])
	.controller('ReviewCtrl', ['$scope', '$resource', '$http', '$location', 'Drink', 'RailsSupport', 'ReviewDiff', 
	function ($scope, $resource, $http, $location, Drink, RailsSupport, ReviewDiff) {
		function recipeInstructionsToText (json) {
			return JSON.parse(json||'[]').map(function (item) {
				return "&middot; " + item.trim();
			}).join("\n");
		}
		$scope.converter = Markdown.getSanitizingConverter();
		$scope.fetchNextReview = function fetchNextReview () {
			$scope.review = $resource('/reviews/next.json').get(function (data) {
				// Create diff for holding diff html
				var diff = $scope.diff = new Object;
				// Get reference to reviewable
				var reviewable = $scope.reviewable = data.reviewable;
				// Get reference to flags
				$scope.flags = data.flags;
				// Preprocess 
				switch ($scope.review.reviewable_type) {
					case "Revision":
						var revision = $scope.reviewable;
						var drink = Drink.get({id:$scope.reviewable.drink_id}, function () {
							var diff = $scope.diff = new ReviewDiff(drink, revision);
							// Set diff html for description
							diff.set('description', reviewable.prev_description, reviewable.description, true);
							// Set diff html for instructions
							var prevInstruction = recipeInstructionsToText(reviewable.prev_instruction);
							var postInstruction = recipeInstructionsToText(reviewable.instructions);
							diff.set('instructions', prevInstruction, postInstruction, true);
							// Get unified list of ingredients (prev & current)
							if (!reviewable.ingredients) reviewable.ingredients = [];
							if (!reviewable.prev_ingredients) reviewable.prev_ingredients = [];
							var combinedIngredients = reviewable.ingredients.concat(reviewable.prev_ingredients);
							// Get ingredient ids in preparation for ingredients#name query
							ingredientIds = combinedIngredients.map(extractIngredientId);
							var ingredientIdsQueryString = ingredientIds.map(function (val, index) {
								return 'id[]='+val;
							}).join('&');
							// Normalize ingredients (interpret 'false' as false)
							combinedIngredients.forEach(normalizeIngredient);
							// Get ingredient names from server
							$http.get('/ingredients/names.json?'+ingredientIdsQueryString)
							.success(function(data){
								// Set ingredient 'name'
								combinedIngredients.forEach(function (ingredient) {
									ingredient.name = data[ingredient.ingredient_id];
								});
								// Build prev & post ingredient texts for diffing
								var prevIngredients = reviewable.prev_ingredients.map(ingredientToText).sort().join("\n");
								var postIngredients = reviewable.ingredients.map(ingredientToText).sort().join("\n");
								diff.set('ingredients', prevIngredients, postIngredients, true);
							});
						});
						break;
					case "Photo":
						reviewable.mediumUrl = reviewable.url.replace(/original/, 'medium');
						break;
				}
				$scope.vote = 0;
			}, function () {
				console.error('Failed to fetch review');
				console.error(arguments);
				$scope.vote.success = window.FAILURE;
			});
		}
		$scope.vote = function (coefficient) {
			$http.post('/reviews/'+$scope.review.id+'/vote.json', {coefficient:coefficient})
			.success(function (data, status, headers, config) {
				$scope.vote.status = window.SUCCESS;
				$scope.fetchOpenReviewCt();
			})
			.error(function (data, status, headers, config) {
				console.error('Failed to complete vote');
				console.error(arguments);
				RailsSupport.errorAlert(data);
				$scope.fetchOpenReviewCt();
			});
		};
		$scope.fetchNextReview();
	}])
	;

	function extractIngredientId (obj, index, array) {
		return obj.ingredient_id;
	}
	function ingredientToText (ingredient) {
		var str = ingredient.qty + ' ' + ingredient.name;
		if (ingredient.optional) str += ' (optional)';
		return str;
	}
	function normalizeIngredient (val, i) {
		if (val.optional === 'false') val.optional = false;
	}
})();
