(function () {
	angular.module('tipsy.rails', [])
	.factory('RailsSupport', [function () {
		var RailsSupport = new Object;
		Object.defineProperties(RailsSupport, {
			errorAlert: {
				configurable: false,
				value: function errorAlert (data, status) {
					var statusText;
					var errStrings = [];
					if (!status) {
						status     = data.status;
						statusText = data.statusText;
					}
					if (data && data.data) data = data.data;
					if (statusText) errStrings.push(status.toString()+' '+statusText);
					for (key in data.errors) {
						var array = data.errors[key];
						if (key === 'base') key = '';
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
