package com.jdsoftwarellc.cordova.admob;

import android.app.Activity;
import android.util.Log;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.appopen.AppOpenAd;
import com.google.android.gms.ads.interstitial.InterstitialAd;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;

public class AdMobAppOpenAd {
    public static final String ADMOBADS_LOGTAG = "AdmMobAds";

    private String adType = "app_open";
    private AdManager adManager;
    private AppOpenAd appOpenAd = null;
    private boolean isShowingAd = false;
    //private String appOpenId = "";
    private AppOpenAd.AppOpenAdLoadCallback loadCallback;

    public AdMobAppOpenAd(AdManager admobAds) {
        this.adManager = admobAds;
    }

    private Activity getActivity() {
        return adManager.cordova.getActivity();
    }

    public void loadAd(String adId, CallbackContext callbackContext) {
        if (isAdAvailable()) {
            adManager.onAdLoaded(adType);
            if (callbackContext != null) { callbackContext.success(); }
            return;
        }
        loadCallback = new AppOpenAd.AppOpenAdLoadCallback() {
            @Override
            public void onAdLoaded(AppOpenAd ad) {
                appOpenAd = ad;
                adManager.onAdLoaded(adType);
                if (callbackContext != null) { callbackContext.success();}
            }

            @Override
            public void onAdFailedToLoad(LoadAdError loadAdError) {
                adManager.onAdFailedToLoad(adType, loadAdError);
                if (callbackContext != null) { callbackContext.error(loadAdError);}
            }
        };
        getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                AdRequest request = new AdRequest.Builder().build();
                AppOpenAd.load(getActivity(), adId, request, AppOpenAd.APP_OPEN_AD_ORIENTATION_LANDSCAPE, loadCallback);
            }
        });
    }

    public void showAdIfAvailable(CallbackContext callbackContext) throws Exception {
        if (!isShowingAd && isAdAvailable()) {
            Log.d(ADMOBADS_LOGTAG, "Going to show app open ad");
            FullScreenContentCallback fullScreenContentCallback = new FullScreenContentCallback() {
                @Override
                public void onAdDismissedFullScreenContent() {
                    appOpenAd = null;
                    isShowingAd = false;
                    adManager.onAdClosed(adType,null);
                }

                @Override
                public void onAdFailedToShowFullScreenContent(AdError adError) {
                    appOpenAd = null;
                    isShowingAd = false;
                    adManager.onAdFailedToShowFullScreen(adType,  adError);
                }

                @Override
                public void onAdShowedFullScreenContent() {
                    isShowingAd = true;
                    adManager.onAdOpened(adType);
                }
            };
            getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    appOpenAd.setFullScreenContentCallback(fullScreenContentCallback);
                    appOpenAd.show(getActivity());
                    if (callbackContext != null) {
                        callbackContext.success();
                    }
                }
            });

        } else {
            throw new Exception("Ad not loaded, call request Ad first.");
        }
        return;
    }

    private boolean isAdAvailable() {
        return appOpenAd != null;
    }


}
