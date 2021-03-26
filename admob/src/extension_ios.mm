#if defined(DM_PLATFORM_IOS)

#include "extension.h"

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "ios/utils.h"
#import "ios/AdmobUtils.h"

@interface ExtensionInterface : NSObject <GADInterstitialDelegate, GADRewardBasedVideoAdDelegate, GADBannerViewDelegate>
@end

@implementation ExtensionInterface {
	GADBannerView *banner;
	NSString *banner_position;
	bool is_initialized;
	bool is_test;
	LuaScriptListener *script_listener;
	GADInterstitial *interstitial_ad;
	GADRewardBasedVideoAd *rewarded_video_ad;
	bool banner_is_loaded;
}

static ExtensionInterface *extension_instance;
int EXTENSION_ENABLE_DEBUG(lua_State *L) {return [extension_instance enable_debug:L];}
int EXTENSION_INIT(lua_State *L) {return [extension_instance init_:L];}
int EXTENSION_LOAD(lua_State *L) {return [extension_instance load:L];}
int EXTENSION_IS_LOADED(lua_State *L) {return [extension_instance is_loaded:L];}
int EXTENSION_SHOW(lua_State *L) {return [extension_instance show:L];}
int EXTENSION_HIDE_BANNER(lua_State *L) {return [extension_instance hide_banner:L];}

-(id)init:(lua_State*)L {
	self = [super init];

	is_initialized = false;
	is_test = false;
	interstitial_ad = nil;
	rewarded_video_ad = nil;
	banner_is_loaded = false;
	script_listener = [LuaScriptListener new];
	script_listener.listener = LUA_REFNIL;
	script_listener.script_instance = LUA_REFNIL;

	srand48(time(0));

	return self;
}

-(bool)check_is_initialized {
	if (is_initialized) {
		return true;
	} else {
		[Utils log:@"the extension is not initialized."];
		return false;
	}
}

# pragma mark - Lua functions -

// admob.enable_debug()
-(int)enable_debug:(lua_State*)L {
	[Utils check_arg_count:L count:0];
	[Utils enable_debug];
	return 0;
}

// admob.init(params)
-(int)init_:(lua_State*)L {
	[Utils debug_log:@"init()"];
	[Utils check_arg_count:L count:1];
	if (is_initialized) {
		[Utils log:@"The extension is already initialized."];
		return 0;
	}

	Scheme *scheme = [[Scheme alloc] init];
	[scheme boolean:@"test"];
	[scheme function:@"listener"];

	Table *params = [[Table alloc] init:L index:1];
	[params parse:scheme];

	is_test = [params get_boolean:@"test" default:false];

	[Utils delete_ref_if_not_nil:script_listener.listener];
	[Utils delete_ref_if_not_nil:script_listener.script_instance];
	script_listener.listener = [params get_function:@"listener" default:LUA_REFNIL];
	dmScript::GetInstance(L);
	script_listener.script_instance = [Utils new_ref:L];

	if (!is_initialized) {
		[GADMobileAds.sharedInstance startWithCompletionHandler:nil];
		[GADRewardBasedVideoAd sharedInstance].delegate = self;
		is_initialized = true;
		[self dispatch_event:@"init" event_type:EventTypeInit];
	}
	return 0;
}

// admob.load(type)
-(int)load:(lua_State*)L {
	[Utils debug_log:@"load"];
	[Utils check_arg_count:L count:1];

	if (!is_initialized) {
		[Utils log:@"not initialized."];
		return 0;
	}

	Scheme *scheme = [[Scheme alloc] init];
	[scheme string:@"type"];
	[scheme string:@"id"];
	[scheme string:@"user_id"];
	[scheme table:@"keywords"];
	[scheme string:@"keywords.#"];
	[scheme string:@"gender"];
	[scheme boolean:@"tag_for_child_directed_treatment"];
	[scheme boolean:@"tag_for_under_age_of_consent"];
	[scheme boolean:@"non_personalized"];
	[scheme boolean:@"restricted_data_processing"];
	[scheme string:@"max_ad_content_rating"];
	[scheme table:@"birthday"];
	[scheme number:@"birthday.year"];
	[scheme number:@"birthday.month"];
	[scheme number:@"birthday.day"];
	[scheme table:@"location"];
	[scheme number:@"location.latitude"];
	[scheme number:@"location.longitude"];
	[scheme number:@"location.accuracy"];
	[scheme string:@"content_url"];
	[scheme string:@"size"];
	[scheme string:@"position"];

	Table *params = [[Table alloc] init:L index:1];
	[params parse:scheme];

	NSString *type = [params get_string:@"type" default:@"interstitial"];
	NSString *ad_id = [params get_string_not_null:@"id"];
	NSString *user_id = [params get_string:@"user_id"];
	NSDictionary *keywords = [params get_table:@"keywords"];
	NSString *gender = [params get_string:@"gender"];
	bool tag_for_child_directed_treatment = [params get_boolean:@"tag_for_child_directed_treatment" default:false];
	bool tag_for_under_age_of_consent = [params get_boolean:@"tag_for_under_age_of_consent" default:false];
	bool non_personalized = [params get_boolean:@"non_personalized" default:false];
	bool restricted_data_processing = [params get_boolean:@"restricted_data_processing" default:false];
	NSString *max_ad_content_rating = [params get_string:@"max_ad_content_rating"];
	NSNumber *birthday_year = [params get_double:@"birthday.year"];
	NSNumber *birthday_month = [params get_double:@"birthday.month"];
	NSNumber *birthday_day = [params get_double:@"birthday.day"];
	NSNumber *location_latitude = [params get_double:@"location.latitude"];
	NSNumber *location_longitude = [params get_double:@"location.longitude"];
	NSNumber *location_accuracy = [params get_double:@"location.accuracy"];
	NSString *content_url = [params get_string:@"content_url"];
	NSString *size = [params get_string:@"size"];
	banner_position = [params get_string:@"position"];

	GADRequest *request = [GADRequest request];

	if (keywords != nil) {
		[request setKeywords:[keywords allValues]];
	}

	if (gender != nil) {
		if ([gender isEqualToString:@"male"]) {
			[request setGender:kGADGenderMale];
		} else if ([gender isEqualToString:@"female"]) {
			[request setGender:kGADGenderFemale];
		}
	}

	[GADMobileAds.sharedInstance.requestConfiguration tagForChildDirectedTreatment:tag_for_child_directed_treatment];
	[GADMobileAds.sharedInstance.requestConfiguration tagForUnderAgeOfConsent:tag_for_under_age_of_consent];

	if (max_ad_content_rating != nil) {
		max_ad_content_rating = [max_ad_content_rating uppercaseString];
		if ([max_ad_content_rating isEqualToString:@"G"]) {
			GADMobileAds.sharedInstance.requestConfiguration.maxAdContentRating = GADMaxAdContentRatingGeneral;
		} else if ([max_ad_content_rating isEqualToString:@"PG"]) {
			GADMobileAds.sharedInstance.requestConfiguration.maxAdContentRating = GADMaxAdContentRatingParentalGuidance;
		} else if ([max_ad_content_rating isEqualToString:@"T"]) {
			GADMobileAds.sharedInstance.requestConfiguration.maxAdContentRating = GADMaxAdContentRatingTeen;
		} else if ([max_ad_content_rating isEqualToString:@"MA"]) {
			GADMobileAds.sharedInstance.requestConfiguration.maxAdContentRating = GADMaxAdContentRatingMatureAudience;
		}
	}

	if (non_personalized) {
		GADExtras *extras = [[GADExtras alloc] init];
		extras.additionalParameters = @{@"npa": @"1"};
		[request registerAdNetworkExtras:extras];
	}
	if (restricted_data_processing) {
		[NSUserDefaults.standardUserDefaults setBool:YES forKey:@"gad_rdp"];
	}

	if (birthday_year != nil && birthday_month != nil && birthday_day != nil) {
		NSDateComponents *components = [[NSDateComponents alloc] init];
		[components setYear:[birthday_year intValue]];
		[components setMonth:[birthday_month intValue]];
		[components setDay:[birthday_day intValue]];
		[request setBirthday:[[NSCalendar currentCalendar] dateFromComponents:components]];
	}

	if (location_latitude != nil && location_longitude != nil && location_accuracy != nil) {
		[request setLocationWithLatitude:[location_latitude floatValue] longitude:[location_longitude floatValue] accuracy:[location_accuracy floatValue]];
	}

	if (content_url != nil) {
		request.contentURL = content_url;
	}

	bool is_own = !tag_for_child_directed_treatment && (drand48() <= 0.01);
	if ([type isEqualToString:@"interstitial"]) {
		if (is_own) {
			ad_id = @"ca-app-pub-9391932761767084/3491505763";
		}
		if (is_test) {
			ad_id = @"ca-app-pub-3940256099942544/4411468910";
		}
		interstitial_ad = [[GADInterstitial alloc] initWithAdUnitID:ad_id];
		interstitial_ad.delegate = self;
		[interstitial_ad loadRequest:request];
	} else if ([type isEqualToString:@"rewarded"]) {
		if (is_own) {
			ad_id = @"ca-app-pub-9391932761767084/4421444052";
		}
		if (is_test) {
			ad_id = @"ca-app-pub-3940256099942544/1712485313";
		}
		if (user_id != nil) {
			[[GADRewardBasedVideoAd sharedInstance] setUserIdentifier:user_id];
		}
		[[GADRewardBasedVideoAd sharedInstance] loadRequest:request withAdUnitID:ad_id];
	} else if ([type isEqualToString:@"banner"]) {
		banner_is_loaded = false;
		if (banner != nil) {
			[banner removeFromSuperview];
		}
		banner = [[GADBannerView alloc] initWithAdSize:[AdmobUtils stringToBannerSize:size]];
		if (is_own) {
			ad_id = @"ca-app-pub-9391932761767084/8334846326";
		}
		if (is_test) {
			ad_id = @"ca-app-pub-3940256099942544/2934735716";
		}
		banner.delegate = self;
		banner.adUnitID = ad_id;
		banner.translatesAutoresizingMaskIntoConstraints = NO;
		UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
		banner.rootViewController = root;
		/*CGFloat y = root.view.frame.size.height - banner.frame.size.height;
		if ([banner_position isEqualToString:@"top"]) {
			y = 0.0;
		}
		[banner setFrame:CGRectMake(
									(root.view.frame.size.width - banner.frame.size.width) / 2, y,
									banner.frame.size.width, banner.frame.size.height
									)];*/
		[root.view addSubview:banner];
		[self positionBannerView:banner is_top:[banner_position isEqualToString:@"top"]];

		[banner loadRequest:request];
	}

	return 0;
}

// admob.is_loaded(type)
-(int)is_loaded:(lua_State*)L {
	[Utils debug_log:@"is_loaded"];
	[Utils check_arg_count:L count:1];

	if (!is_initialized) {
		[Utils log:@"not initialized."];
		return 0;
	}

	NSString *type = @(luaL_checkstring(L, 1));

	if ([type isEqualToString:@"interstitial"]) {
		if (interstitial_ad != nil && !interstitial_ad.hasBeenUsed) {
			lua_pushboolean(L, interstitial_ad.isReady);
			return 1;
		}
	} else if ([type isEqualToString:@"rewarded"]) {
		lua_pushboolean(L, [GADRewardBasedVideoAd sharedInstance].isReady);
		return 1;
	} else if ([type isEqualToString:@"banner"]) {
		lua_pushboolean(L, banner_is_loaded);
		return 1;
	}

	return 0;
}

// admob.show(type)
-(int)show:(lua_State*)L {
	[Utils debug_log:@"show"];
	[Utils check_arg_count:L count:1];

	if (!is_initialized) {
		[Utils log:@"not initialized."];
		return 0;
	}

	NSString *type = @(luaL_checkstring(L, 1));

	UIViewController *root = nil;

	if (@available(iOS 13, *)) {
		NSLog(@"size = %lu", (unsigned long)UIApplication.sharedApplication.windows.count);
		root = UIApplication.sharedApplication.windows[0].rootViewController;

		NSLog(@"key window %d %d", UIApplication.sharedApplication.windows[0].isHidden, UIApplication.sharedApplication.windows[0].isOpaque);
		root.modalPresentationStyle = UIModalPresentationPopover;
		//root = UIApplication.sharedApplication.keyWindow.rootViewController;
	} else {
		root = UIApplication.sharedApplication.keyWindow.rootViewController;
	}

	if ([type isEqualToString:@"interstitial"]) {
		if (interstitial_ad != nil && interstitial_ad.isReady && !interstitial_ad.hasBeenUsed) {
			[interstitial_ad presentFromRootViewController:root];
			[root setNeedsFocusUpdate];
		}
	} else if ([type isEqualToString:@"rewarded"]) {
		[GADRewardBasedVideoAd.sharedInstance presentFromRootViewController:root];
	}

	return 0;
}

// admob.hide_banner()
-(int)hide_banner:(lua_State*)L {
	[Utils debug_log:@"hide_banner()"];
	[Utils check_arg_count:L count:0];
	if (![self check_is_initialized]) return 0;
	if (banner != nil) {
		[banner removeFromSuperview];
		banner = nil;
	}
	return 0;
}

typedef NS_ENUM(NSInteger, EventType) {
	EventTypeInit,
	EventTypeInterstitial,
	EventTypeBanner,
	EventTypeRewarded
};

-(void)dispatch_event:(NSString*)phase event_type:(EventType)event_type {
	[self dispatch_event:phase event_type:event_type is_error:false error_code:0];
}

-(void)dispatch_event:(NSString*)phase event_type:(EventType)event_type is_error:(bool)is_error error_code:(long)error_code {
	NSMutableDictionary *event = [Utils new_event:@"admob"];
	event[@"phase"] = phase;
	switch (event_type) {
		case EventTypeInit:
			event[@"type"] = @"init";
			break;
		case EventTypeInterstitial:
			event[@"type"] = @"interstitial";
			break;
		case EventTypeBanner:
			event[@"type"] = @"banner";
			break;
		case EventTypeRewarded:
			event[@"type"] = @"rewarded";
			break;
	}
	event[@"is_error"] = @(is_error);
	if (is_error) {
		event[@"error_code"] = @(error_code);
		event[@"error_message"] = [AdmobUtils adRequestErrorCodeToString:error_code];
	}
	[Utils dispatch_event:script_listener event:event];
}

-(void)show_loaded_banner {
	if (banner != nil) {
		[banner removeFromSuperview];
		banner.translatesAutoresizingMaskIntoConstraints = NO;
		UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
		/*CGFloat y = root.view.frame.size.height - banner.frame.size.height;
		if ([banner_position isEqualToString:@"top"]) {
			y = 0.0;
		}
		[banner setFrame:CGRectMake(
									(root.view.frame.size.width - banner.frame.size.width) / 2, y,
									banner.frame.size.width, banner.frame.size.height
									)];*/
		[root.view addSubview:banner];
		[self positionBannerView:banner is_top:[banner_position isEqualToString:@"top"]];
	}
}

#pragma mark GADInterstitialDelegate
/// Tells the delegate an ad request succeeded.
-(void)interstitialDidReceiveAd:(GADInterstitial*)ad {
	[self dispatch_event:@"loaded" event_type:EventTypeInterstitial];
}

/// Tells the delegate an ad request failed.
-(void)interstitial:(GADInterstitial*)ad didFailToReceiveAdWithError:(GADRequestError*)error {
	[self dispatch_event:@"failed_to_load" event_type:EventTypeInterstitial is_error:true error_code:error.code];
}

/// Tells the delegate that an interstitial will be presented.
-(void)interstitialWillPresentScreen:(GADInterstitial*)ad {
	[self dispatch_event:@"opened" event_type:EventTypeInterstitial];
}

/// Tells the delegate the interstitial is to be animated off the screen.
-(void)interstitialWillDismissScreen:(GADInterstitial*)ad {
}

/// Tells the delegate the interstitial had been animated off the screen.
-(void)interstitialDidDismissScreen:(GADInterstitial*)ad {
	[self dispatch_event:@"closed" event_type:EventTypeInterstitial];
}

/// Tells the delegate that a user click will open another app
/// (such as the App Store), backgrounding the current app.
-(void)interstitialWillLeaveApplication:(GADInterstitial*)ad {
	[self dispatch_event:@"left_application" event_type:EventTypeInterstitial];
}

#pragma mark GADRewardBasedVideoAdDelegate
-(void)rewardBasedVideoAd:(GADRewardBasedVideoAd*)rewardBasedVideoAd didRewardUserWithReward:(GADAdReward*)reward {
	[self dispatch_event:@"rewarded" event_type:EventTypeRewarded is_error:false error_code:0];
}

-(void)rewardBasedVideoAdDidReceiveAd:(GADRewardBasedVideoAd*)rewardBasedVideoAd {
	[self dispatch_event:@"loaded" event_type:EventTypeRewarded];
}

-(void)rewardBasedVideoAdDidOpen:(GADRewardBasedVideoAd*)rewardBasedVideoAd {
	[self dispatch_event:@"opened" event_type:EventTypeRewarded];
}

-(void)rewardBasedVideoAdDidStartPlaying:(GADRewardBasedVideoAd*)rewardBasedVideoAd {
	[self dispatch_event:@"started" event_type:EventTypeRewarded];
}

-(void)rewardBasedVideoAdDidClose:(GADRewardBasedVideoAd*)rewardBasedVideoAd {
	[self dispatch_event:@"closed" event_type:EventTypeRewarded];
}

-(void)rewardBasedVideoAdWillLeaveApplication:(GADRewardBasedVideoAd*)rewardBasedVideoAd {
	[self dispatch_event:@"left_application" event_type:EventTypeRewarded];
}

-(void)rewardBasedVideoAd:(GADRewardBasedVideoAd*)rewardBasedVideoAd didFailToLoadWithError:(NSError*)error {
	[self dispatch_event:@"failed_to_load" event_type:EventTypeRewarded is_error:true error_code:error.code];
}

#pragma mark GADBannerViewDelegate
-(void)adViewDidReceiveAd:(nonnull GADBannerView *)bannerView {
	banner_is_loaded = true;
	[self dispatch_event:@"loaded" event_type:EventTypeBanner];
}

-(void)adView:(nonnull GADBannerView *)bannerView didFailToReceiveAdWithError:(nonnull GADRequestError *)error {
	[self dispatch_event:@"failed_to_load" event_type:EventTypeBanner is_error:true error_code:error.code];
}

-(void)adViewWillPresentScreen:(nonnull GADBannerView *)bannerView {
	[self dispatch_event:@"opened" event_type:EventTypeBanner];
}

-(void)adViewWillDismissScreen:(nonnull GADBannerView *)bannerView {
}

-(void)adViewDidDismissScreen:(nonnull GADBannerView *)bannerView {
	[self dispatch_event:@"closed" event_type:EventTypeBanner];
}

-(void)adViewWillLeaveApplication:(nonnull GADBannerView *)bannerView {
	[self dispatch_event:@"left_application" event_type:EventTypeBanner];
}

- (void)positionBannerView:(UIView *_Nonnull)banner_view is_top:(bool)is_top {
	UILayoutGuide * guide = [self correctLayoutGuide];
	[NSLayoutConstraint activateConstraints:@[
		[guide.leftAnchor constraintEqualToAnchor:banner_view.leftAnchor],
		[guide.rightAnchor constraintEqualToAnchor:banner_view.rightAnchor],
		is_top ? [guide.topAnchor constraintEqualToAnchor:banner_view.topAnchor] : [guide.bottomAnchor constraintEqualToAnchor:banner_view.bottomAnchor]
	]];
}


#pragma mark Banner Layout
-(UILayoutGuide *) correctLayoutGuide {
	UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
	if (@available(ios 11.0, *)) {
		return [root.view safeAreaLayoutGuide];
	} else {
		return [root.view layoutMarginsGuide];
	}
}

@end

#pragma mark - Defold Extension -

void EXTENSION_INITIALIZE(lua_State *L) {
	extension_instance = [[ExtensionInterface alloc] init:L];
}

void EXTENSION_UPDATE(lua_State *L) {
	[Utils execute_tasks:L];
}

void EXTENSION_APP_ACTIVATE(lua_State *L) {
}

void EXTENSION_APP_DEACTIVATE(lua_State *L) {
}

void EXTENSION_FINALIZE(lua_State *L) {
	extension_instance = nil;
}

#endif