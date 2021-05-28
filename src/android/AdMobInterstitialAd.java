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
    private AdManager adManager;
    private InterstitialAd interstitialAd = null;
    private boolean isShowingAd = false;
    private String adId = null;
    //private String appOpenId = "";
    private InterstitialAdLoadCallback loadCallback;

    public AdMobInterstitialAd(AdManager admobAds) {
        this.adManager = admobAds;
    }

    private Activity getActivity() {
        return adManager.cordova.getActivity();
    }

    public void loadAd(String adId, CallbackContext callbackContext) {
        this.adId = adId;
        if (isAdAvailable()) {
            adManager.onAdLoaded(adType);
            if (callbackContext != null) { callbackContext.success();}
            return;
        }
        loadCallback = new InterstitialAdLoadCallback() {
            @Override
            public void onAdLoaded(@NonNull InterstitialAd ad) {
                interstitialAd = ad;
                adManager.onAdLoaded(adType);
                if (callbackContext != null) { callbackContext.success();}
            }

            @Override
            public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
                adManager.onAdFailedToLoad(adType, loadAdError);
                if (callbackContext != null) { callbackContext.error(loadAdError.toString());}
            }
        };

        getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                interstitialAd = null;
                AdRequest request = new AdRequest.Builder().build();
                InterstitialAd.load(getActivity(), adId, request, loadCallback);
            }
        });
    }

    public void showAdIfAvailable(CallbackContext callbackContext) throws Exception {
        if(isShowingAd){
            throw new Exception("Ad is currently showing an ad");
        }
        if (isAdAvailable()) {
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

        } else if(!this.isAdAvailable() && this.adId != null){
                this.loadAd(this.adId,callbackContext);
        }else{
            throw new Exception("Ad not loaded, call request Ad first.");
        }
        return;
    }

    private boolean isAdAvailable() {
        return interstitialAd != null;
    }


}
