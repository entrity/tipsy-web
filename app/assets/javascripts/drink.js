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
					var sharedAttrs = ['name', 'description', 'instructions', 'ingredients', 'abv', 'calories', 'prep_time', 'profane', 'non_alcoholic'];
					for (var i = 0; i < sharedAttrs.length; i++) {
						var key = sharedAttrs[i];
						this[key] = drink[key];
					}
					this.drink_id = drink.id;
					this.revision_id = drink.revision_id;
					this.prev_description = drink.description;
					this.prev_instruction = drink.instructions;
					// Fetch ingredients from server
					this.prev_ingredients = Drink.ingredients({id:id}, function () {
						this.ingredients = angular.copy(this.prev_ingredients);
					});
				},
			}
		});
		return Revision;
	}])
	.controller('DrinkCtrl', ['$scope', '$modal', 'Drink', function ($scope, $modal, Drink) {
		$scope.drink = window.drink;
		$scope.drinkCtrl = new Object;
		$scope.flag = function () {
			if ($scope.requireLoggedIn()) {
				var id = getDrinkId($scope);
				$modal.open({
					animation: true,
					templateUrl: '/drinks/flag-modal.html',
					size: 'lg',
				});
			}
		};
		$scope.loadEditView = function () {
			if ($scope.requireLoggedIn()) {
				var id = getDrinkId($scope);
				Turbolinks.visit('/drinks/'+id+'/edit.html');
			}
		};
		$scope.openPhotoUploadModal = function () {
			if ($scope.requireLoggedIn()) {
				var modalInstance = $modal.open({
					animation: true,
					controller: 'Drink.PhotoUploadCtrl',
					templateUrl: '/drinks/photo-upload-modal.html',
					size: 'medium',
					resolve: {
						drink: function () { return $scope.drink }
					},
				});
			}
		};
	}])
	.controller('Drink.EditCtrl', ['$scope', 'Drink', 'Revision', function ($scope, Drink, Revision) {
		var id = getDrinkId($scope);
		$scope.drink = Drink.get({id:id});
		$scope.revision = new Revision();
		$scope.drink.$promise.then(function () {
			$scope.revision.loadDrink($scope.drink);
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
			Turbolinks.visit('/drinks/'+id+'.html');
		}
		// Start description text editor
		new Markdown.Editor(Markdown.getSanitizingConverter()).run();
		// Start instructions text editor
		new Markdown.Editor(Markdown.getSanitizingConverter(), '-instructions').run();
	}])
	.controller('Drink.FlagModalCtrl', ['$scope', '$resource', 'Differ', function ($scope, $resource, Differ) {
		$scope.revisions = $resource('/drinks/'+getDrinkId($scope)+'/revisions.json').query(null, function (data) {
			data.forEach(function(revision){
				revision.$descriptionDiff = new Differ(revision.prev_description, revision.description).prettyHtml();
				revision.$instructionDiff = new Differ(revision.prev_instruction, revision.instructions).prettyHtml();
			});
		});
		$scope.submitFlag = function (revision) {
			if (!revision.$flagMotivation || !revision.$flagMotivation.trim().length) {
				alert('Please supply text for your flag.');
			}
			else if (confirm("Are you sure you want to submit this flag?")) {
				$resource('/flags.json').save({
					description: revision.$flagMotivation,
					flaggable_id: revision.id,
					flaggable_type: 'Revision',
				},
				function (data, headers) {
					$scope.$close();
				},
				function (response) {
					console.error(response);
					var alertMsg = "Unspecified error. See javascript console for details.";
					// alert on duplicate
					if (response.data.errors && response.data.errors.user) {
						response.data.errors.user.forEach(function (str) {
							if (str == 'has already been taken') return alertMsg = "You have already flagged this input";
						});
					}
					// alert on unspecified failure
					alert(alertMsg);
				});
			}
		}
	}])
	.controller('Drink.PhotoUploadCtrl', ['$scope', '$resource', function ($scope, $resource) {
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
