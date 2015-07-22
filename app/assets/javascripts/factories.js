(function () {
	angular.module('tipsy.factories', [])
	.factory('Differ', [function () {
		var Differ = function (prev, post, options) {
			this.prev = prev||'';
			this.post = post||'';
			if (options) {
				angular.forEach(options, function (val, key) {this[key] = val});
			}
		};
		Object.defineProperties(Differ.prototype, {
			prettyHtml: {
				value: function () {
					var differ = new diff_match_patch();
					var diffs = differ.diff_main(this.prev, this.post);
					differ.diff_cleanupEfficiency(diffs);
					var html = [];
					diffs.forEach(function (diff) {
						var op = diff[0];    // Operation (insert, delete, equal)
						var text = diff[1];  // Text of change.
						switch (op) {
							case DIFF_INSERT:
								if (this.insert != false) html.push('<ins>' + text + '</ins>');
								break;
							case DIFF_DELETE:
								if (this.delete != false) html.push('<del>' + text + '</del>');
								break;
							case DIFF_EQUAL:
								if (this.equal != false) html.push('<span>' + text + '</span>');
								break;
						}
					});
					return html.join('');
				}
			},
			prettyMarkdown: {
				value: function () {
					var converter = Markdown.getSanitizingConverter();
					this.prev = converter.makeHtml(this.prev);
					this.post = converter.makeHtml(this.post);
					return this.prettyHtml(prev, post);
				}
			},
		});
		return Differ;
	}])
	.factory('Flagger', ['$resource', '$modal', function ($resource, $modal) {
		var Flagger = function (parentScope, flaggable, flaggableType, modalOptions) {
			this.flaggable = flaggable;
			this.flaggableType = flaggableType;
			modalOptions = angular.extend({
				animation: true,
				templateUrl: '/flag-modal.html',
				size: 'med',
				scope: angular.extend(parentScope.$new(), {
					flagger: this,
				}),
			}, modalOptions || {});
			this.flagModal = $modal.open(modalOptions);
		};
		Object.defineProperties(Flagger.prototype, {
			createFlag: {
				configurable: false,
				value: function () {
					if (!this.flagMotivation || !this.flagMotivation.trim().length) {
						alert('Please supply text for your flag.');
					}
					else if (confirm("Are you sure you want to submit this flag?")) {
						var thisFlagger = this;
						$resource('/flags.json').save({
							description: this.flagMotivation,
							flaggable_id: this.flaggable.id,
							flaggable_type: this.flaggableType,
						},
						function (data, headers) {
							thisFlagger.flagModal.close();
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
			}
		});
		return Flagger;
	}])
	;
})();
