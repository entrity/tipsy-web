(function () {
	angular.module('tipsy.review', [])
	.controller('ReviewCtrl', ['$scope', '$resource', '$http', '$location', 'RailsSupport', function ($scope, $resource, $http, $location, RailsSupport) {
		$scope.review = $resource('/reviews/next.json').get(function (data) {
			// Get reference to reviewable
			$scope.reviewable = data.reviewable;
			var ingredientIds = [];
			if ($scope.reviewable.ingredients && $scope.reviewable.ingredients.length) {
				// Normalize reviewable's ingredients
				$scope.reviewable.ingredients.forEach(normalizeIngredient);
				// Get ingredient ids for ingredients#name query
				ingredientIds = $scope.reviewable.ingredients.map(extractIngredientId);
			}
			// Get reference to diff
			$scope.diff = data.diff;
			if ($scope.diff.ingredients && $scope.diff.ingredients.length) {
				// Normalize base's ingredients
				$scope.diff.ingredients.forEach(normalizeIngredient);
				// Get ingredient ids for ingredients#name query
				ingredientIds = ingredientIds.concat($scope.diff.ingredients.map(extractIngredientId));
				// Collect base's ingredients into hash
				var hash = new Object;
				$scope.diff.ingredients.forEach(function (val, i) {
					hash[JSON.stringify(val)] = i;
				});
				// Set hash values to objects if shared or ins (and add class)
				$scope.reviewable.ingredients.forEach(function (val, i) {
					key = JSON.stringify(val);
					val.klass = (key in hash) ? 'unchanged' : 'ins';
					hash[key] = val;
				});
				// Set hash values to object if del (and add class)
				angular.forEach(hash, function (val, key) {
					if (typeof val === 'number') {
						hash[key] = $scope.diff.ingredients[val];
						hash[key].klass = 'del';
					}
				});
				// Replace diff ingredients with hash values
				$scope.diff.ingredients = Object.keys(hash).map(function (key) {
					return hash[key];
				});
			}
			// Get ingredient names from back end
			var ingredientIdsQueryString = ingredientIds.map(function (val, index) {
				return 'id[]='+val;
			}).join('&');
			$http.get('/ingredients/names.json?'+ingredientIdsQueryString)
			.success(function(data){
				function setIngredientName (ingredient) {
					ingredient.name = data[ingredient.ingredient_id];
				}
				if ($scope.reviewable.ingredients && $scope.reviewable.ingredients.length) $scope.reviewable.ingredients.forEach(setIngredientName);
				if ($scope.diff.ingredients && $scope.diff.ingredients.length) $scope.diff.ingredients.forEach(setIngredientName);
			});
		}, function () {
			console.error('Failed to fetch review');
			console.error(arguments);
			$location.path('/review/empty');
		});
		$scope.converter = Markdown.getSanitizingConverter();
		$scope.vote = function (coefficient) {
			$http.post('/reviews/'+$scope.review.id+'/vote.json', {coefficient:coefficient})
			.success(function (data, status, headers, config) {
				$location.path('/review/thank-you');
				$scope.fetchOpenReviewCt();
			})
			.error(function (data, status, headers, config) {
				console.error('Failed to complete vote');
				console.error(arguments);
				RailsSupport.errorAlert(data);
				$scope.fetchOpenReviewCt();
			});
		};
	}])
	;

	function extractIngredientId (obj, index, array) {
		return obj.ingredient_id;
	}
	function normalizeIngredient (val, i) {
		if (val.optional === 'false') val.optional = false;
	}
})();
