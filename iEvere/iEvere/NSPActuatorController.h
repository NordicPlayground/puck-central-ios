
@import Foundation;

#import "NSPActuator.h"

@interface NSPActuatorController : NSObject

+ (NSDictionary *)actuators;
+ (void)actuate:(NSNumber *)actuatorIndex withOptions:(NSDictionary *)options;

@end
