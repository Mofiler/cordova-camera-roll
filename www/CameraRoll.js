var exec = require('cordova/exec');

var cameraRoll = {};

cameraRoll.getPhotos = function(successCallback, errorCallback, options) {
  exec(successCallback, errorCallback, "CameraRoll", "getPhotos", []);
};

cameraRoll.saveToCameraRoll = function(imageBase64, successCallback, errorCallback, options) {
  exec(successCallback, errorCallback, "CameraRoll", "saveToCameraRoll", [imageBase64]);
};

cameraRoll.find = function (max, successCallback, errorCallback) {
  if (typeof errorCallback != "function") {
    console.log("CameraRoll.find failure: errorCallback parameter must be a function");
    return
  }

  if (typeof successCallback != "function") {
    console.log("CameraRoll.find failure: successCallback parameter must be a function");
    return
  }
  cordova.exec(successCallback, errorCallback, "CameraRoll", "find", [max]);
};

cameraRoll.getOriginalImage = function(url, successCallback, errorCallback) {
   cordova.exec(successCallback, errorCallback, "CameraRoll", "getOriginalImage", [url]);
};

module.exports = cameraRoll;
