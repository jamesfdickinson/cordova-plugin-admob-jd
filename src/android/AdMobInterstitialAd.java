package com.jdsoftwarellc.cordova.admob;

import android.app.Activity;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;

import org.apache.cordova.CallbackContext;

public class AdMobInterstitialAd {
    public static final String ADMOBADS_LOGTAG = "AdmMobAds";

    private String adType = "interstitial";
    private AdMobAds adManager;
    private InterstitialAd interstitialAd = null;
    private boolean isShowingAd = false;
    //private String appOpenId = "";
    private InterstitialAdLoadCallback loadCallback;

    public AdMobInterstitialAd(AdMobAds admobAds, Activity activity) {
        this.adManager = admobAds;
    }

    private Activity getActivity() {
        return adManager.cordova.getActivity();
    }

    public void loadAd(String adId, CallbackContext callbackContext) {
        if (isAdAvailable()) {
            callbackContext.success();
            return;
        }
        loadCallback = new InterstitialAdLoadCallback() {
            @Override
            public void onAdLoaded(@NonNull InterstitialAd ad) {
                interstitialAd = ad;
                adManager.onAdLoaded(adType);
            }

            @Override
            public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
                adManager.onAdFailedToLoad(adType, loadAdError);
            }
        };
        AdRequest request = new AdRequest.Builder().build();
        InterstitialAd.load(getActivity(), adId, request, loadCallback);
    }

    public void showAdIfAvailable(CallbackContext callbackContext) throws Exception {
        if (!isShowingAd && isAdAvailable()) {
            Log.d(ADMOBADS_LOGTAG, "Going to show app open ad");
            FullScreenContentCallback fullScreenContentCallback = new FullScreenContentCallback() {
                @Override
                public void onAdDismissedFullScreenContent() {
                    interstitialAd = null;
                    isShowingAd = false;
                    adManager.onAdClosed(adType,null);
                }

                @Override
                public void onAdFailedToShowFullScreenContent(AdError adError) {
                    interstitialAd = null;
                    isShowingAd = false;
                    adManager.onAdFailedToShowFullScreen(adType,adError);
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
                    interstitialAd.setFullScreenContentCallback(fullScreenContentCallback);
                    interstitialAd.show(getActivity());
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
        return interstitialAd != null;
    }


}
