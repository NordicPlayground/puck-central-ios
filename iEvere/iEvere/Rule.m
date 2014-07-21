
#import "Rule.h"
#import "Puck.h"


@implementation Rule

@dynamic trigger;
@dynamic puck;
@dynamic actions;

- (void)addActionsObject:(Action *)object
{
    self.actions = [self.actions setByAddingObject:object];
}

- (void)addActions:(NSSet *)objects
{
    self.actions = [self.actions setByAddingObjectsFromSet:objects];
}

+ (NSString *)nameForTrigger:(NSPTrigger)trigger
{
    switch (trigger) {
        case NSPTriggerEnterZone:
            return @"Enter zone";
            break;
        case NSPTriggerLeaveZone:
            return @"Leave zone";
            break;
        case NSPTriggerCubeDirectionUP:
            return @"Cube turns up";
            break;
        case NSPTriggerCubeDirectionDOWN:
            return @"Cube turns down";
            break;
        case NSPTriggerCubeDirectionLEFT:
            return @"Cube turns left";
            break;
        case NSPTriggerCubeDirectionRIGHT:
            return @"Cube turns right";
            break;
        case NSPTriggerCubeDirectionBACK:
            return @"Cube turns back";
            break;
        case NSPTriggerCubeDirectionFRONT:
            return @"Cube turns front";
            break;

        default:
            // This is only for the counter of the triggers
            return @"";
            break;
    }
}

@end
