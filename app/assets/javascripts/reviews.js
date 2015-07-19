(function () {
	angular.module('tipsy.review', [])
	.controller('ReviewCtrl', ['$scope', '$resource', '$http', '$location', 'Differ', 'RailsSupport', 
		function ($scope, $resource, $http, $location, Differ, RailsSupport) {
		$scope.converter = Markdown.getSanitizingConverter();
		$scope.fetchNextReview = function fetchNextReview () {
			$scope.review = $resource('/reviews/next.json').get(function (data) {
				// Create diff for holding diff html
				$scope.diff = new Object;
				// Get reference to reviewable
				var reviewable = $scope.reviewable = data.reviewable;
				// Get reference to flags
				$scope.flags = data.flags;
				// Preprocess 
				switch ($scope.review.reviewable_type) {
					case "Revision":
						// Make diff html for description
						$scope.diff.description = new Differ(reviewable.prev_description, reviewable.description).prettyMarkdown();
						$scope.diff.instruction = new Differ(reviewable.prev_instruction, reviewable.instructions).prettyMarkdown();
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
							var prevIngredients = reviewable.prev_ingredients.map(ingredientToText).sort().join("<br>");
							var postIngredients = reviewable.ingredients.map(ingredientToText).sort().join("<br>");
							$scope.diff.ingredients = new Differ(prevIngredients, postIngredients).prettyHtml();
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
