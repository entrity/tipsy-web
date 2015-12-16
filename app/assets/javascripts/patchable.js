(function () {
	angular.module('tipsy.patchable', [])
	.factory('TipsyDiffable', ['Differ', '$resource', function (Differ, $resource) {
		function TipsyDiffable (diffable) {
			this.diffable = diffable;
			// get target (drink, ingredient, etc)
			var targetUrl;
			if (diffable.hasOwnProperty('drink_id'))
				targetUrl = '/drinks/'+diffable.drink_id+'.json';
			else if (diffable.hasOwnProperty('ingredient_id'))
				targetUrl = '/ingredients/'+diffable.ingredient_id+'.json';
			else
				throw "No target detected for diffable: "+JSON.stringify(diffable);
			this.target = $resource(targetUrl).get();
			// make diff
			// values in diff dictionary are an object consisting of [pre, post, patch, patched]
			// preVal is the value that the record held at the time that the revision was submitted
			// postVal is the value that was submitted as a revision
			// patchVal is the diff of preVal and postVal
			this.diff = {};
			for (var key in this.diffable) {
				if (/prev_.+/.test(key)) {
					this.set(key.substr(5), key);
				}
				else if (this.diffable.hasOwnProperty('prev_'+key)) {
					this.set(key, 'prev_'+key);
				}
				else {
					this.diff[key] = {
						post: this.diffable[key],
						curr: this.target[key],
					};
				}
			}
		}
		Object.defineProperties(TipsyDiffable.prototype, {
			has: {
				value: function (key) {
					return this.diff.hasOwnProperty(key);
				}
			},
			set: {
				value: function (postKey, prevKey, targetKey) {
					if (!prevKey) prevKey = 'prev_'+postKey;
					if (!targetKey) targetKey = postKey;
					var prevVal = this.diffable[prevKey];
					var postVal = this.diffable[postKey];
					var differ = new Differ(prevVal||'', postVal||'');
					if (typeof prevVal === "string" || typeof postVal === "string") {
						this.diff[postKey] = {
							prev: prevVal||'',
							post: postVal||'',
							patch: differ.prettyHtml(postVal),
							patched: differ.prettyHtml(this.target[targetKey]),
						};
					}
				}
			},
			prev: {
				value: function (key, value) {
					if (value == null)
						return this.diff[key].prev;
					else
						this.diff[key].prev = value;
				}
			},
			post: {
				value: function (key, value) {
					if (value == null)
						return this.diff[key].post;
					else
						this.diff[key].post = value;
				}
			},
			patch: {
				value: function (key) {
					return this.diff[key].patch;
				}
			},
			patched: {
				value: function (key) {
					return this.diff[key].patched;
				}
			},
			patchable: {
				value: function (key) {
					return this.diff[key].hasOwnProperty('patch');
				}
			},
		});
		return TipsyDiffable;
	}])
	.controller('PatchableCtrl', ['$scope', '$resource', '$http', '$location', 'Drink', 'Ingredient', 'RailsSupport', 'TipsyDiffable',
	function ($scope, $resource, $http, $location, Drink, Ingredient, RailsSupport, TipsyDiffable) {
		$scope.converter = Markdown.getSanitizingConverter();
		$scope.fetchDiffable = function (url) {
			$http.get(url).then(function(response){
				$scope.diffableLoaded = true;
				$scope.diff = new TipsyDiffable(response.data); // revision or ingredient revision
			})
		}
	}])
	.directive('tipsyDiff', function () {
		return {
			restrict: 'E',
			scope: {
				key: '@',
				title: '@',
			},
			link: function (scope) {
				scope.diff = scope.$parent.diff;
			},
			template: '<div ng-if="diff.has(key)"> \
			<h2>{{title}}</h2> \
			<div class="grid"> \
				<label class="grid-cell">Diff/Old Value</label> \
				<label class="grid-cell">Patched/New Value</label> \
			</div> \
			<div class="grid" ng-show="diff.patchable(key)"> \
				<div class="grid-cell" ng-bind-html="diff.prev(key)"></div> \
				<div class="grid-cell" ng-bind-html="diff.patched(key)"></div> \
			</div> \
			<div class="grid" ng-hide="diff.patchable(key)"> \
				<div class="grid-cell" ng-bind-html="diff.curr(key)"></div> \
				<div class="grid-cell" ng-bind-html="diff.post(key)"></div> \
			</div> \
		</div>',
		};
	})
	;

})();
