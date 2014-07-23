
@import Foundation;

#import <XLForm/XLForm.h>

@class Puck;

@protocol NSPActuator <NSObject>

+ (NSNumber *)index;
+ (NSString *)name;
+ (XLFormDescriptor *)optionsForm;
- (NSString *)stringForOptions:(NSDictionary *)options;

@optional
- (void)actuate:(NSDictionary *)options;
- (void)actuateOnPuck:(Puck *)puck withOptions:(NSDictionary *)options;

@end
