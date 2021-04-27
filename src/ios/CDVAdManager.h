

#import <Cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <GoogleMobileAds/GoogleMobileAds.h>


#pragma mark - JS requestAd options

@class GADInterstitialAd;
@class GADRewardAd;
@class GADAppOpenAd;

#pragma mark AdManager Plugin

@interface CDVAdManager : CDVPlugin <GADFullScreenContentDelegate> {
}

@property (assign) BOOL isInterstitialAvailable;
@property (assign) BOOL isRewardedAvailable;
@property (assign) BOOL isAppOpenAvailable;

@property (nonatomic, retain) GADInterstitialAd  *interstitialAd;
@property (nonatomic, retain) GADRewardedAd *rewardedAd;
@property (nonatomic, retain) GADAppOpenAd* appOpenAd;


@property (nonatomic, retain) NSString* interstitialAdId;
@property (nonatomic, retain) NSString* rewardedAdId;
@property (nonatomic, retain) NSString* appOpenAdId;

@property (nonatomic, retain) NSDictionary* adExtras;

@property (assign) BOOL isInterstitialAutoShow;
@property (assign) BOOL isRewardedAutoShow;


- (void)setOptions:(CDVInvokedUrlCommand *)command;

- (void)requestInterstitialAd:(CDVInvokedUrlCommand *)command;
- (void)showInterstitialAd:(CDVInvokedUrlCommand *)command;

- (void)requestRewardedAd:(CDVInvokedUrlCommand *)command;
- (void)showRewardedAd:(CDVInvokedUrlCommand *)command;

- (void)requestAppOpenAd:(CDVInvokedUrlCommand *)command;
- (void)showAppOpenAd:(CDVInvokedUrlCommand *)command;

- (void)onInterstitialAd:(GADInterstitialAd *)interstitial;
- (void)onRewardedAd:(GADRewardedAd *)rewarded ;
- (void)onAppOpenAd:(GADAppOpenAd *)appOpenAd ;

@end
