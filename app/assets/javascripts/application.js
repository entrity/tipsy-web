// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require 'angular/angular'
//= require 'angular-animate/angular-animate'
//= require 'angular-aria/angular-aria.min'
//= require 'angular-bootstrap/ui-bootstrap-tpls.min'
//= require 'angular-drag-and-drop-lists/angular-drag-and-drop-lists.min'
//= require 'angular-resource/angular-resource.min'
//= require 'angular-route/angular-route.min'
//= require 'angular-sanitize/angular-sanitize.min'
//= require 'angular-touch/angular-touch.min'
//= require 'angular-ui-select/dist/select.min'
//= require google-diff-match-patch/diff_match_patch
//= require hammerjs/hammer.min.js
//= require ng-file-upload/ng-file-upload.min
//= require ng-pageslide/dist/angular-pageslide-directive.min
//= require pagedown/Markdown.Converter
//= require pagedown/Markdown.Sanitizer
//= require pagedown/Markdown.Editor
//= require ryanmullins-angular-hammer/angular.hammer.min
//= require image-resize-crop-canvas/component
//= require ui-bootstrap
//= require jquery.toolbar.min
//= require bootstrap-slider
//= require_tree .

(function(){

	angular.module('tipsy', [
		'dndLists',
		'hmTouchEvents',
		'ngAria',
		'ngResource',
		'ngSanitize',
		'pageslide-directive',
		'tipsy.drink',
		'tipsy.factories',
		'tipsy.find',
		'tipsy.image',
		'tipsy.ingredient',
		'tipsy.misc',
		'tipsy.rails',
		'tipsy.review',
		'tipsy.toolbar',
		'ui.bootstrap',
		'ui.select'
	])
	.run(['$rootScope', '$resource', '$modal', '$http', '$q', '$window', 'User', function ($rootScope, $resource, $modal, $http, $q, $window, User) {
		Object.defineProperties($rootScope, {
			addToCabinet: {
				configurable: false,
				value: function (ingredient) {
					addIngredientToAside(ingredient, 'cabinet');
				}
			},
			addToShoppingList: {
				configurable: false,
				value: function (ingredient) {
					addIngredientToAside(ingredient, 'shoppingList');
				}
			},
			cabinet: {
				configurable: false,
				value: JSON.parse(localStorage.getItem('cabinet')) || []
			},
			createResolvedPromise: {
				configurable: false,
				value: function (val) {
					var deferred = $q.defer();
					deferred.resolve(val);
					return deferred.promise;
				}
			},
			getConstant: {
				configurable: false,
				value: function (name) {
					return window[name];
				}
			},
			getUser: {
				configurable: false,
				value: function getUser (successCallback, failureCallback, forceReload) {
					// Fetch user from API
					if (forceReload || !$rootScope.currentUser) {
						window.user = $rootScope.currentUser = $resource('/users/0.json').get(null, function (data) {
							if (data.photo_url) data.tinyAvatar = data.photo_url.replace(/original/, 'tiny');
							window.user = $rootScope.currentUser = new User(data);
						});
					}
					// Schedule callbacks
					if (successCallback) $rootScope.currentUser.$promise.then(function () {
						if ($rootScope.currentUser.id)
							successCallback($rootScope.currentUser);
						else
							failureCallback($rootScope.currentUser);
					});
					if (failureCallback) $rootScope.currentUser.$promise.then(null, function () {
						failureCallback($rootScope.currentUser);
					});
					// Return
					return $rootScope.currentUser;
				}
			},
			getWindowVal: {
				configurable: false,
				value: function (key) {
					return window[key];
				},
			},
			fetchOpenReviewCt: {
				configurable: false,
				value: function () {
					$http.get('/reviews/count')
					.success(function (data, status, headers, config) {
						var count = parseInt(data);
						$rootScope.openReviewCt = count > 50 ? '50+' : count;
					})
					.error(function (data, status, headers, config) {
						console.error('Failed to fetch open review count');
						console.error(data, status, headers, config);
					});
				}
			},
			isInCabinet: {
				configurable: false,
				value: function isInCabinet (id) {
					if (typeof(id) === "object") id = id.id;
					if (typeof(id) === "string") id = parseInt(id);
					for (var i = 0; i < this.cabinet.length; i++) {
						if (this.cabinet[i].id == id) return true;
					}
					return false;
				}
			},
			isInShoppingList: {
				configurable: false,
				value: function isInShoppingList (id) {
					if (typeof(id) === "object") id = id.id;
					if (typeof(id) === "string") id = parseInt(id);
					for (var i = 0; i < this.shoppingList.length; i++) {
						if (this.shoppingList[i].id == id) return true;
					}
					return false;
				}
			},
			isLoggedIn: {
				configurable: false,
				value: function (forceReload) {
					return this.getUser(null, null, forceReload).id;
				}
			},
			isToggled: {
				configurable: false,
				value: function isToggled (key) {
					if (!(key in this.tipsyconfig)) this.tipsyconfig[key] = JSON.parse(localStorage.getItem(key));
					return this.tipsyconfig[key];
				}
			},
			loadCabinetToFuzzyFindResults: {
				configurable: false,
				value: function loadCabinetToFuzzyFindResults () {
					this.finder.ingredients = angular.copy(this.cabinet);
					this.finder.fetchDrinksForIngredients();
				}
			},
			openLoginModal: {
				configurable: false,
				value: function (modalMessage) {
					this.loginModal = $modal.open({
						animation: true,
						templateUrl: '/login-modal.html',
						controller: 'LoginModalCtrl',
						size: 'sm',
						resolve: {
							message: function () {
								return modalMessage;
							}
						}
					});
				}
			},
			openReviewModal: {
				configurable: false,
				value: function openReviewModal () {
					$modal.open({
						animation: true,
						templateUrl: '/reviews/modal.html',
						controller: 'ReviewCtrl',
						size: 'max',
					})
				}
			},
			parsePsqlIntarray: {
				configurable: false,
				value: function parsePsqlIntarray (text) {
					text.substr(1, text.length-2).split(',').map(function (num) { return parseInt(num) });
				}
			},
			removeFromCabinet:{
				configurable: false,
				value: function (ingredient) {
					removeIngredientFromAside(ingredient, 'cabinet');
				}
			},
			removeFromShoppingList:{
				configurable: false,
				value: function (ingredient) {
					removeIngredientFromAside(ingredient, 'shoppingList');
				}
			},
			requireLoggedIn: {
				configurable: false,
				value: function requireLoggedIn (successCallback, failureCallback) {
					if (successCallback || failureCallback) {
						this.getUser(successCallback, failureCallback);
						this.getUser(null, function () {
							$rootScope.openLoginModal('This action requires you to log in.');
						});
					}
					else if (this.isLoggedIn())
						return true;
					else
						this.openLoginModal('This action requires you to log in.');
				}
			},
			shoppingList: {
				configurable: false,
				value: JSON.parse(localStorage.getItem('shoppingList')) || []
			},
			sidebar: {
				configurable: false,
				value: {} // just for holding config options
			},
			tipsyconfig: {
				configurable: false,
				value: {} // just for holding config options
			},
			toggle: {
				configurable: false,
				value: function toggle (key) {
					this.tipsyconfig[key] = !this.tipsyconfig[key];
					localStorage.setItem(key, this.tipsyconfig[key]);
				}
			},
			toggleSidebar: { // deprecated
				configurable: false,
				value: function toggleSidebar () {
					this.sidebar.open = !this.sidebar.open;
					localStorage.setItem('sidebar.open', this.sidebar.open);
				}
			},
			visit: {
				configurable: false,
				value: function visit (url, event) {
					if (event) {
						event.stopPropagation();
						event.preventDefault();
					}
					$window.location.href = url;
				}
			},
		});
		/* Support fns */
		function addIngredientToAside (ingredient, arrayName) {
			var arr = $rootScope[arrayName];
			if (findObjIndex(ingredient, arr) == -1) {
				arr.push(ingredient);
				arr.sort(sortByName);
				localStorage.setItem(arrayName, JSON.stringify(arr));
				return true;
			}
		}
		function removeIngredientFromAside (ingredient, arrayName) {
			var arr = $rootScope[arrayName];
			var index = findObjIndex(ingredient, arr);
			if (index != -1) {
				arr.splice(index, 1);
				localStorage.setItem(arrayName, JSON.stringify(arr));
				return true;
			}
			console.warn('Ingredient not found in '+arrayName, ingredient);
		}
		/* Initialization calls */
		while (removeDuplicatesFromAside($rootScope.cabinet)) {}
		while (removeDuplicatesFromAside($rootScope.shoppingList)) {}
		$rootScope.sidebar.open = JSON.parse(localStorage.getItem('sidebar.open')||false);
		$rootScope.isToggled('leftbarOpen');
		$rootScope.isToggled('rightbarOpen');
	}])
	.filter('tipsyFindableClass', function () {
		return function (item) {
			switch (parseInt(item.type)) {
				case window.DRINK:
					return 'drink'; break;
				case window.INGREDIENT:
					return 'ingredient'; break;
				default:
					if (typeof item !== 'string') console.error('Bad type for findable: '+JSON.stringify(item));
			}
		}
	})
	.controller('SplashCtrl', ['$scope', function ($scope) {
		$scope.onSplashScreen = true;
	}])
	;

	function removeDuplicatesFromAside (ingredients) {
		var map = {};
		for (var i in ingredients) {
			var ingredient = ingredients[i];
			if (map[ingredient.id]) {
				ingredients.splice(i,1);
				return true;
			}
			map[ingredient.id] = true;
		}
		return false;
	}
	function findObjIndex (ingredient, array) {
		for (var i in array) {
			if (array[i].id == ingredient.id)
				return i;
		}
		return -1;
	}
	function sortByName (a, b) {
		var nameA = a.name || '';
		var nameB = b.name || '';
		if (nameA < nameB)
			return -1;
		else if (nameA > nameB)
			return 1;
		else
			return 0;
	}
})();

// Bootstrap AngularJS on page load
(function(){
	function boostrapAngularJS () {
		angular.bootstrap(document.body, ['tipsy']);
		attachBootstrapAngularJSCbToPageChange();
	}
	function attachBootstrapAngularJSCbToPageChange () {
		angular.element(document).one('page:change', function () {
			angular.element(this).one('page:load', boostrapAngularJS);
		});
	}
	attachBootstrapAngularJSCbToPageChange();
})();

(function(){
	window.Tipsy.writeMarkdown = function (text) {
		document.write(Markdown.getSanitizingConverter().makeHtml(text));
	}
})();
