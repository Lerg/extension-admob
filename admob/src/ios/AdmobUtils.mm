#if defined(DM_PLATFORM_IOS)

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "AdmobUtils.h"

@implementation AdmobUtils

+(GADAdSize)stringToBannerSize:(NSString*)value {
	if ([value isEqualToString:@"banner"]) {
		return kGADAdSizeBanner;
	} else if ([value isEqualToString:@"large"]) {
		return kGADAdSizeLargeBanner;
	} else if ([value isEqualToString:@"medium"]) {
		return kGADAdSizeMediumRectangle;
	} else if ([value isEqualToString:@"full"]) {
		return kGADAdSizeFullBanner;
	} else if ([value isEqualToString:@"leaderboard"]) {
		return kGADAdSizeLeaderboard;
	} else if ([value isEqualToString:@"smart_portrait"]) {
		return kGADAdSizeSmartBannerPortrait;
	} else if ([value isEqualToString:@"smart"] || [value isEqualToString:@"smart_landscape"]) {
		return kGADAdSizeSmartBannerLandscape;
	} else {
		return kGADAdSizeBanner;
	}
}

+(NSString*)adRequestErrorCodeToString:(long)error_code {
	switch (error_code) {
		case kGADErrorInvalidRequest:
			return @"The ad request is invalid. The localizedFailureReason error description will have more details. Typically this is because the ad did not have the ad unit ID or root view controller set.";
		case kGADErrorNoFill:
			return @"The ad request was successful, but no ad was returned.";
		case kGADErrorNetworkError:
			return @"There was an error loading data from the network.";
		case kGADErrorServerError:
			return @"The ad server experienced a failure processing the request.";
		case kGADErrorOSVersionTooLow:
			return @"The current device's OS is below the minimum required version.";
		case kGADErrorTimeout:
			return @"The request was unable to be loaded before being timed out.";
		case kGADErrorAdAlreadyUsed:
			return @"Will not send request because the ad object has already been used.";
		case kGADErrorMediationDataError:
			return @"The mediation response was invalid.";
		case kGADErrorMediationAdapterError:
			return @"Error finding or creating a mediation ad network adapter.";
		case kGADErrorMediationInvalidAdSize:
			return @"Attempting to pass an invalid ad size to an adapter.";
		case kGADErrorInternalError:
			return @"Internal error.";
		case kGADErrorInvalidArgument:
			return @"Invalid argument error.";
		case kGADErrorReceivedInvalidResponse:
			return @"Received invalid response.";
	}
	return @"";
}

@end

#endif