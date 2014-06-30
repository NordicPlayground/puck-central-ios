
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
                                                 selector:@selector(leaveZone)
                                                     name:NSPDidLeaveZone
                                                   object:nil];
    }
    return self;
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Rule"];
    return request;
}

- (Rule *)insertRuleWithTrigger:(NSNumber *)trigger
                           puck:(Puck *)puck
{
    Rule *rule = [NSEntityDescription insertNewObjectForEntityForName:@"Rule"
                                               inManagedObjectContext:self.managedObjectContext];
    
    rule.trigger = trigger;
    rule.puck = puck;
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error: %@", error);
    }
    
    NSLog(@"Inserted");
    
    return rule;
}

- (void)enterZone:(NSNotification *)notification
{
    NSFetchRequest *request = [self fetchRequest];
    
    Puck *puck = notification.userInfo[@"puck"];
    
    NSArray *predicates = @[
                            [NSPredicate predicateWithFormat:@"trigger == %d", 0],
                            [NSPredicate predicateWithFormat:@"puck == %@", puck]
                            ];
    
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    
    NSError *error;
    NSArray *rules = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (rules == nil) {
        NSLog(@"Error: %@", error);
    } else {
        for (Rule *rule in rules) {
            for (Action *action in rule.actions) {
                NSData *jsonData = [action.options dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error;
                NSDictionary *parsedOptions = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
                if (error) {
                    NSLog(@"Error: %@", error);
                }
                [NSPActuatorController actuate:action.actuatorId withOptions:parsedOptions];
            }
        }
    }
}

- (void)leaveZone
{
    NSLog(@"Leave zone trigger");
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
