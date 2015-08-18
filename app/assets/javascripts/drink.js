(function () {
	angular.module('tipsy.drink', [])
	.factory('Drink', ['$resource', function ($resource) {
		var Drink = $resource('/drinks/:id.json', {id:'@id'}, {
			ingredients: {method:'GET', isArray:true, url:'/drinks/:id/ingredients.json', cache:true},
			update: {method:'PUT'},
		});
		var Map = function () {}; // For mapping Flags & Votes (as values) to the polymorphic records they target (as keys)
		Object.defineProperties(Map.prototype, {
			getValue: {
				value: function (type, id, fieldName) {
					var record = this[type] && this[type][id];
					return fieldName ? (record && record[fieldName]) : record;
				}
			}
		});
		Object.defineProperties(Drink.prototype, {
			// turn this.userFlags into a map if present
			getMap: {
				value: function getMap (mapName, dataArray, typeFieldName, idFieldName) {
					if (!this[mapName] && dataArray) {
						var drink = this;
						this[mapName] = new Map;
						dataArray.forEach(function (datum) {
							if (!drink[mapName][datum[typeFieldName]]) drink[mapName][datum[typeFieldName]] = new Object;
							drink[mapName][datum[typeFieldName]][datum[idFieldName]] = datum;
						});
					}
					return this[mapName];
				},
				configurable: false,
			},
			getUrl: {
				value: function () {
					var nameSlug = this.name ? '-' + this.name.toLowerCase().replace(/[^\w]+/g, '-') : '';
					return '/recipe/'+this.id+nameSlug;
				},
				configurable: false,
			},
			getUserFlagsMap: {
				value: function getUserFlagsMap () {
					return this.getMap('userFlagsMap', this.userFlags, 'flaggable_type', 'flaggable_id');
				},
				configurable: false,
			},
			getUserVotesMap: {
				value: function getUserVotesMap () {
					return this.getMap('userVotesMap', this.userVotes, 'votable_type', 'votable_id');
				},
				configurable: false,
			},
			setIsUserFlagged: {
				value: function setIsUserFlagged (flaggable, flaggableType) {
					var map;
					if (map = this.getUserFlagsMap())
						flaggable._isUserFlagged = !!map.getValue(flaggableType, flaggable.id);
				},
				configurable: false,
			},
			setUserVoteSign: {
				value: function setUserVoteSign (votable, votableType) {
					var map;
					if (map = this.getUserVotesMap())
						votable._userVoteSign = map.getValue(votableType, votable.id, 'sign');
				},
				configurable: false,
			}
		});
		return Drink;
	}])
	.factory('Revision', ['$resource', 'Drink', function ($resource, Drink) {
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
					this.parent_id = drink.revision_id;
					this.prev_description = drink.description;
					this.prev_instruction = drink.instructions;
					// Fetch ingredients from server
					var thisRevision = this;
					this.prev_ingredients = Drink.ingredients({id:drink.id}, function () {
						thisRevision.ingredients = angular.copy(thisRevision.prev_ingredients);
					});
				},
			}
		});
		return Revision;
	}])
	.controller('DrinkCtrl', ['$scope', '$modal', '$http', 'Drink', 'Flagger', 'RailsSupport', function ($scope, $modal, $http, Drink, Flagger, RailsSupport) {
		$scope.drink = new Drink(window.drink);
		$scope.drink.setUserVoteSign($scope.drink, 'Drink');
		$scope.drinkCtrl = new Object;
		$scope.comments = window.drink.comments;
		$scope.tips = new Array;
		// Iterate comments:
		$scope.comments.forEach(function (comment) {
			if (comment.tip_pts) tips.push(comment); // identify tips
			$scope.drink.setIsUserFlagged(comment, 'Comment'); // identify flags by current user
			$scope.drink.setUserVoteSign(comment, 'Comment'); // identify votes by current user
		});
		// Fetch related drinks
		Drink.query({'id[]':$scope.drink.related_drink_ids}, function (data) {
			$scope.relatedDrinks = data.map(function (obj) { return new Drink(obj) });
		});
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
				$scope.newComment._saving = true;
				$http.post('/comments.json',
					angular.extend(comment, {drink_id: $scope.drink.id})
				).then(
				function (response) {
					delete $scope.newComment.text;
					$scope.newComment._saving = false;
					$scope.comments.push(response.data);
				},
				function (response) {
					RailsSupport.errorAlert(response.data, response.status);
					$scope.newComment._saving = false;
				});
			}
		};
		$scope.vote = function (votable, votableType, sign) {
			if ($scope.requireLoggedIn()) {
				if (sign) sign = sign > 0 ? 1 : -1; // ensure sign in {-1,0,1}
				var prevSign = votable._userVoteSign || 0;
				if (prevSign == sign) sign = 0; // undo existing vote if current vote has a sign
				var delta = sign - prevSign;
				$http.post('/votes.json', {
					votable_type: votableType,
					votable_id: votable.id,
					sign: sign,
				})
				.success(function (data, status, headers, config) {
					votable._userVoteSign = sign;
					votable.score += delta;
				})
				.error(function (data, status, headers, config) {
					console.error(data, status, headers, config);
					RailsSupport.errorAlert(data, status);
				});
			}
		};
		$scope.flagComment = function (comment) {
			if ($scope.requireLoggedIn()) new Flagger(this, comment, 'Comment');
		}
		$scope.removeComment = function (comment) {
			if ($scope.requireLoggedIn()) {
				$http.delete('/comments/'+comment.id+'.json')
				.success(function (data, status, headers, config) {
					var tipsIndex = $scope.tips.indexOf(comment);
					if (tipsIndex) $scope.tips = $scope.tips.splice(tipsIndex, 1);
					var commentsIndex = $scope.comments.indexOf(comment);
					if (commentsIndex) $scope.comments = $scope.comments.splice(commentsIndex, 1);
				})
				.error(function (data, status, headers, config) {
					console.error(data, status, headers, config);
					alert('Failed to delete comment. See javascript console for details');
				});
			}
		};
	}])
	.controller('Drink.EditCtrl', ['$scope', 'Drink', 'Revision', 'RailsSupport', function ($scope, Drink, Revision, RailsSupport) {
		$scope.revision = new Revision();
		// Build description text editor
		var descriptionEditor = new Markdown.Editor(Markdown.getSanitizingConverter());
		// Build instructions text editor
		var instructionEditor = new Markdown.Editor(Markdown.getSanitizingConverter(), '-instructions');
		// Get drink id and act on it (but it won't be present if this is creating a revision for a new -- nonexistent -- drink)
		var id = getDrinkId($scope);
		if (id != null) { // could be 0, which is falsey
			$scope.drink = Drink.get({id:id});
			// Drink loaded callback
			$scope.drink.$promise.then(function () {
				$scope.revision.loadDrink($scope.drink);
				descriptionEditor.run();
				instructionEditor.run();
			});
		} else { // action for new, but not edit
			descriptionEditor.run();
			instructionEditor.run();
		}
		$scope.addIngredient = function () {
			if (!$scope.revision.ingredients) $scope.revision.ingredients = [];
			$scope.revision.ingredients.push(new Object);
		}
		$scope.removeIngredient = function (index) {
			if (!isNaN(index) && index >= 0) $scope.revision.ingredients.splice(index, 1);
		}
		$scope.save = function () {
			$scope.revision.$save(null, function (data) {
				// success
			}, function () {
				RailsSupport.errorAlert(data);
			});
		}
		$scope.visitDrink = function () {
			Turbolinks.visit($scope.drink.getUrl());
		}
	}])
	.controller('Drink.FlagModalCtrl', ['$scope', '$resource', 'Differ', 'Flagger', function ($scope, $resource, Differ, Flagger) {
		$scope.revisions = $resource('/drinks/'+getDrinkId($scope)+'/revisions.json').query(null, function (data) {
			data.forEach(function(revision){
				revision.$descriptionDiff = new Differ(revision.prev_description, revision.description).prettyHtml();
				revision.$instructionDiff = new Differ(revision.prev_instruction, revision.instructions).prettyHtml();
			});
		});
		$scope.flagger = new Flagger($scope, null, 'Revision', false);
		$scope.submitFlag = function (revision) {
			$scope.flagger.createFlag(revision, 'Revision')
			.$promise.then(function () {
				$scope.$close();
			});
		}
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
