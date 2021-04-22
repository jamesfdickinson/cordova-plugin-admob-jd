

#import <Cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <GoogleMobileAds/GADAdSize.h>
#import <GoogleMobileAds/GADBannerView.h>
#import <GoogleMobileAds/GADInterstitial.h>
#import <GoogleMobileAds/GADBannerViewDelegate.h>
#import <GoogleMobileAds/GADInterstitialDelegate.h>
#import <GoogleMobileAds/GADRewardedAdDelegate.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "CDVAdMobAdsAdListener.h"


#pragma mark - JS requestAd options

@class GADBannerView;
@class GADInterstitial;
@class GADRewardAd;
@class CDVAdMobAdsAdListener;
@class GADAppOpenAd;

#pragma mark AdMobAds Plugin

@interface CDVAdMobAds : CDVPlugin {
}

@property (assign) BOOL isInterstitialAvailable;
@property (assign) BOOL isRewardedAvailable;
@property (assign) BOOL isAppOpenAvailable;

@property (nonatomic, retain) GADBannerView *bannerView;
@property (nonatomic, retain) GADInterstitial *interstitialView;
@property (nonatomic, retain) GADRewardedAd *rewardedView;
@property (nonatomic, retain) GADAppOpenAd* appOpenAd;
@property (nonatomic, retain) CDVAdMobAdsAdListener *adsListener;

@property (nonatomic, retain) NSString* bannerAdId;
@property (nonatomic, retain) NSString* interstitialAdId;
@property (nonatomic, retain) NSString* rewardedAdId;
@property (nonatomic, retain) NSString* appOpenAdId;
@property (nonatomic, retain) NSString* tappxId;

@property (assign) GADAdSize adSize;
@property (assign) BOOL isBannerAtTop;
@property (assign) BOOL isBannerOverlap;
@property (assign) BOOL isOffsetStatusBar;

@property (assign) BOOL isTesting;
@property (nonatomic, retain) NSDictionary* adExtras;

@property (assign) BOOL isBannerVisible;
@property (assign) BOOL isBannerInitialized;
@property (assign) BOOL isBannerShow;
@property (assign) BOOL isBannerAutoShow;
@property (assign) BOOL isInterstitialAutoShow;
@property (assign) BOOL isRewardedAutoShow;
@property (assign) BOOL hasTappx;
@property (assign) double tappxShare;

- (void)setOptions:(CDVInvokedUrlCommand *)command;

- (void)createBannerView:(CDVInvokedUrlCommand *)command;
- (void)showBannerAd:(CDVInvokedUrlCommand *)command;
- (void)destroyBannerView:(CDVInvokedUrlCommand *)command;

- (void)requestInterstitialAd:(CDVInvokedUrlCommand *)command;
- (void)showInterstitialAd:(CDVInvokedUrlCommand *)command;

- (void)requestRewardedAd:(CDVInvokedUrlCommand *)command;
- (void)showRewardedAd:(CDVInvokedUrlCommand *)command;

- (void)requestAppOpenAd:(CDVInvokedUrlCommand *)command;
- (void)showAppOpenAd:(CDVInvokedUrlCommand *)command;

- (void)onBannerAd:(GADBannerView *)adView adListener:(CDVAdMobAdsAdListener *)adListener ;
- (void)onInterstitialAd:(GADInterstitial *)interstitial adListener:(CDVAdMobAdsAdListener *)adListener;
- (void)onRewardedAd:(GADRewardedAd *)rewarded adListener:(CDVAdMobAdsAdListener *)adListener;
- (void)onAppOpenAd:(GADAppOpenAd *)appOpenAd adListener:(CDVAdMobAdsAdListener *)adListener;

@end
