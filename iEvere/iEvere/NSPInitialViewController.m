
#import "NSPInitialViewController.h"
#import "Puck.h"
#import "NSPPuckController.h"
#import "NSPLocationManager.h"
#import "NSPSelectPuckViewController.h"
#import "NSPRuleController.h"
#import "Rule.h"
#import "NSPRuleTableViewCell.h"
#import "NSPEditRuleViewController.h"


@interface NSPInitialViewController ()

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) CLBeacon *tempBeacon;
@property (nonatomic, strong) NSPLocationManager *locationManager;

@property (nonatomic, strong) NSMutableArray *pucks;

@end

@implementation NSPInitialViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"iEvere";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *beaconButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                  target:self
                                                                                  action:@selector(restartRanging)];
    UIBarButtonItem *addRuleButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(addRule)];
    
    self.navigationItem.leftBarButtonItem = beaconButton;
    self.navigationItem.rightBarButtonItem = addRuleButton;
    
    NSFetchRequest *request = [[NSPPuckController sharedController] fetchRequest];
    NSError *error;
    NSMutableArray *fetchResults = [[[[NSPPuckController sharedController] managedObjectContext] executeFetchRequest:request error:&error] mutableCopy];
    if (fetchResults == nil) {
        NSLog(@"Error %@", error);
    }
    
    self.pucks = fetchResults;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(foundBeacon:)
                                                 name:NSPDidFindNewBeacon
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enteredZone:)
                                                 name:NSPDidEnterZone
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLeaveZone)
                                                 name:NSPDidLeaveZone
                                               object:nil];
    
    self.locationManager = [NSPLocationManager sharedManager];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)restartRanging
{
    [self.locationManager forceRestartRanging];
}

- (void)addRule
{
    NSPSelectPuckViewController *selectPuckViewController = [[NSPSelectPuckViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:selectPuckViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)enteredZone:(NSNotification *)notification
{
    self.title = [notification.userInfo[@"puck"] name];
}

- (void)didLeaveZone
{
    self.title = @"iEvere";
}

- (void)foundBeacon:(NSNotification *)notification
{
    self.tempBeacon = notification.userInfo[@"beacon"];
    NSString *message = [NSString stringWithFormat:@"Add %04X to your beacons", self.tempBeacon.minor.intValue];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Found new beacon"
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Add", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[NSPLocationManager sharedManager] stopLookingForBeacons];
    [alertView show];
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 0) {
        NSString *name = [[alertView textFieldAtIndex:0] text];
        Puck *puck = [[NSPPuckController sharedController] insertPuck:name
                                                    withProximityUUID:self.tempBeacon.proximityUUID
                                                                major:self.tempBeacon.major
                                                                minor:self.tempBeacon.minor];
        [self.pucks addObject:puck];
        [self.tableView reloadData];
    }
    [[NSPLocationManager sharedManager] startLookingForBeacons];
}

#pragma mark UITableViewDelegate + UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.pucks.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    Puck *puckForSection = [self.pucks objectAtIndex:section];
    return puckForSection.rules.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSPRuleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[NSPRuleTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    Puck *puck = self.pucks[indexPath.section];
    Rule *rule = [puck.rules objectAtIndex:indexPath.row];
    
    cell.triggerLabel.text = [NSString stringWithFormat:@"When: %@", [Rule nameForTrigger:rule.trigger.intValue]];
    
    cell.actions = rule.actions.allObjects;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40.f + [[[[self.pucks[indexPath.section] rules] objectAtIndex:indexPath.row] actions] count] * 20.f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.pucks[section] name];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObject *ruleToDelete = [[self.pucks[indexPath.section] rules] objectAtIndex:indexPath.row];
        [self.managedObjectContext deleteObject:ruleToDelete];
        
        NSMutableOrderedSet *rules = [[self.pucks[indexPath.section] rules] mutableCopy];
        [rules removeObjectAtIndex:indexPath.row];
        [self.pucks[indexPath.section] setRules:rules];

        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Could not delete");
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Puck *puck = self.pucks[indexPath.section];
    Rule *rule = puck.rules[indexPath.row];
    NSPEditRuleViewController *editRuleVC = [[NSPEditRuleViewController alloc] initWithRule:rule forPuck:puck];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController pushViewController:editRuleVC animated:YES];
}

#pragma mark NSObject

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPDidFindNewBeacon object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPDidEnterZone object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPDidLeaveZone object:nil];
}

@end
