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
	;
})();
