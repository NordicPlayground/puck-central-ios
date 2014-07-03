
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
    }
}

@end
