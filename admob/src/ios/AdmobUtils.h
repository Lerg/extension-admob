#ifndef Utils_h
#define Utils_h

#import <UIKit/UIKit.h>

@interface AdmobUtils : NSObject
+(GADAdSize)stringToBannerSize:(NSString*)value;
+(NSString*)adRequestErrorCodeToString:(long)error_code;
@end

#endif
