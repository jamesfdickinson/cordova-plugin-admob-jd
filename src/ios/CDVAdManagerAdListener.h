
#import <Foundation/Foundation.h>
#import "CDVAdManager.h"
#import <GoogleMobileAds/GADBannerViewDelegate.h>
#import <GoogleMobileAds/GADInterstitialDelegate.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <GoogleMobileAds/GADRewardedAdDelegate.h>
#import <GoogleMobileAds/GADExtras.h>

@class CDVAdManager;

@interface CDVAdManagerAdListener : NSObject <GADRewardedAdDelegate,GADBannerViewDelegate, GADInterstitialDelegate, GADFullScreenPresentingAd> {
    
}

@property (nonatomic, retain) CDVAdManager *adMobAds;


- (instancetype)initWithAdManager: (CDVAdManager *)originalAdManager ;
- (void)adViewDidFailedToShow:(GADBannerView *)view;
- (void)interstitialDidFailedToShow:(GADInterstitial *) interstitial;
- (void)rewardedDidFailedToShow:(GADRewardedAd *) rewarded;
- (void)rewardAdDidReceiveAd:(GADRewardedAd *) rewarded;
- (void)appOpenDidReceiveAd:(GADAppOpenAd *)appOpenAd;
@end
