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
//= require 'angular/angular.min'
//= require 'angular-resource/angular-resource.min'
//= require 'angular-sanitize/angular-sanitize.min'
//= require 'angular-ui-select/dist/select.min'
//= require turbolinks
//= require_tree .

angular.module('tipsy', [
	'ngResource',
	'ngSanitize',
	'tipsy.find',
	'ui.select'
])
.run(['$rootScope', '$resource', function ($rootScope, $resource) {
	Object.defineProperties($rootScope, {
		getUser: {
			writable: false,
			configurable: false,
			value: function (forceReload) {
				if (forceReload || !$rootScope.currentUser)
					$rootScope.currentUser = $resource('/users/0.json').get();
				window.user = $rootScope.currentUser;
				return $rootScope.currentUser;
			}
		},
		isLoggedIn: {
			writable: false,
			configurable: false,
			value: function (forceReload) {
				return $rootScope.getUser(forceReload).id;
			}
		},
	});
	$rootScope.getUser();
}])
.filter('tipsyFindableClass', function () {
	return function (type) {
		switch (parseInt(type)) {
			case window.DRINK:
				return 'drink'; break;
			case window.INGREDIENT:
				return 'ingredient'; break;
			default:
				console.error('Bad type for findable: '+type);
		}
	}
})
;

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

Object.defineProperties(window, {
	DRINK: {
		value: 0,
		writable: false,
		configurable: false,
	},
	INGREDIENT: {
		value: 1,
		writable: false,
		configurable: false,
	},
});
