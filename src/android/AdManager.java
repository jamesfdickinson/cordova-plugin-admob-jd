package com.jdsoftwarellc.cordova.admob;


import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import android.util.Log;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.rewarded.RewardItem;
import com.google.android.ads.mediationtestsuite.MediationTestSuite;

public class AdManager extends CordovaPlugin {
    public static final String ADMOBADS_LOGTAG = "AdManager";

    /* Cordova Actions. */
    private static final String ACTION_SET_OPTIONS = "setOptions";
    private static final String ACTION_REQUEST_INTERSTITIAL_AD = "requestInterstitialAd";
    private static final String ACTION_SHOW_INTERSTITIAL_AD = "showInterstitialAd";
    private static final String ACTION_REQUEST_REWARDED_AD = "requestRewardedAd";
    private static final String ACTION_SHOW_REWARDED_AD = "showRewardedAd";
    private static final String ACTION_REQUEST_APP_OPEN_AD = "requestAppOpenAd";
    private static final String ACTION_SHOW_APP_OPEN_AD = "showAppOpenAd";
    private static final String ACTION_SHOW_MEDIATION_TEST_SUITE = "showMediationTestSuite";

    
    /* options */
    private static final String OPT_APP_ID = "appId";
    private static final String OPT_PUBLISHER_ID = "publisherId";
    private static final String OPT_INTERSTITIAL_AD_ID = "interstitialAdId";
    private static final String OPT_REWARDED_AD_ID = "rewardedAdId";
    private static final String OPT_APP_OPEN_AD_ID = "appOpenAdId";
    private static final String OPT_IS_TESTING = "isTesting";
    private static final String OPT_AD_EXTRAS = "adExtras";
    private static final String OPT_AUTO_SHOW_INTERSTITIAL = "autoShowInterstitial";
    private static final String OPT_AUTO_SHOW_REWARDED = "autoShowRewarded";
    private static final String OPT_AUTO_SHOW_APPOPEN = "autoShowAppOpen";


    protected boolean isInterstitialAutoShow = true;
    protected boolean isRewardedAutoShow = false;
    protected boolean isAppOpenAutoShow = false;

    private boolean isMobileAdsInitialized = false;


    private String appId = ""; // App ID from AdMob
    private String publisherId = "";

    /**
     * The interstitial ad to display to the user.
     */
    private AdMobInterstitialAd interstitialAd;
    private String interstitialAdId = "";

    /**
     * The reward ad to display to the user.
     */
    private AdMobRewardedAd rewardedAd;
    private String rewardedAdId = "";

    /**
     * The App Open ad to display to the user.
     */
    private AdMobAppOpenAd appOpenAd = null;
    private String appOpenId = "";


    private boolean isTesting = false;
    private JSONObject adExtras = null;

    public AdManager() {
        interstitialAd = new AdMobInterstitialAd(this);
        rewardedAd = new AdMobRewardedAd(this);
        appOpenAd = new AdMobAppOpenAd(this);
    }

    /**
     * Executes the request.
     * <p/>
     * This method is called from the WebView thread.
     * <p/>
     * To do a non-trivial amount of work, use: cordova.getThreadPool().execute(runnable);
     * <p/>
     * To run on the UI thread, use: cordova.getActivity().runOnUiThread(runnable);
     *
     * @param action          The action to execute.
     * @param args            The exec() arguments.
     * @param callbackContext The callback context used when calling back into JavaScript.
     * @return Whether the action was valid.
     */
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        PluginResult result = null;
        if (ACTION_SET_OPTIONS.equals(action)) {
            JSONObject options = args.optJSONObject(0);
            result = executeSetOptions(options, callbackContext);
        } else if (ACTION_REQUEST_INTERSTITIAL_AD.equals(action)) {
            JSONObject options = args.optJSONObject(0);
            result = executeRequestInterstitialAd(options, callbackContext);
        } else if (ACTION_SHOW_INTERSTITIAL_AD.equals(action)) {
            result = executeShowInterstitialAd(callbackContext);
        } else if (ACTION_REQUEST_REWARDED_AD.equals(action)) {
            JSONObject options = args.optJSONObject(0);
            result = executeRequestRewardedAd(options, callbackContext);
        } else if (ACTION_SHOW_REWARDED_AD.equals(action)) {
            result = executeShowRewardedAd(callbackContext);
        } else if (ACTION_REQUEST_APP_OPEN_AD.equals(action)) {
            JSONObject options = args.optJSONObject(0);
            result = executeRequestAppOpenAd(options, callbackContext);
        } else if (ACTION_SHOW_APP_OPEN_AD.equals(action)) {
            result = executeShowAppOpenAd(callbackContext);
        } else if (ACTION_SHOW_MEDIATION_TEST_SUITE.equals(action)) {
            result = executeShowMediationTestSuite(callbackContext);
        } else {
            Log.d(ADMOBADS_LOGTAG, String.format("Invalid action passed: %s", action));
            return false;
        }

        if (result != null) {
            callbackContext.sendPluginResult(result);
        }

        return true;
    }

    private PluginResult executeSetOptions(JSONObject options, CallbackContext callbackContext) {
        Log.w(ADMOBADS_LOGTAG, "executeSetOptions");
        this.setOptions(options);
        callbackContext.success();
        return null;
    }

    private void setOptions(JSONObject options) {
        if (options == null) {
            return;
        }
        if (options.has(OPT_APP_ID)) {
            this.appId = options.optString(OPT_APP_ID);
        }
        if (options.has(OPT_PUBLISHER_ID)) {
            this.publisherId = options.optString(OPT_PUBLISHER_ID);
        }
        if (options.has(OPT_INTERSTITIAL_AD_ID)) {
            this.interstitialAdId = options.optString(OPT_INTERSTITIAL_AD_ID);
        }
        if (options.has(OPT_REWARDED_AD_ID)) {
            this.rewardedAdId = options.optString(OPT_REWARDED_AD_ID);
        }
        if (options.has(OPT_APP_OPEN_AD_ID)) {
            this.appOpenId = options.optString(OPT_APP_OPEN_AD_ID);
        }
        if (options.has(OPT_IS_TESTING)) {
            this.isTesting = options.optBoolean(OPT_IS_TESTING);
        }
        if (options.has(OPT_AD_EXTRAS)) {
            this.adExtras = options.optJSONObject(OPT_AD_EXTRAS);
        }
        if (options.has(OPT_AUTO_SHOW_INTERSTITIAL)) {
            this.isInterstitialAutoShow = options.optBoolean(OPT_AUTO_SHOW_INTERSTITIAL);
        }
        if (options.has(OPT_AUTO_SHOW_REWARDED)) {
            this.isRewardedAutoShow = options.optBoolean(OPT_AUTO_SHOW_REWARDED);
        }
        if (options.has(OPT_AUTO_SHOW_APPOPEN)) {
            this.isAppOpenAutoShow = options.optBoolean(OPT_AUTO_SHOW_APPOPEN);
        }
    }

    private void initializeMobileAds() {
        if (!isMobileAdsInitialized) {
            MobileAds.initialize(cordova.getActivity(), initializationStatus -> {
            });
            isMobileAdsInitialized = true;
        }
    }


    ///////////////////Interstitial Ad///////////////////////

    private PluginResult executeRequestInterstitialAd(JSONObject options, CallbackContext callbackContext) {
        initializeMobileAds();
        setOptions(options);
        try {
            interstitialAd.loadAd(interstitialAdId, callbackContext);
        } catch (Exception ex) {
            return new PluginResult(Status.ERROR, "Request interstitialAd failed. " + ex);
        }
        return null;
    }

    private PluginResult executeShowInterstitialAd(CallbackContext callbackContext) {
        try {
            interstitialAd.showAdIfAvailable(callbackContext);
        } catch (Exception ex) {
            return new PluginResult(Status.ERROR, "interstitialAd not loaded, call request first. " + ex);
        }
        return null;
    }

    ///////////////////App Open Ad///////////////////////

    private PluginResult executeRequestAppOpenAd(JSONObject options, CallbackContext callbackContext) {
        initializeMobileAds();
        setOptions(options);
        try {
            appOpenAd.loadAd(appOpenId, callbackContext);
        } catch (Exception ex) {
            return new PluginResult(Status.ERROR, "Request AppOpenAd failed. " + ex);
        }
        return null;
    }

    private PluginResult executeShowAppOpenAd(CallbackContext callbackContext) {
        try {
            appOpenAd.showAdIfAvailable(callbackContext);
        } catch (Exception ex) {
            return new PluginResult(Status.ERROR, "App Open Ad not loaded, call request first. " + ex);
        }
        return null;
    }

    ///////////////////Rewarded Ads///////////////////////
    private PluginResult executeRequestRewardedAd(JSONObject options, CallbackContext callbackContext) {
        initializeMobileAds();
        setOptions(options);
        try {
            rewardedAd.loadAd(rewardedAdId, callbackContext);
        } catch (Exception ex) {
            return new PluginResult(Status.ERROR, "Request AppOpenAd failed. " + ex);
        }
        return null;
    }

    private PluginResult executeShowRewardedAd(CallbackContext callbackContext) {
        try {
            rewardedAd.showAdIfAvailable(callbackContext);
        } catch (Exception ex) {
            return new PluginResult(Status.ERROR, "App Open Ad not loaded, call request first. " + ex);
        }
        return null;
    }
    private PluginResult executeShowMediationTestSuite(CallbackContext callbackContext) {
        try {
            MediationTestSuite.launch(this.cordova.getActivity());
        } catch (Exception ex) {
            return new PluginResult(Status.ERROR, "ShowMediationTestSuite Error. " + ex);
        }
        return null;
    }
   
    ///////////////////Events///////////////////////
    @Override
    public void onPause(boolean multitasking) {
        super.onPause(multitasking);
    }

    @Override
    public void onResume(boolean multitasking) {
        super.onResume(multitasking);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
    }

    public void onAdLoaded(String adType) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Log.d(ADMOBADS_LOGTAG, adType + ": ad loaded");
                String event = String.format("javascript:cordova.fireDocumentEvent(admob.events.onAdLoaded, { 'adType': '%s' });", adType);
                webView.loadUrl(event);
            }
        });
    }

    public void onAdFailedToLoad(String adType,  AdError adError) {
        int code = adError.getCode();
        String reason = adError.getMessage();
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Log.d(ADMOBADS_LOGTAG, adType + ": failed to load ad (" + reason + ")");
                String event = String.format("javascript:cordova.fireDocumentEvent(admob.events.onAdFailedToLoad, { 'adType': '%s', 'error': %d, 'reason': '%s' });", adType, code, reason);
                webView.loadUrl(event);
            }
        });
    }
    public void onAdFailedToShowFullScreen(String adType,  AdError adError) {
        int code = adError.getCode();
        String reason = adError.getMessage();
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Log.d(ADMOBADS_LOGTAG, adType + ": failed to load ad (" + reason + ")");
                String event = String.format("javascript:cordova.fireDocumentEvent(admob.events.onAdError, { 'adType': '%s', 'error': %d, 'reason': '%s' });", adType, code, reason);
                webView.loadUrl(event);
            }
        });
    }
    public void onAdOpened(String adType) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Log.d(ADMOBADS_LOGTAG, adType + ": ad opened");
                String event = String.format("javascript:cordova.fireDocumentEvent(admob.events.onAdOpened, { 'adType': '%s' });", adType);
                webView.loadUrl(event);
            }
        });
    }

    public void onAdClosed(String adType, RewardItem reward) {
        final String rewardType = reward.getType();
        final int rewardAmount = reward.getAmount();
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Log.d(ADMOBADS_LOGTAG, adType + ": ad closed after clicking on it");
                String event = String.format("javascript:cordova.fireDocumentEvent(admob.events.onAdClosed, { 'adType': '%s','rewardType': '%s','rewardAmount': %d });", adType,rewardType,rewardAmount);
                webView.loadUrl(event);
            }
        });
    }

    public void onRewarded(String adType, RewardItem reward) {
        final String rewardType = reward.getType();
        final int rewardAmount = reward.getAmount();

        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Log.d(ADMOBADS_LOGTAG, adType + ": ad rewarded : "+rewardType+ " "+ rewardAmount);
                String event = String.format("javascript:cordova.fireDocumentEvent(admob.events.onAdRewarded, { 'adType': '%s','rewardType': '%s','rewardAmount': %d });", adType,rewardType,rewardAmount);
                webView.loadUrl(event);
            }
        });
    }

    /**
     * Gets a string error reason from an error code.
     */
    public String getErrorReason(int errorCode) {
        String errorReason = "Unknown";
        switch (errorCode) {
            case AdRequest.ERROR_CODE_INTERNAL_ERROR:
                errorReason = "Internal error";
                break;
            case AdRequest.ERROR_CODE_INVALID_REQUEST:
                errorReason = "Invalid request";
                break;
            case AdRequest.ERROR_CODE_NETWORK_ERROR:
                errorReason = "Network Error";
                break;
            case AdRequest.ERROR_CODE_NO_FILL:
                errorReason = "No fill";
                break;
        }
        return errorReason;
    }

}
