
@import Foundation;

@protocol NSPActuator <NSObject>

+ (NSNumber *)index;
+ (NSString *)name;
- (void)actuate:(NSDictionary *)data;

@end
