(function () {
	angular.module('tipsy.rails', [])
	.factory('RailsSupport', [function () {
		var RailsSupport = new Object;
		Object.defineProperties(RailsSupport, {
			errorAlert: {
				configurable: false,
				value: function (objFromRails) {
					var errStrings = [];
					for (key in objFromRails.errors) {
						var array = objFromRails.errors[key];
						array.forEach(function (value, index) {
							errStrings.push(key + ' ' + value);
						});
					}
					alert(errStrings.join("\r\n"));
				}
			},
		});
		return RailsSupport;
	}])
	;
})();
