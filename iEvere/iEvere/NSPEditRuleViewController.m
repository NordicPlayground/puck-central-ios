
#import "NSPEditRuleViewController.h"
#import "Rule.h"
#import "Puck.h"
#import "Action.h"
#import "NSPActuatorController.h"
#import "NSPRuleController.h"
#import "NSPSelectActuatorViewController.h"

@interface NSPEditRuleViewController ()

@property (nonatomic, strong) Rule *rule;
@property (nonatomic, strong) Puck *puck;

@end

@implementation NSPEditRuleViewController

- (id)initWithRule:(Rule *)rule forPuck:(Puck *)puck
{
    self = [super initWithNibName:@"NSPEditRuleViewController" bundle:[NSBundle mainBundle]];
    if (self) {
        self.rule = rule;
        self.puck = puck;
        self.title = [NSString stringWithFormat:@"%@: %@", self.puck.name, [Rule nameForTrigger:self.rule.trigger.intValue]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(add)];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)add
{
    NSPSelectActuatorViewController *selectActuatorVC = [[NSPSelectActuatorViewController alloc] initWithRule:self.rule];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:selectActuatorVC];
    
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.rule.actions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.font = [UIFont systemFontOfSize:12.f];
    
    Action *action = [[self.rule.actions allObjects] objectAtIndex:indexPath.row];
    Class actuatorClass = [[NSPActuatorController actuators] objectForKey:action.actuatorId];
    if ([actuatorClass conformsToProtocol:@protocol(NSPActuator)]) {
        id<NSPActuator> actuator = [[actuatorClass alloc] init];
        cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", [actuatorClass name],
         [actuator stringForOptions:[action decodedOptions]]];
    }
    
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSPRuleController *ruleController = [NSPRuleController sharedController];
        NSManagedObject *actionToDelete = self.rule.actions.allObjects[indexPath.row];
        [ruleController.managedObjectContext deleteObject:actionToDelete];
        
        NSMutableOrderedSet *actions = [NSMutableOrderedSet orderedSetWithSet:self.rule.actions];
        [actions removeObjectAtIndex:indexPath.row];
        [self.rule setActions:[actions set]];
         
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        NSError *error;
        if (![ruleController.managedObjectContext save:&error]) {
            NSLog(@"Could not delete");
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark NSObject

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
