
var admob = window.admob || {};

/**
 * This enum represents cordova-admob plugin events
 */
admob.events = {
	onAdLoaded: "jd.cordova.admob.onAdLoaded",
	onAdFailedToLoad: "jd.cordova.admob.onAdFailedToLoad",
	onAdOpened: "jd.cordova.admob.onAdOpened",
	onAdLeftApplication: "jd.cordova.admob.onAdLeftApplication",
	onAdClosed: "jd.cordova.admob.onAdClosed",
	onAdRewarded: "jd.cordova.admob.onAdRewarded",
	onAdStarted: "jd.cordova.admob.onAdStarted",
};


// This is not used by the plugin, it is just a helper to show how options are specified and their default values
admob.options = {
	appId: "",
	interstitialAdId: "",
	appOpenAdId: "",
	isTesting: false,
	adExtras: {},
	autoShowInterstitial: true,
	autoShowRewarded: false
};

/**
 * Initialize cordova-admob plugin with options:
 * @param {!Object}    options         AdMob options (use admob.options as template)
 * @param {function()} successCallback Callback on success
 * @param {function()} failureCallback Callback on fail
 */
admob.setOptions = function (options, successCallback, failureCallback) {
	if (typeof options === 'function') {
		failureCallback = successCallback;
		successCallback = options;
		options = undefined;
	}

	// Migrate publisherId => bannerAdId
	if (typeof options === 'object' && options.publisherId != undefined) {
		options.bannerAdId = options.publisherId;
	}

	options = options || admob.DEFAULT_OPTIONS;

	if (typeof options === 'object') {
		cordova.exec(successCallback, failureCallback, 'AdManager', 'setOptions', [options]);

	} else {
		if (typeof failureCallback === 'function') {
			failureCallback('options.appId should be specified.');
		}
	}
};



admob.requestInterstitialAd = function (options, successCallback, failureCallback) {
	if (typeof options === 'function') {
		failureCallback = successCallback;
		successCallback = options;
		options = undefined;
	}
	options = options || {};
	cordova.exec(successCallback, failureCallback, 'AdManager', 'requestInterstitialAd', [options]);
};

/**
 * Shows an interstitial ad. This function should be called when onAdLoaded occurred.
 *
 * @param {function()} successCallback The function to call if the ad was shown successfully.
 * @param {function()} failureCallback The function to call if the ad failed to be shown.
 */
admob.showInterstitialAd = function (successCallback, failureCallback) {
	cordova.exec(successCallback, failureCallback, 'AdManager', 'showInterstitialAd', []);
};

/**
 * Request an AdMob Rewarded ad.
 *
 * @param {!Object}    options         The options used to request an ad. (use admob.options as template)
 * @param {function()} successCallback The function to call if an ad was requested successfully.
 * @param {function()} failureCallback The function to call if an ad failed to be requested.
 */
admob.requestRewardedAd = function (options, successCallback, failureCallback) {
	if (typeof options === 'function') {
		failureCallback = successCallback;
		successCallback = options;
		options = undefined;
	}
	options = options || {};
	cordova.exec(successCallback, failureCallback, 'AdManager', 'requestRewardedAd', [options]);
};

/**
 * Shows an Rewarded ad. This function should be called when onAdLoaded occurred.
 *
 * @param {function()} successCallback The function to call if the ad was shown successfully.
 * @param {function()} failureCallback The function to call if the ad failed to be shown.
 */
admob.showRewardedAd = function (successCallback, failureCallback) {
	cordova.exec(successCallback, failureCallback, 'AdManager', 'showRewardedAd', []);
};


admob.requestAppOpenAd = function (options, successCallback, failureCallback) {
	if (typeof options === 'function') {
		failureCallback = successCallback;
		successCallback = options;
		options = undefined;
	}

	options = options || {};
	cordova.exec(successCallback, failureCallback, 'AdManager', 'requestAppOpenAd', [options]);
};

admob.showAppOpenAd = function (successCallback, failureCallback) {
	cordova.exec(successCallback, failureCallback, 'AdManager', 'showAppOpenAd', [])
};

admob.showMediationTestSuite = function (successCallback, failureCallback) {
	cordova.exec(successCallback, failureCallback, 'AdManager', 'showMediationTestSuite', [])
};


if (typeof module !== 'undefined') {
	// Export admob
	module.exports = admob;
}

window.admob = admob;
