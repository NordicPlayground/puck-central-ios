
#import "NSPRuleController.h"
#import "Rule.h"
#import "Action.h"
#import "Puck.h"
#import "NSPActuatorController.h"

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
            NSLog(@"Error: %@", error);
        } else {
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Error: %@", error);
            }
        }
    }
}

- (void)enterZone:(NSNotification *)notification
{
    Puck *puck = notification.userInfo[@"puck"];
    [self executeTrigger:NSPTriggerEnterZone withPuck:puck];
}

- (void)leaveZone:(NSNotification *)notification
{
    Puck *puck = notification.userInfo[@"puck"];
    [self executeTrigger:NSPTriggerLeaveZone withPuck:puck];
}

- (void)cubeChangedDirection:(NSNotification *)notification
{
    Puck *puck = notification.userInfo[@"puck"];
    NSNumber *direction = notification.userInfo[@"direction"];

    switch ([direction integerValue]) {
        case NSPCubeDirectionUP:
            [self executeTrigger:NSPTriggerCubeDirectionUP withPuck:puck];
            break;
        case NSPCubeDirectionDOWN:
            [self executeTrigger:NSPTriggerCubeDirectionDOWN withPuck:puck];
            break;
        case NSPCubeDirectionBACK:
            [self executeTrigger:NSPTriggerCubeDirectionBACK withPuck:puck];
            break;
        case NSPCubeDirectionFRONT:
            [self executeTrigger:NSPTriggerCubeDirectionFRONT withPuck:puck];
            break;
        case NSPCubeDirectionLEFT:
            [self executeTrigger:NSPTriggerCubeDirectionLEFT withPuck:puck];
            break;
        case NSPCubeDirectionRIGHT:
            [self executeTrigger:NSPTriggerCubeDirectionRIGHT withPuck:puck];
            break;

        default:
            NSLog(@"Unknown value: %@ for cube puck: %@", direction, puck);
            return;

            break;
    }
}

- (void)executeTrigger:(NSPTrigger)trigger withPuck:(Puck *)puck
{
    NSFetchRequest *request = [self fetchRequest];
    NSArray *predicates = @[
                            [NSPredicate predicateWithFormat:@"trigger == %d", trigger],
                            [NSPredicate predicateWithFormat:@"puck == %@", puck]
                            ];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    
    NSError *error;
    NSArray *rules = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (rules == nil) {
        NSLog(@"Error: %@", error);
    } else if (rules.count > 0) {
        NSLog(@"Execute new trigger! %ld, %@", trigger, puck.name);
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
