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
	.controller('Drink.PhotoUploadCtrl', ['$scope', 'TipsyUpload', 'drink', function ($scope, TipsyUpload, drink) {
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
		$scope.upload = function () {
			delete $scope.uploader.success;
			delete $scope.uploader.errors;
			var files;
			$scope.uploader.run($scope.imgFiles);
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
					$scope.getUser(function getUserSuccess (data) {
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
	;
})();
