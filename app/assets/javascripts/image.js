(function () {
	angular.module('tipsy.image', [
		'ngAnimate',
		'ngFileUpload',
		'ngTouch',
	])
	.directive('tipsyImageEditor', [function () {
		return {
			restrict: 'E',
			template: '<div ng-show="isFileReaderSupported" style="min-height:700px; position:relative" stop-event="touchend">\n<!-- No NG binding support for file input. Therefore, we attach behaviour in the link fn. --><input type=file ng-hide="file">\n<div ng-show="file"><img style="max-width:900px; max-height:900px;"><div class="overlay"><div class="overlay-inner"></div></div><a class="btn btn-primary btn-tiny" ng-click="triggerSaveImage()" >Save</a></div>\n</div>\n<span ng-hide="isFileReaderSupported">Your browser does not support FileReader, so image uploads are disabled.</span>',
			controller: ['$scope', function ($scope) {
				$scope.file = null;
				$scope.isFileReaderSupported = !!FileReader;
				function getFile () {
					var elem = $scope.$fileInput[0]; // $scope.$fileInput should be set in directive's link function
					return elem.files && elem.files.length && elem.files[0];
				}
				$scope.readFileInput = function () {
					if (FileReader && ($scope.file = getFile())) {
						var reader = new FileReader();
						reader.onload = function () {
							$scope.$imageElem.attr('src', reader.result); // $scope.$fileInput should be set in directive's link function
						}
						var image = $scope.$imageElem[0];
						image.onload = function () {
							image.onload = null; // `delete` wouldn't gc this fast enough, apparently
							$scope.$apply(); // This fn gets triggered by a non-ng event
							$scope.resizeableImage = new ResizeableImage($scope.$imageElem, $scope.options); // provided by ImageResizeCropCanvas: http://tympanus.net/codrops/2014/10/30/resizing-cropping-images-canvas/
						}
						reader.readAsDataURL($scope.file);
					}
				}
				$scope.triggerSaveImage = function () {
					var dataUrl = $scope.resizeableImage.crop();
					$scope.saveImage(dataUrl, $scope.file.name);
				}
			}],
			scope: {
				'saveImage': '='
			},
			link: function (scope, elem, attrs) {
				// No NG binding support for file input. Therefore, we attach behaviour with an onchange attribute.
				scope.$imageElem = elem.find('img');
				scope.$fileInput = elem.find('input');
				scope.$fileInput.on('change', scope.readFileInput);
				scope.options = {
					maxHeight: attrs.maxHeight,
					minHeight: attrs.minHeight,
					maxWidth: attrs.maxWidth,
					minWidth: attrs.minWidth,
				};
			}
		}
	}])
	.factory('TipsyUpload', ['Upload', function (Upload) {
		TipsyUpload = function (config, options) {
			this._config = config;
			if (!config.data) config.data = {};
			this.data = config.data;
			this.options = options || {};
		}
		TipsyUpload.prototype.run = function (files) {
			if (files && files.length) {
				var self = this;
				for (var i = 0; i < files.length; i++) {
					var file = files[i];
					var config = angular.extend({file:file, transformRequest:null}, this._config);
					Upload.upload(config).progress(function (evt) {
						var progressPercentage = parseInt(100.0 * evt.loaded / evt.total);
						console.log('progress: ' + progressPercentage + '% ' + evt.config.file.name);
						if (self.options.progress) self.options.progress(progressPercentage, evt);
					}).success(function (data, status, headers, config) {
						console.log('file ' + config.file.name + 'uploaded. Response: ' + data);
						if (self.options.success) self.options.success(data, status, headers, config);
					}).error(function (data, status, headers, config) {
						console.error('error status: ' + status);
						if (self.options.error) self.options.error(data, status, headers, config);
					})
				}
			}
		};
		return TipsyUpload;
	}])
	.controller('Drink.PhotoUploadCtrl', ['$scope', '$swipe', 'TipsyUpload', 'drink', function ($scope, $swipe, TipsyUpload, drink) {
		// Init vars
		$scope.isFileReaderSupported = !!window.FileReader;
		$scope.uploader = new TipsyUpload({
			url: '/photos.json',
			data: {
				drink_id: drink.id,
			},
		}, {
			progress: function (progress, evt) {
				$scope.uploader.progress = progress;
			},
			success: function (data, status, headers, config) {
				$scope.uploader.success = true;
			},
			error: function (data, status, headers, config) {
				console.error(data);
				// Make array of strings for error messages
				$scope.uploader.errors = [];
				for (var key in data.errors) {
					data.errors[key].forEach(function (str) {
						$scope.uploader.errors.push(key+' '+str);
					});					
				}
			},
		});
		$scope.uploader.progress = 0;
		$scope.saveImage = function () {
			delete $scope.uploader.success;
			delete $scope.uploader.errors;
			$scope.uploader.showCropper = false;
			// make blob from data url
			var dataurl = $scope.getCropperDataUrl();
			var arr = dataurl.split(',');
			var mime = arr[0].match(/:(.*?);/)[1];
			var bstr = atob(arr[1]);
			var n = bstr.length
			var u8arr = new Uint8Array(n);
			while (n--) { u8arr[n] = bstr.charCodeAt(n); }
			var blob = new Blob([u8arr], {type:mime});
			blob.name = $scope.file.name + '.png';
			// upload
			$scope.uploader.run([blob], $scope.uploader.alt);
		}
		// Add callback to file input (b/c ng-change doesn't work on file inputs)
		$scope.$watch('uploader.file', function (newval) {
			if (newval) $scope.fileDropped([newval]);
		});
		// File dropped on drag-and-drop div
		$scope.fileDropped = function (files) {
			if (files && files.length) {
				if (/^image\/.*/.test(files[0].type)) {
					$scope.file = files[0];
					$scope.fileReader = new FileReader();
					$scope.fileReader.onload = function () {
						$scope.$apply();
					}
					$scope.fileReader.readAsDataURL(files[0]);
					$scope.uploader.showCropper = true;
				} else {
					alert('Chosen file must be an image');
				}
			}
		}
	}])
	.controller('Drink.PhotoGalleryCtrl', ['$scope', '$modal', 'Flagger', function ($scope, $modal, Flagger) {
		if (!$scope.drink.$promise) $scope.drink.$promise = $scope.createResolvedPromise();
		$scope.drink.$promise.then(function () {
			if ($scope.drink.photos && $scope.drink.photos.length) {
				// set $scope.photos
				$scope.photos = $scope.drink.photos;
				// set activeUrl for each photo
				$scope.photos.forEach(function (photo) {
					photo.activeUrl = photo.thumb.replace(/thumb/, 'large');
					photo.originalUrl = photo.thumb.replace(/thumb/, 'original');
					// set _isUserFlagged
					$scope.drink.setIsUserFlagged(photo, 'Photo');
					$scope.drink.setUserVoteSign(photo, 'Photo');
				});
				// initilize activeIndex
				$scope.photos.activeIndex = 0;
			}
		});
		// if a current image is the same as requested image
		$scope.isActive = function (index) {
			return $scope.photos.activeIndex == index;
		}
		$scope.getActivePhoto = function getActivePhoto () {
			return $scope.photos[$scope.photos.activeIndex];			
		}
		$scope.isPhotoUserFlagged = function () {
			return $scope.getActivePhoto()._isUserFlagged;
		}
		// show prev image
		$scope.showPrevPhoto = function () {
			$scope.photos.activeIndex = ($scope.photos.activeIndex > 0) ? --$scope.photos.activeIndex : $scope.photos.length - 1;
		};
		// show next image
		$scope.showNextPhoto = function () {
			$scope.photos.activeIndex = ($scope.photos.activeIndex < $scope.photos.length - 1) ? ++$scope.photos.activeIndex : 0;
		};
		// show a certain image
		$scope.showPhoto = function (index) {
			$scope.photos.activeIndex = index;
		};
		// flag active photo
		$scope.flagPhoto = function () {
			if ($scope.requireLoggedIn() && $scope.getActivePhoto()) new Flagger(this, $scope.getActivePhoto(), 'Photo');
		}
		$scope.votePhoto = function (sign) {
			$scope.vote($scope.getActivePhoto(), 'Photo', sign);
		}
	}])
	.controller('Photo.FlagModalCtrl', ['$scope', 'photo', 'Flagger', function ($scope, photo, Flagger) {
		$scope.photo = photo;
		$scope.flagPhoto = function flagPhoto () {
			new Flagger($scope).submitFlag(photo, 'Photo');
		}
	}])
	.controller('User.AvatarModalCtrl', ['$scope', '$http', 'RailsSupport', 'user', function ($scope, $http, RailsSupport, user) {
		$scope.saveImage = function saveImage (dataUrl, filename) {
			if ($scope.requireLoggedIn()) {
				$http.put('/users.json', {user:{photo_data:{data_url:dataUrl, filename:filename}}})
				.success(function(data, status, headers, config){
					$scope.ifUser(function getUserSuccess (data) {
						user.thumbnail = data.photo_url.replace(/original/, 'thumb');
						$scope.$close();
					}, null, true);
				})
				.error(function(data, status, headers, config){
					RailsSupport.errorAlert(data);
				});
			}
		}
	}])
	.directive('tipsyCropper', ['$swipe', function ($swipe) {
		return {
			link: function (scope, elem, attrs) {
				var THRESHOLD = 12;
				var MIN_X = 300;
				var MAX_X = 1280;
				var dragStartState = {};
				scope.$parent.getCropperDataUrl = function () {
					var l = scope.cropper.xCropZone;
					var t = scope.cropper.yCropZone;
					var w = scope.cropper.widthCropZone;
					var h = scope.cropper.heightCropZone;
					var outputW = Math.min(1280, w);
					var outputH = Math.min(720, h);
					var canvas = document.createElement('canvas');
					canvas.getContext('2d').drawImage(elem.find('img')[0], l, t, w, h, 0, 0, outputW, outputH);
					return canvas.toDataURL("image/png");
				}
				// Set position of crop zone
				function moveCropZone (x, y) {
					if (x == null) x = scope.cropperProperEl.offsetWidth / 2;
					if (y == null) y = scope.cropperProperEl.offsetHeight / 2;
					if (x < 0 || y < 0) return;
					scope.cropper.xCropZone = x - scope.cropper.widthCropZone / 2;
					scope.cropper.yCropZone = y - scope.cropper.heightCropZone / 2;
				}
				// Set size of crop zone
				function sizeCropZone (width, height) {
					if (width == null) width = scope.cropperProperEl.offsetWidth / 2;
					if (height == null) height = scope.cropperProperEl.offsetHeight / 2;
					scope.cropper.widthCropZone = width = Math.max(400, width);
					scope.cropper.heightCropZone = width * scope.cropper.ratio[1] / scope.cropper.ratio[0];
				}
				// Either move or resize cropZone in response to touch
				function handleSwipe (coords, isTouchStart) {
					// normalize coords
					var offsets = scope.cropper.offsets = [0,0]
						var el = elem.find('img')[0];
						do {
							offsets[0] += el.scrollLeft - el.offsetLeft;
							offsets[1] += el.scrollTop  - el.offsetTop;
						} while (el = el.parentElement);
					var x = coords.x + scope.cropper.offsets[0];
					var y = coords.y + scope.cropper.offsets[1];
					// Set dragging function if this is a touchstart
					if (isTouchStart) {
						angular.extend(dragStartState, scope.cropper);
						dragStartState.x = x;
						dragStartState.y = y;
						scope.cropper.draggingFn = getResizeFn(x, y) || moveCropZone;
					}
					// Call dragging function
					scope.cropper.draggingFn(x, y);
					scope.$apply(); // this is only needed for $swipe events (for some reason)
				}
				// Either move or resize cropZone in response to mousemove
				function handleMouse (event) {
					console.log('move')
					// normalize coords
					var x = event.clientX;
					var y = event.clientY;
					// Call dragging function
					scope.cropper.draggingFn(x, y);
				}
				// Find border, if any, which is within threshold of coordinates
				function getNearbyBorder(x, y) {
					var left   = scope.cropper.xCropZone;
					var top    = scope.cropper.yCropZone;
					var right  = scope.cropper.xCropZone + scope.cropper.widthCropZone;
					var bottom = scope.cropper.yCropZone + scope.cropper.heightCropZone;
					if (Math.abs(x - right) <= THRESHOLD)
						return 'E';
					else if (Math.abs(x - left) <= THRESHOLD)
						return 'W';
					else if (Math.abs(y - top) <= THRESHOLD)
						return 'N';
					else if (Math.abs(y - bottom) <= THRESHOLD)
						return 'S';
					else
						return false;
				}
				function getResizeFn(x, y) {
					var border = getNearbyBorder(x, y);
					if (!border) return false;
					var left   = scope.cropper.xCropZone;
					var top    = scope.cropper.yCropZone;
					var right  = scope.cropper.xCropZone + scope.cropper.widthCropZone;
					var bottom = scope.cropper.yCropZone + scope.cropper.heightCropZone;
					switch (border) {
						case 'E':
						case 'W':
							if (y > top && y < bottom) {
								var latitudinal = (y > top + scope.cropper.heightCropZone / 2) ? 'S' : 'N';
								return function (x, y) {
									var dx = x - dragStartState.x;
									if (border == 'W') dx *= -1;
									var newWidth = Math.min(Math.max(dragStartState.widthCropZone + dx, MIN_X), MAX_X);
									moveBorders({w:newWidth, dx:dx, isWest:border == 'W', isNorth:latitudinal == 'N'});
								};
							}
							break;
						case 'N':
						case 'S':
							if (x > left && x < right) {
								var longitudinal = (x > left + scope.cropper.widthCropZone / 2) ? 'E' : 'W';
								var maxY = MAX_X * scope.cropper.ratio[1] / scope.cropper.ratio[0];
								var minY = MIN_X * scope.cropper.ratio[1] / scope.cropper.ratio[0];
								return function (x, y) {
									var dy = y - dragStartState.y;
									if (border == 'N') dy *= -1;
									var newHeight = Math.min(Math.max(dragStartState.heightCropZone + dy, minY), maxY);
									moveBorders({h:newHeight, dy:dy, isWest:longitudinal == 'W', isNorth:border == 'N'});
								};
							}
							break;
					}
					return false;
				}
				function moveBorders (opts) { // requires keys of either (w & dx) or (h & dy)
					opts.w  || (opts.w = opts.h * scope.cropper.ratio[0] / scope.cropper.ratio[1]);
					opts.h  || (opts.h = opts.w * scope.cropper.ratio[1] / scope.cropper.ratio[0]);
					opts.dx || (opts.dx = opts.w - dragStartState.widthCropZone);
					opts.dy || (opts.dy = opts.h - dragStartState.heightCropZone);
					if (opts.isWest)  scope.cropper.xCropZone = dragStartState.xCropZone - opts.dx;
					if (opts.isNorth) scope.cropper.yCropZone = dragStartState.yCropZone - opts.dy;
					scope.cropper.widthCropZone  = opts.w;
					scope.cropper.heightCropZone = opts.h;
				}
				// Set scope vars
				scope.$parent.cropper = new Object;
				scope.cropperProperEl = elem.find('#cropper-proper')[0];
				scope.cropper.ratio   = attrs.ratio ? attrs.ratio.split(':') : [16,9];
				sizeCropZone(attrs.widthCropZone, attrs.heightCropZone);
				angular.extend(scope.cropper, {xCropZone:0, yCropZone:0});
				// Attach swipe behaviour to cropper
				$swipe.bind(elem, {
					start: function (coords) {
						scope.cropper.isPressed = true;
						handleSwipe(coords, true);
					},
					move: function (coords) {
						if (scope.cropper.isPressed) handleSwipe(coords);
					},
					end: function (coords) {
						scope.cropper.isPressed = false;
						handleSwipe(coords);
					},
				});
			},
			templateUrl: '/drinks/tipsy-cropper.html'
		}
	}])
	;
})();
