
#import <AdSupport/ASIdentifierManager.h>
#import <CommonCrypto/CommonDigest.h>
#import "CDVAdManager.h"
#import "MainViewController.h"

@interface CDVAdManager() 


@property( assign) NSInteger rewardAmount;
@property( assign) NSString* rewardType;

- (void) __setOptions:(NSDictionary*) options;
- (BOOL) __createInterstitial:(NSString *)_iid ;
- (BOOL) __showInterstitial:(BOOL)show;
- (BOOL) __createRewarded:(NSString *)_iid ;
- (BOOL) __showRewarded:(BOOL)show;
- (GADRequest*) __buildAdRequest;
- (NSString *) __admobDeviceID;
- (NSString *) __getPublisherId;
- (NSString *) __getPublisherId:(BOOL)isTappx;
- (NSString *) __getInterstitialId:(BOOL)isBackFill;
- (NSString *) __getRewardedId;
- (NSString *) __getAppOpenId;

- (void)resizeViews;

- (GADAdSize)__adSizeFromString:(NSString *)string;

- (void)deviceOrientationChange:(NSNotification *)notification;

@end

@implementation CDVAdManager

#define INTERSTITIAL                @"interstitial";
#define REWARDED                    @"rewarded";
#define APP_OPEN                    @"app_open";

#define OPT_INTERSTITIAL_ADID       @"interstitialAdId"
#define OPT_REWARDED_ADID           @"rewardedAdId"
#define OPT_APP_OPEN_ADID           @"appOpenAdId"
#define OPT_IS_TESTING              @"isTesting"
#define OPT_AD_EXTRAS               @"adExtras"



@synthesize isInterstitialAvailable;
@synthesize isRewardedAvailable;
@synthesize isAppOpenAvailable;

@synthesize interstitialView;
@synthesize rewardedView;
@synthesize appOpenAd;


@synthesize interstitialAdId,rewardedAdId, appOpenAdId;
@synthesize adExtras;



@synthesize rewardAmount,rewardType;

#pragma mark Cordova JS bridge

- (void)pluginInitialize {
    // These notifications are required for re-placing the ad on orientation
    // changes. Start listening for notifications here since we need to
    // translate the Smart Banner constants according to the orientation.
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(deviceOrientationChange:)
     name:UIDeviceOrientationDidChangeNotification
     object:nil];
    
    interstitialAdId = nil;
    rewardedAdId = nil;
    appOpenAdId = nil;
    
    rewardAmount = 0;
    rewardType = @"";
    
    srand((unsigned)time(NULL));
}


- (void)setOptions:(CDVInvokedUrlCommand *)command {
    CDVPluginResult *pluginResult;
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;
    
    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}


-(void)showAppOpenAd:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult;
        
        if (!self.isAppOpenAvailable && self.appOpenAd) {
            self.appOpenAd = nil;
        }
        
        if (!self.appOpenAd) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"App Open Ad is null, call requestAppOpenAd first."];
        } else {
            if(![self __showAppOpenAd:YES]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Unable to show App Open ad"];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)showInterstitialAd:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult;
        
        if (!isInterstitialAvailable && interstitialView) {
            self.interstitialView.delegate = nil;
            self.interstitialView = nil;
        }
        
        if (!self.interstitialView) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"interstitialAd is null, call requestInterstitialAd first."];
            
        } else {
            if (![self __showInterstitial:YES]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Advertising tracking may be disabled. To get test ads on this device, enable advertising tracking."];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)showRewardedAd:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult;
        
        if (!isRewardedAvailable && rewardedView) {
            ////self.rewardedView.delegate = nil;
            self.rewardedView = nil;
        }
        
        if (!self.rewardedView) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"rewardedView is null, call requestRewardedAd first."];
            
        } else {
            if (![self __showRewarded:YES]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Advertising tracking may be disabled. To get test ads on this device, enable advertising tracking."];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)onAdLoaded:(NSString *)adType {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *jsString = [NSString stringWithFormat: @"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdLoaded, { 'adType' : '%@' }); }, 1);", adType];
        [self.commandDelegate evalJs:jsString];
    }];
}

- (void)onAdFailedToLoad:(NSString *,NSError)adType, error {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *jsString = [NSString stringWithFormat: @"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdFailedToLoad, { 'adType' : '%@','error':'%@' }); }, 1);", adType];
        [self.commandDelegate evalJs:jsString];
    }];
}
- (void)onAdRewarded:(GADAdReward *)reward {
    //Reward the user.
    NSLog(@"rewardedAd:userDidEarnReward:");
    self.rewardAmount = [reward.amount integerValue];
    self.rewardType = reward.type;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *jsString =
        [NSString stringWithFormat:
         @"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdRewarded, { 'adType' : 'rewarded','rewardType': '%@','rewardAmount': %ld }); }, 1);"
         ,self.rewardType
         ,(long)self.rewardAmount
         ];
        [self.commandDelegate evalJs:jsString];
        self.isRewardedAvailable = false;
    }];
}


- (void)requestInterstitialAd:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;
    
    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        
        if (!isInterstitialAvailable && interstitialView) {
            self.interstitialView.delegate = nil;
            self.interstitialView = nil;
        }
        
        if (isInterstitialAvailable) {
            [self onAdLoaded:"interstitial"];
            
        } else if (!self.interstitialView) {
            NSString *_iid = [self __getInterstitialId:false];
            
            if (![self __createInterstitial:_iid ]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Advertising tracking may be disabled. To get test ads on this device, enable advertising tracking."];
            }
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

-(void)requestAppOpenAd:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;
    
    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        if (!self.isAppOpenAvailable && self.appOpenAd) {
            self.appOpenAd = nil;
        }
        
        if (self.isAppOpenAvailable) {
//            
        } else if (!self.appOpenAd) {
            NSString *_iid = [self __getAppOpenId];
            if (![self __createAppOpen:_iid ]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Unable to create App Open ad"];
            }
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)requestRewardedAd:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;
    
    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        
        if (!isRewardedAvailable && rewardedView) {
            ////self.rewardedView.delegate = nil;
            self.rewardedView = nil;
        }
        
        if (isRewardedAvailable) {
              [self onAdLoaded:"rewarded"];
            
        } else if (!self.rewardedView) {
            NSString *_iid = [self __getRewardedId];
            
            if (![self __createRewarded:_iid ]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Advertising tracking may be disabled. To get test ads on this device, enable advertising tracking."];
            }
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}


- (NSString *) __getPublisherId {
    return [self __getPublisherId:hasTappx];
}


- (NSString *) __getInterstitialId:(BOOL)isBackFill {
    NSString *_interstitialAdId = interstitialAdId;
    
    return _interstitialAdId;
}
- (NSString *) __getRewardedId {
    NSString *_rewardedAdId = rewardedAdId;
    
    return _rewardedAdId;
}

- (NSString *) __getAppOpenId {
    NSString *_appOpenAdId = appOpenAdId;
    
    return _appOpenAdId;
}


#pragma mark set Options logic

- (void) __setOptions:(NSDictionary*) options {
    if ((NSNull *)options == [NSNull null]) {
        return;
    }
    
    NSString* str = nil;
    
    str = [options objectForKey:OPT_PUBLISHER_ID];
    if (str && ![str isEqual:[NSNull null]] && [str length] > 0) {
        bannerAdId = str;
    }
    
    str = [options objectForKey:OPT_INTERSTITIAL_ADID];
    if (str && ![str isEqual:[NSNull null]] && [str length] > 0) {
        interstitialAdId = str;
    }
    
    str = [options objectForKey:OPT_REWARDED_ADID];
    if (str && ![str isEqual:[NSNull null]] && [str length] > 0) {
        rewardedAdId = str;
    }
    
    str = [options objectForKey:OPT_APP_OPEN_ADID];
    if (str && ![str isEqual:[NSNull null]] && [str length] > 0) {
        appOpenAdId = str;
    }
    
    NSDictionary* dict = [options objectForKey:OPT_AD_EXTRAS];
    if (dict && ![dict isEqual:[NSNull null]]) {
        adExtras = dict;
    }
    
}
- (GADRequest*) __buildAdRequest {
    GADRequest *request = [GADRequest request];
    
    if (self.adExtras) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            GADExtras *extras = [[GADExtras alloc] init];
            NSMutableDictionary *modifiedExtrasDict =
            [[NSMutableDictionary alloc] initWithDictionary:self.adExtras];
            
            [modifiedExtrasDict removeObjectForKey:@"cordova"];
            [modifiedExtrasDict setValue:@"1" forKey:@"cordova"];
            extras.additionalParameters = modifiedExtrasDict;
            [request registerAdNetworkExtras:extras];
        });
    }
    
    return request;
}

- (BOOL) __createAppOpen:(NSString *)_appOpenId withAdListener:(CDVAdManagerAdListener *) adListener {
    BOOL succeeded = false;
    
    if (self.appOpenAd) {
        self.appOpenAd = nil;
    }
    
    GADRequest *request = [self __buildAdRequest];
    if (!request) {
        succeeded = false;
        if (self.appOpenAd) {
            self.appOpenAd = nil;
        }
    } else {
        [GADAppOpenAd loadWithAdUnitID:_appOpenId request:request orientation:UIInterfaceOrientationPortrait completionHandler:^(GADAppOpenAd * _Nullable appOpenAd, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Failed to load app open ad: %@", error);
                [self onAdFailedToLoad:"app_open" :error];
                return;
            }
            self.appOpenAd.fullScreenContentDelegate = self;
            self.appOpenAd = appOpenAd;
            [self onAdLoaded:"app_open"];
        }];
    }
    return succeeded;
}

- (BOOL) __showAppOpenAd:(BOOL)show {
    BOOL succeeded = false;
    
    if (!self.appOpenAd) {
        NSString *_iid = [self __getAppOpenId];
        succeeded = [self __createAppOpen:_iid ];
        
    } else {
        succeeded = true;
    }
    
    if (self.appOpenAd) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.appOpenAd presentFromRootViewController:self.viewController];
        });
    }
    
    return succeeded;
}

- (BOOL) __createInterstitial:(NSString *)_iid withAdListener:(CDVAdManagerAdListener *) adListener {
    BOOL succeeded = true;
    
    // Clean up the old interstitial...
    if (self.interstitialView) {
        self.interstitialView.delegate = nil;
        self.interstitialView = nil;
    }

    GADRequest *request = [self __buildAdRequest];
    dispatch_async(dispatch_get_main_queue(), ^{
        [GADInterstitialAd loadWithAdUnitID:_iid request:request completionHandler:^(GADInterstitialAd *ad, NSError *error) {
            if (error) {
                NSLog(@"Failed to load interstitial ad with error: %@", [error localizedDescription]);
                [self onAdFailedToLoad:"interstitial" :error];
                self.isInterstitialAvailable = false;
                return;
            }
            self.interstitialView = ad;
            self.interstitialView.fullScreenContentDelegate = self;
            self.isInterstitialAvailable = true;
            [self onAdLoaded:"interstitial"]
        }];
    });
  
    return succeeded;
}

- (BOOL) __showInterstitial:(BOOL)show {
    BOOL succeeded = false;
    
    if (!self.interstitialView) {
        NSString *_iid = [self __getInterstitialId:false];
        
        succeeded = [self __createInterstitial:_iid ];
        
    } else {
        succeeded = true;
    }
    
    if (self.interstitialView && self.interstitialView.isReady) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.interstitialView presentFromRootViewController:self.viewController];
        });
    }
    
    return succeeded;
}


- (BOOL) __createRewarded:(NSString *)_iid withAdListener:(CDVAdManagerAdListener *) adListener {
    BOOL succeeded = true;

    if (self.rewardedView) {
        self.rewardedView = nil;
    }
    GADRequest *request = [self __buildAdRequest];
    dispatch_async(dispatch_get_main_queue(), ^{
        [GADRewardedAd  loadWithAdUnitID: _iid  request:request  completionHandler:^(GADRewardedAd *ad, NSError *error) {
        if (error) {
          NSLog(@"Rewarded ad failed to load with error: %@", [error localizedDescription]);
          [self onAdFailedToLoad:"rewarded" :error];
          return;
        }
        self.rewardedView = ad;
        self.rewardedView.fullScreenContentDelegate = self;
        [self onAdLoaded:"rewarded"]
      }];
    });

    return succeeded;
}

- (BOOL) __showRewarded:(BOOL)show {
    BOOL succeeded = false;
    
    if (!self.rewardedView) {
        NSString *_iid = [self __getRewardedId];
        succeeded = [self __createRewarded:_iid ];
    } else {
        succeeded = true;
    }
    
    if (self.rewardedView && self.rewardedView.isReady) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.rewardedAd presentFromRootViewController:self.viewController userDidEarnRewardHandler:^{
                                  GADAdReward *reward =  self.rewardedAd.adReward;
                                  [self onAdRewarded:reward];
                                }];
        });
    }
    
    return succeeded;
}

//events

/// Tells the delegate that the ad failed to present full screen content.
- (void)ad:(nonnull id<GADFullScreenPresentingAd>)ad 
didFailToPresentFullScreenContentWithError:(nonnull NSError *)error {
    NSString *reason = [error localizedDescription];
    NSLog(@"Admob Ad failed to present full screen content with error %@.", reason);
    adMobAds.isInterstitialAvailable = false;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *jsString =
        [NSString stringWithFormat:
        @"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdFailedToLoad, "
        @"{ 'adType' : 'interstitial', 'error': %ld, 'reason': '%@' }); }, 1);"
        ,(long)error.code
        , reason
        ];
        [self.commandDelegate evalJs:jsString];
    }];
}

/// Tells the delegate that the ad presented full screen content.
- (void)adDidPresentFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Ad did present full screen content.");
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.commandDelegate evalJs:@"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdOpened, { 'adType' : 'rewarded' }); }, 1);"];
    }];
    self.rewardAmount = 0;
    self.rewardType = @"";
}

/// Tells the delegate that the ad dismissed full screen content.
- (void)adDidDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Ad did dismiss full screen content.");
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *jsString =
        [NSString stringWithFormat:
        @"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdClosed, { 'adType' : 'rewarded','rewardType': '%@','rewardAmount': %ld }); }, 1);"
        ,self.rewardType
        ,(long)self.rewardAmount
        ];
        [self.commandDelegate evalJs:jsString];
    }];
}



#pragma mark -


- (void)deviceOrientationChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self resizeViews];
    });
}

#pragma mark -
#pragma mark Cleanup

- (void)dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIDeviceOrientationDidChangeNotification
     object:nil];
    

    interstitialView.delegate = nil;
    interstitialView = nil;
    
    ////rewardedView.delegate = nil;
    rewardedView = nil;

    
    adExtras = nil;
}

@end
