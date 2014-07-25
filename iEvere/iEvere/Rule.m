
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

@end
