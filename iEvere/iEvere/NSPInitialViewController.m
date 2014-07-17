
#import "NSPInitialViewController.h"
#import "Puck.h"
#import "NSPPuckController.h"
#import "NSPLocationManager.h"
#import "NSPBluetoothManager.h"
#import "NSPSelectPuckViewController.h"
#import "NSPRuleController.h"
#import "Rule.h"
#import "NSPRuleTableViewCell.h"
#import "NSPEditRuleViewController.h"
#import "NSPServiceUUIDController.h"


@interface NSPInitialViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) Puck *tempPuck;
@property (nonatomic, strong) NSMutableArray *pucks;
@property (nonatomic, strong) NSPLocationManager *locationManager;
@property (nonatomic, strong) NSPBluetoothManager *bluetoothManager;

@property (nonatomic, assign) NSUInteger currentSelectedPuckIndex;

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
    self.bluetoothManager = [NSPBluetoothManager sharedManager];
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
    CLBeacon *tempBeacon = notification.userInfo[@"beacon"];
    Puck *puck = [[NSPPuckController sharedController] insertPuck:nil
                                                withProximityUUID:tempBeacon.proximityUUID
                                                       identifier:nil
                                                            major:tempBeacon.major
                                                            minor:tempBeacon.minor];
    self.tempPuck = puck;
    [self.bluetoothManager findPeripheralFromBeacon:self.tempPuck];
    NSLog(@"userinfo: %@", notification.userInfo);
    NSString *message = [NSString stringWithFormat:@"Add %04X to your beacons", self.tempPuck.minor.intValue];
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
        self.tempPuck.name = name;
        [self.pucks addObject:self.tempPuck];
        [self.tableView reloadData];
    } else {
        [[[NSPPuckController sharedController] managedObjectContext] deleteObject:self.tempPuck];
    }
    [[NSPBluetoothManager sharedManager] stopSearchingForPeripherals];
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
    return puckForSection.rules.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self isLastRow:indexPath]) {
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
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"deleteCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"deleteCell"];
        }
        cell.textLabel.text = @"Remove puck";
        cell.textLabel.textColor = [UIColor redColor];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isLastRow:indexPath]) {
        return 44.f;
    }
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
    if (![self isLastRow:indexPath]) {
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
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
    if ([self isLastRow:indexPath]) {
        self.currentSelectedPuckIndex = indexPath.section;
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:@"Remove puck"
                                                        otherButtonTitles:nil];
        [actionSheet showInView:self.view];
    } else {
        Puck *puck = self.pucks[indexPath.section];
        Rule *rule = puck.rules[indexPath.row];
        NSPEditRuleViewController *editRuleVC = [[NSPEditRuleViewController alloc] initWithRule:rule forPuck:puck];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.navigationController pushViewController:editRuleVC animated:YES];
    }
}

- (BOOL)isLastRow:(NSIndexPath *)indexPath {
    return [[self.pucks[indexPath.section] rules] count] == indexPath.row;
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [[[NSPPuckController sharedController] managedObjectContext] deleteObject:self.pucks[self.currentSelectedPuckIndex]];
        [self.pucks removeObjectAtIndex:self.currentSelectedPuckIndex];
        
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:self.currentSelectedPuckIndex]
                      withRowAnimation:UITableViewRowAnimationTop];
        
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Error: %@", error);
        }
    }
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
