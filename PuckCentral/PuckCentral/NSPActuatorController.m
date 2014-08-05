
#import "NSPActuatorController.h"
#import "NSPHTTPActuator.h"
#import "NSPIRActuator.h"
#import "NSPMusicActuator.h"
#import "NSPDisplayActuator.h"
#import "NSPActuator.h"
#import "NSPPuckController.h"

@implementation NSPActuatorController

+ (NSDictionary *)actuators
{
    return @{
             [NSPHTTPActuator index]:[NSPHTTPActuator class],
             [NSPIRActuator index]: [NSPIRActuator class],
             [NSPMusicActuator index]:[NSPMusicActuator class],
             [NSPDisplayActuator index]:[NSPDisplayActuator class]
             };
}

+ (void)actuate:(NSNumber *)actuatorIndex withOptions:(NSDictionary *)options
{
    Class actuatorClass = [[NSPActuatorController actuators] objectForKey:actuatorIndex];
    id<NSPActuator> actuator = [[actuatorClass alloc] init];
    
    if ([actuator respondsToSelector:@selector(actuateOnPuck:withOptions:)]) {
        Puck *puck = nil;

        NSError *error;
        NSFetchRequest *req = [[NSPPuckController sharedController] fetchRequest];
        req.predicate = [NSPredicate predicateWithFormat:@"minor == %@", options[@"minor"]];
        req.fetchLimit = 1;
        NSArray *result = [[[NSPPuckController sharedController] managedObjectContext] executeFetchRequest:req error:&error];
        if (error) {
            DDLogError(error.localizedDescription);
        } else if (result.count > 0) {
            puck = result[0];
            [actuator actuateOnPuck:puck withOptions:options];
        }
    } else if ([actuator respondsToSelector:@selector(actuate:)]) {
        [actuator actuate:options];
    }
}

@end
