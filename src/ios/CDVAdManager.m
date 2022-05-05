
#import <AdSupport/ASIdentifierManager.h>
#import <CommonCrypto/CommonDigest.h>
#import "CDVAdManager.h"
#import "MainViewController.h"
@import GoogleMobileAdsMediationTestSuite;
@interface CDVAdManager()


@property( assign) NSInteger rewardAmount;
@property( assign) NSString* rewardType;

- (void) __setOptions:(NSDictionary*) options;
- (BOOL) __createInterstitial:(NSString *)_iid ;
- (BOOL) __showInterstitial:(BOOL)show;
- (BOOL) __createRewarded:(NSString *)_iid ;
- (BOOL) __showRewarded:(BOOL)show;
- (GADRequest*) __buildAdRequest;
- (NSString *) __getInterstitialId;
- (NSString *) __getRewardedId;
- (NSString *) __getAppOpenId;

- (void)resizeViews;

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

@synthesize interstitialAd;
@synthesize rewardedAd;
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


-(void)showMediationTestSuite:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult;
       [GoogleMobileAdsMediationTestSuite presentOnViewController:self delegate:nil];


        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}
-(void)showAdInspector:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult;
        [GADMobileAds.sharedInstance presentAdInspectorFromViewController:viewController
        completionHandler:^(NSError *error) {
        // Error will be non-nil if there was an issue and the inspector was not displayed.
        }];

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

-(void)showAppOpenAd:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    if (!@available(iOS 13, *)) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Admob does not support iOS 12 and lower. Skipping"] callbackId:callbackId];
        return;
    }
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult;
        
        
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
    if (!@available(iOS 13, *)) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Admob does not support iOS 12 and lower. Skipping"] callbackId:callbackId];
        return;
    }
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult;

        if (!self.interstitialAd) {
            //pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"interstitialAd is null, call requestInterstitialAd first."];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"interstitialAd is null, called requestInterstitialAd."];
            [self requestInterstitialAd:command];
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
    if (!@available(iOS 13, *)) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Admob does not support iOS 12 and lower. Skipping"] callbackId:callbackId];
        return;
    }
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult;
        

        if (!self.rewardedAd) {
            //pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"rewardedAd is null, call requestRewardedAd first."];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"rewardedAd is null, called requestRewardedAd."];
            [self requestRewardedAd:command];
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
        
        if (interstitialAd) {
            [self onAdLoaded:@"interstitial"];
        } else if (!self.interstitialAd) {
            NSString *_iid = [self __getInterstitialId];
            
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

        
        if (self.appOpenAd) {
            [self onAdLoaded:@"app_open"];
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
        
        if (rewardedAd) {
            [self onAdLoaded:@"rewarded"];
        } else if (!self.rewardedAd) {
            NSString *_iid = [self __getRewardedId];
            
            if (![self __createRewarded:_iid ]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Advertising tracking may be disabled. To get test ads on this device, enable advertising tracking."];
            }
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}


- (NSString *) __getInterstitialId {
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

- (BOOL) __createAppOpen:(NSString *)_appOpenId {
    BOOL succeeded = false;
    
    if (self.appOpenAd) {
        self.appOpenAd = nil;
    }
    
    GADRequest *request = [self __buildAdRequest];
    dispatch_async(dispatch_get_main_queue(), ^{
        [GADAppOpenAd loadWithAdUnitID:_appOpenId request:request orientation:UIInterfaceOrientationPortrait completionHandler:^(GADAppOpenAd * _Nullable appOpenAd, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Failed to load app open ad: %@", error);
                [self onAdFailedToLoad:@"app_open"  withError:error];
                return;
            }
            self.appOpenAd.fullScreenContentDelegate = self;
            self.appOpenAd = appOpenAd;
            [self onAdLoaded:@"app_open"];
        }];
    });
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

- (BOOL) __createInterstitial:(NSString *)_iid {
    BOOL succeeded = true;
    
    // Clean up the old interstitial...
    if (self.interstitialAd) {
        self.interstitialAd = nil;
    }

    GADRequest *request = [self __buildAdRequest];
    dispatch_async(dispatch_get_main_queue(), ^{
        [GADInterstitialAd loadWithAdUnitID:_iid request:request completionHandler:^(GADInterstitialAd *ad, NSError *error) {
            if (error) {
                NSLog(@"Failed to load interstitial ad with error: %@", [error localizedDescription]);
                [self onAdFailedToLoad:@"interstitial"  withError:error];
                self.isInterstitialAvailable = false;
                return;
            }
            self.interstitialAd = ad;
            self.interstitialAd.fullScreenContentDelegate = self;
            self.isInterstitialAvailable = true;
            [self onAdLoaded:@"interstitial"];
        }];
    });
  
    return succeeded;
}

- (BOOL) __showInterstitial:(BOOL)show {
    BOOL succeeded = false;
    
    if (!self.interstitialAd) {
        NSString *_iid = [self __getInterstitialId];
        succeeded = [self __createInterstitial:_iid ];
    } else {
        succeeded = true;
    }
    
    if (self.interstitialAd) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.interstitialAd presentFromRootViewController:self.viewController];
        });
    }
    
    return succeeded;
}


- (BOOL) __createRewarded:(NSString *)_iid {
    BOOL succeeded = true;

    if (self.rewardedAd) {
        self.rewardedAd = nil;
    }
    GADRequest *request = [self __buildAdRequest];
    dispatch_async(dispatch_get_main_queue(), ^{
        [GADRewardedAd  loadWithAdUnitID: _iid  request:request  completionHandler:^(GADRewardedAd *ad, NSError *error) {
        if (error) {
          NSLog(@"Rewarded ad failed to load with error: %@", [error localizedDescription]);
          [self onAdFailedToLoad:@"rewarded" withError:error];
          return;
        }
        self.rewardedAd = ad;
        self.rewardedAd.fullScreenContentDelegate = self;
        [self onAdLoaded:@"rewarded"];
      }];
    });

    return succeeded;
}

- (BOOL) __showRewarded:(BOOL)show {
    BOOL succeeded = false;
    
    if (!self.rewardedAd) {
        NSString *_iid = [self __getRewardedId];
        succeeded = [self __createRewarded:_iid ];
    } else {
        succeeded = true;
    }
    
    if (self.rewardedAd) {
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
- (void)onAdLoaded:(NSString *)adType {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *jsString = [NSString stringWithFormat: @"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdLoaded, { 'adType' : '%@' }); }, 1);", adType];
        [self.commandDelegate evalJs:jsString];
    }];
}
- (void)onAdOpened:(NSString *)adType {
    self.rewardAmount = 0;
    self.rewardType = @"";
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *jsString = [NSString stringWithFormat: @"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdOpened, { 'adType' : '%@' }); }, 1);", adType];
        [self.commandDelegate evalJs:jsString];
    }];
}
- (void)onAdFailedToLoad:(NSString *)adType withError:(NSError *) error {
    NSString *reason = [error localizedDescription];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *jsString =
        [NSString stringWithFormat:
        @"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdFailedToLoad, { 'adType' : '%@', 'error': %ld, 'reason': '%@' }); }, 1);"
        ,adType
        ,(long)error.code
        , reason
        ];
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
- (void)onAdClosed:(NSString *)adType {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *jsString =
        [NSString stringWithFormat:
        @"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdClosed, { 'adType' : '%@','rewardType': '%@','rewardAmount': %ld }); }, 1);"
        ,adType
        ,self.rewardType
        ,(long)self.rewardAmount
        ];
        [self.commandDelegate evalJs:jsString];
    }];
    if([adType isEqualToString: @"interstitial"]) self.interstitialAd = nil;
    if([adType isEqualToString: @"rewarded" ]) self.rewardedAd = nil;
    if([adType isEqualToString: @"app_open" ]) self.appOpenAd = nil;
}
- (void)onAdError:(NSString *)adType withError:(NSError *) error {
    NSString *reason = [error localizedDescription];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *jsString =
        [NSString stringWithFormat:
        @"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onError, { 'adType' : '%@', 'error': %ld, 'reason': '%@' }); }, 1);"
        ,adType
        ,(long)error.code
        , reason
        ];
        [self.commandDelegate evalJs:jsString];
    }];
    if([adType isEqualToString: @"interstitial"]) self.interstitialAd = nil;
    if([adType isEqualToString: @"rewarded" ]) self.rewardedAd = nil;
    if([adType isEqualToString: @"app_open" ]) self.appOpenAd = nil;
}

#pragma GADFullScreeContentDelegate implementation

- (void)ad:(nonnull id<GADFullScreenPresentingAd>)ad 
didFailToPresentFullScreenContentWithError:(nonnull NSError *)error {
     NSLog(@"Ad did fail to present full screen content.");
    NSString *adType = @"";
    if([ad isKindOfClass:[GADInterstitialAd class]]) adType = @"interstitial";
    if([ad isKindOfClass:[GADRewardedAd class]]) adType = @"rewarded";
    if([ad isKindOfClass:[GADAppOpenAd class]]) adType = @"app_open";

    [self onAdError:@"rewarded" withError:error];
}

/// Tells the delegate that the ad presented full screen content.
- (void)adDidPresentFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Ad did present full screen content.");
    NSString *adType = @"";
    if([ad isKindOfClass:[GADInterstitialAd class]]) adType = @"interstitial";
    if([ad isKindOfClass:[GADRewardedAd class]]) adType = @"rewarded";
    if([ad isKindOfClass:[GADAppOpenAd class]]) adType = @"app_open";
    [self onAdOpened:adType];
}

/// Tells the delegate that the ad dismissed full screen content.
- (void)adDidDismissFullScreenContent:(nonnull id<GADFullScreenPresentingAd>)ad {
    NSLog(@"Ad did dismiss full screen content.");
    NSString *adType = @"";
    if([ad isKindOfClass:[GADInterstitialAd class]]) adType = @"interstitial";
    if([ad isKindOfClass:[GADRewardedAd class]]) adType = @"rewarded";
    if([ad isKindOfClass:[GADAppOpenAd class]]) adType = @"app_open";
    [self onAdClosed:adType];
}


#pragma mark -


- (void)deviceOrientationChange:(NSNotification *)notification {
   // dispatch_async(dispatch_get_main_queue(), ^{
    //    [self resizeViews];
   // });
}

#pragma mark -
#pragma mark Cleanup

- (void)dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIDeviceOrientationDidChangeNotification
     object:nil];
    
    interstitialAd = nil;
    
    ////rewardedAd.delegate = nil;
    rewardedAd = nil;

    
    adExtras = nil;
}

@end
