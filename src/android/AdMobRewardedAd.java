package com.jdsoftwarellc.cordova.admob;

import android.app.Activity;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.OnUserEarnedRewardListener;
import com.google.android.gms.ads.appopen.AppOpenAd;
import com.google.android.gms.ads.rewarded.RewardItem;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;

import org.apache.cordova.CallbackContext;

public class AdMobRewardedAd {
    public static final String ADMOBADS_LOGTAG = "AdmMobAds";

    private String adType = "rewarded";
    private AdManager adManager;
    private RewardedAd rewardedAd = null;
    private boolean isShowingAd = false;
    private RewardedAdLoadCallback loadCallback;
    RewardItem rewardItemSave = null;
    public AdMobRewardedAd(AdManager admobAds) {
        this.adManager = admobAds;
    }

    private Activity getActivity() {
        return adManager.cordova.getActivity();
    }

    public void loadAd(String adId, CallbackContext callbackContext) {
        if (isAdAvailable()) {
            adManager.onAdLoaded(adType);
            callbackContext.success();
            return;
        }
        loadCallback = new RewardedAdLoadCallback() {
            @Override
            public void onAdLoaded(@NonNull RewardedAd ad) {
                rewardedAd = ad;
                adManager.onAdLoaded(adType);
            }

            @Override
            public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
                adManager.onAdFailedToLoad(adType,loadAdError);
            }
        };
        getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                AdRequest request = new AdRequest.Builder().build();
                RewardedAd.load(getActivity(), adId, request,loadCallback);
                if (callbackContext != null) {
                    callbackContext.success();
                }
            }
        });
    }

    public void showAdIfAvailable(CallbackContext callbackContext) throws Exception {
        if (!isShowingAd && isAdAvailable()) {
            Log.d(ADMOBADS_LOGTAG, "Going to show app open ad");
            FullScreenContentCallback fullScreenContentCallback = new FullScreenContentCallback() {
                @Override
                public void onAdDismissedFullScreenContent() {
                    rewardedAd = null;
                    isShowingAd = false;
                    adManager.onAdClosed(adType,rewardItemSave);
                }

                @Override
                public void onAdFailedToShowFullScreenContent(AdError adError) {
                    rewardedAd = null;
                    isShowingAd = false;
                    adManager.onAdFailedToShowFullScreen(adType,adError);
                }

                @Override
                public void onAdShowedFullScreenContent() {
                    isShowingAd = true;
                    adManager.onAdOpened(adType);
                }
            };
            //reset rewardItemSave
            rewardItemSave = null;
            OnUserEarnedRewardListener onUserEarnedRewardListener = new OnUserEarnedRewardListener() {
                @Override
                public void onUserEarnedReward(@NonNull RewardItem rewardItem) {
                    // Handle the reward.
                    Log.d(ADMOBADS_LOGTAG, "The user earned the reward.");
                    rewardItemSave = rewardItem;
                    adManager.onRewarded(adType,rewardItem);
                }
            };
            getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    rewardedAd.setFullScreenContentCallback(fullScreenContentCallback);
                    rewardedAd.show(getActivity(),onUserEarnedRewardListener);
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
        return rewardedAd != null;
    }


}
