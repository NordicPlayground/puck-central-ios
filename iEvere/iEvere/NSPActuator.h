
@import Foundation;

#import <XLForm/XLForm.h>

@protocol NSPActuator <NSObject>

+ (NSNumber *)index;
+ (NSString *)name;
+ (XLFormDescriptor *)optionsForm;
- (void)actuate:(NSDictionary *)data;
- (NSString *)stringForOptions:(NSDictionary *)options;

@end
