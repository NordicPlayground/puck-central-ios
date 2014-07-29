
#import "NSPRuleController.h"
#import "Rule.h"
#import "Action.h"
#import "Puck.h"
#import "Trigger.h"
#import "NSPActuatorController.h"
#import "NSPTriggerManager.h"

@implementation NSPRuleController

+ (NSPRuleController *)sharedController
{
    static NSPRuleController *sharedController;
    
    @synchronized(self) {
        if (!sharedController) {
            sharedController = [[NSPRuleController alloc] init];
        }
        return sharedController;
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(enterZone:)
                                                     name:NSPDidEnterZone
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(leaveZone:)
                                                     name:NSPDidLeaveZone
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cubeChangedDirection:)
                                                     name:NSPTriggerCubeChangedDirection
                                                   object:nil];
    }
    return self;
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Rule"];
    return request;
}

- (void)conditionalInsertRule:(Rule *)rule
{
    NSError *error;
    NSFetchRequest *request = [self fetchRequest];
    request.fetchLimit = 1;
    
    [request setPredicate:[NSPredicate predicateWithFormat:@"self == %@", rule]];
    
    NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
    if (count == NSNotFound) {
        if (error) {
            DDLogError(error.localizedDescription);
        } else {
            if (![self.managedObjectContext save:&error]) {
                DDLogError(error.localizedDescription);
            }
        }
    }
}

- (void)enterZone:(NSNotification *)notification
{
    Puck *puck = notification.userInfo[@"puck"];
    NSArray *triggers = [[NSPTriggerManager sharedManager] triggersForNotification:NSPDidEnterZone];
    [self executeTrigger:triggers[0] withPuck:puck];
}

- (void)leaveZone:(NSNotification *)notification
{
    Puck *puck = notification.userInfo[@"puck"];
    NSArray *triggers = [[NSPTriggerManager sharedManager] triggersForNotification:NSPDidLeaveZone];
    [self executeTrigger:triggers[0] withPuck:puck];
}

- (void)cubeChangedDirection:(NSNotification *)notification
{
    Puck *puck = notification.userInfo[@"puck"];
    NSNumber *direction = notification.userInfo[@"direction"];

    NSArray *triggers = [[NSPTriggerManager sharedManager] triggersForNotification:NSPCubeChangedDirection];

    [self executeTrigger:triggers[[direction intValue]] withPuck:puck];
}

- (void)executeTrigger:(Trigger *)trigger withPuck:(Puck *)puck
{
    NSFetchRequest *request = [self fetchRequest];
    NSArray *predicates = @[
                            [NSPredicate predicateWithFormat:@"trigger == %d", [trigger.identifier intValue]],
                            [NSPredicate predicateWithFormat:@"puck == %@", puck]
                            ];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    
    NSError *error;
    NSArray *rules = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (rules == nil) {
        DDLogError(error.localizedDescription);
    } else if (rules.count > 0) {
        DDLogInfo(@"Execute new trigger! %@, %@", trigger.identifier, puck.name);
        for (Rule *rule in rules) {
            for (Action *action in rule.actions) {
                [NSPActuatorController actuate:action.actuatorId withOptions:[action decodedOptions]];
            }
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
