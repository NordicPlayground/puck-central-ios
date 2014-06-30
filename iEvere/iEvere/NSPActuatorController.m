
#import "NSPActuatorController.h"
#import "NSPHTTPActuator.h"
#import "NSPActuator.h"

@implementation NSPActuatorController

+ (NSDictionary *)actuators
{
    return @{
             [NSPHTTPActuator index]:[NSPHTTPActuator class]
             };
}

+ (void)actuate:(NSNumber *)actuatorIndex withOptions:(NSDictionary *)options
{
    Class actuatorClass = [[NSPActuatorController actuators] objectForKey:actuatorIndex];
    id<NSPActuator> actuator = [[actuatorClass alloc] init];
    [actuator actuate:options];
}

@end
