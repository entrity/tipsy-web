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
	.controller('DrinkCtrl', ['$scope', '$modal', '$http', 'Drink', 'RailsSupport', function ($scope, $modal, $http, Drink, RailsSupport) {
		$scope.drink = window.drink;
		$scope.drinkCtrl = new Object;
		$scope.comments = window.drink.comments;
		$scope.tips = jQuery.grep($scope.drink.comments, function (comment) {
			return comment.tip_pts;
		}).sort(function (a, b) {
			return a.tip_pts - b.tip_pts;
		});
		// Get votes for these comments for this user from backend, and set comment.userVote on each
		(function(){
			$scope.getUser().$promise.then(function (user) {
				var commentIds = $scope.comments.reduce(function (prev, comment) {
					return prev + '&comment_id[]=' + comment.id;
				}, '');
				$http.get('/comments/votes?user_id='+user.id+commentIds)
				.success(function (data) {
					var commentMap = {};
					$scope.drink.comments.forEach(function (comment) {
						commentMap[comment.id] = comment;
					});
					data.forEach(function (comment) {
						if (commentMap[comment.id]) angular.extend(commentMap[comment.id], comment);
					});
				});
			})
		})();
		$scope.flag = function () {
			if ($scope.requireLoggedIn()) {
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
		$scope.createComment = function (comment) {
			if ($scope.requireLoggedIn()) {
				$http.post('/comments.json',
					angular.extend(comment, {drink_id: $scope.drink.id})
				)
				.success(function (data) {
					delete $scope.newComment.text;
					$scope.comments.push(data);
				})
				.error(function (data) {
					RailsSupport.errorAlert(data);
				})
			}
		};
		$scope.upvoteComment = function (comment) {
			if ($scope.requireLoggedIn()) {
				$http.post('/comments/'+comment.id+'/upvote.json')
				.success(function (data, status, headers, config) {
					comment.userVote = status == 201 ? 1 : 0;
				})
				.error(function (data, status, headers, config) {
					console.error(data, config);
				});
			}
		};
		$scope.dnvoteComment = function (comment) {
			if ($scope.requireLoggedIn()) {
				$http.post('/comments/'+comment.id+'/upvote.json')
				.success(function (data, status, headers, config) {
					comment.userVote = status == 201 ? -1 : 0;
				})
				.error(function (data, status, headers, config) {
					console.error(data, config);
				});
			}
		};
		$scope.flagComment = function (comment) {
			if ($scope.requireLoggedIn()) {
				$http.post('/flags.json', {
					flaggable_id: comment.id,
					flaggable_type: 'Comment',
					description: comment._flagDescription,
				})
				.success(function (data, status, headers, config) {

				})
				.error(function (data, status, headers, config) {

				});
			}
		};
		$scope.removeComment = function (comment) {
			if ($scope.requireLoggedIn()) {
				$http.delete('/comments/'+comment.id+'.json')
				.success(function (data, status, headers, config) {

				})
				.error(function (data, status, headers, config) {

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
	.controller('Drink.FlagModalCtrl', ['$scope', '$resource', 'Differ', 'Flagger', function ($scope, $resource, Differ, Flagger) {
		$scope.revisions = $resource('/drinks/'+getDrinkId($scope)+'/revisions.json').query(null, function (data) {
			data.forEach(function(revision){
				revision.$descriptionDiff = new Differ(revision.prev_description, revision.description).prettyHtml();
				revision.$instructionDiff = new Differ(revision.prev_instruction, revision.instructions).prettyHtml();
			});
		});
		$scope.submitFlag = function (revision) {
			new Flagger($scope).submitFlag(revision, 'Revision');
		}
	}])
	.controller('Drink.PhotoUploadCtrl', ['$scope', '$resource', function ($scope, $resource) {
	}])
	;

	function getDrinkId(scope) {
		var id;
		var match;
		if (scope.drink && scope.drink.id)
			id = scope.drink.id;
		else if (window.drink && window.drink.id)
			id = window.drink.id;
		else if (match = /\/drinks\/(\d+)/.exec(window.location.pathname))
			id = match[1];
		return id;
	}
})();
