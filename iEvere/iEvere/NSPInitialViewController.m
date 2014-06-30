
#import "NSPInitialViewController.h"
#import "LocationPuck.h"
#import "NSPLocationPuckController.h"
#import "NSPLocationManager.h"

@interface NSPInitialViewController ()

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) CLBeacon *tempBeacon;
@property (nonatomic, strong) NSPLocationManager *locationManager;

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
    
    UIBarButtonItem *beaconButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(restartRanging)];
    
    self.navigationItem.leftBarButtonItem = beaconButton;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"LocationPuck"
                                              inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    
    NSError *error;
    NSMutableArray *mutableFetchResults = [[self.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if (mutableFetchResults == nil) {
        NSLog(@"Error");
    }
    
    self.locationPucks = mutableFetchResults;
    
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

- (void)restartRanging
{
    [self.locationManager forceRestartRanging];
}

- (void)enteredZone:(NSNotification *)notification
{
    self.title = notification.userInfo[@"title"];
}

- (void)didLeaveZone
{
    self.title = @"iEvere";
}

- (void)foundBeacon:(NSNotification *)notification
{
    NSLog(@"Found beacon notification");
    
    self.tempBeacon = notification.userInfo[@"beacon"];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Found new beacon"
                                                        message:@"Add it to your beacons"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Add", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 0) {
        NSString *name = [[alertView textFieldAtIndex:0] text];
        LocationPuck *locationPuck = [[NSPLocationPuckController sharedController] insertPuck:name
                                                                            withProximityUUID:self.tempBeacon.proximityUUID
                                                                                        major:self.tempBeacon.major
                                                                                        minor:self.tempBeacon.minor];
        [self.locationPucks addObject:locationPuck];
        [self.tableView reloadData];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"pucks %ld", self.locationPucks.count);
    return self.locationPucks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    LocationPuck *locationPuck = self.locationPucks[indexPath.row];
    
    NSLog(@"Cell %ld", indexPath.row);
    
    uint16_t minor = [locationPuck.minor integerValue];
    
    cell.textLabel.text = [NSString stringWithFormat:@"Puck: %@, %u", locationPuck.name, minor];
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObject *puckToDelete = self.locationPucks[indexPath.row];
        [self.managedObjectContext deleteObject:puckToDelete];
        
        [self.locationPucks removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Could not delete");
        }
    }
}

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
