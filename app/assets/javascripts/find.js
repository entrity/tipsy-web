(function () {
	angular.module('tipsy.find', [])
	.controller('FindCtrl', ['$scope', '$resource', function ($scope, $resource) {
		$scope.fetchFindables = function (searchTerm) {
			if (searchTerm && searchTerm.length > 0) {
				$scope.findables = $resource('/fuzzy_find.json').query({fuzzy:searchTerm},
					function (data, responseHeaders) {
						$scope.findables = $scope.findables.sort(function (a,b) {
							var downcasedSearchTerm = searchTerm.toLowerCase();
							return compareFuzzyFindResults(a.name.toLowerCase(),b.name.toLowerCase(),downcasedSearchTerm);
						});
					});
			}
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
