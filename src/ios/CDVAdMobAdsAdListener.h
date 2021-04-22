
#import <Foundation/Foundation.h>
#import "CDVAdMobAds.h"
#import <GoogleMobileAds/GADBannerViewDelegate.h>
#import <GoogleMobileAds/GADInterstitialDelegate.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <GoogleMobileAds/GADRewardedAdDelegate.h>
#import <GoogleMobileAds/GADExtras.h>

@class CDVAdMobAds;

@interface CDVAdMobAdsAdListener : NSObject <GADRewardedAdDelegate,GADBannerViewDelegate, GADInterstitialDelegate, GADFullScreenPresentingAd> {
    
}

@property (nonatomic, retain) CDVAdMobAds *adMobAds;


- (instancetype)initWithAdMobAds: (CDVAdMobAds *)originalAdMobAds ;
- (void)adViewDidFailedToShow:(GADBannerView *)view;
- (void)interstitialDidFailedToShow:(GADInterstitial *) interstitial;
- (void)rewardedDidFailedToShow:(GADRewardedAd *) rewarded;
- (void)rewardAdDidReceiveAd:(GADRewardedAd *) rewarded;
- (void)appOpenDidReceiveAd:(GADAppOpenAd *)appOpenAd;
@end
