
#import "NSPSelectPuckViewController.h"
#import "NSPPuckController.h"
#import "Puck.h"
#import "NSPAddTriggerViewController.h"
#import "NSPRuleController.h"
#import "Rule.h"

@interface NSPSelectPuckViewController ()

@property (nonatomic, strong) NSMutableArray *pucks;
@property (nonatomic, strong) Rule *rule;

@end

@implementation NSPSelectPuckViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Select puck";
        
        NSManagedObjectContext *context = [[NSPRuleController sharedController] managedObjectContext];
        self.rule = [[Rule alloc] initWithEntity:[NSEntityDescription entityForName:@"Rule" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    self.navigationItem.leftBarButtonItem = closeButton;
    
    NSFetchRequest *request = [[NSPPuckController sharedController] fetchRequest];
    
    NSError *error;
    NSMutableArray *mutableFetchResults = [[[[NSPPuckController sharedController] managedObjectContext] executeFetchRequest:request error:&error] mutableCopy];
    if (mutableFetchResults == nil) {
        DDLogError(@"Error fetching pucks %@", error.localizedDescription);
    }
    
    self.pucks = mutableFetchResults;
}

- (void)close
{
    [[[NSPRuleController sharedController] managedObjectContext] deleteObject:self.rule];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.pucks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    Puck *puck = self.pucks[indexPath.row];
    
    cell.textLabel.text = puck.name;
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.rule.puck = self.pucks[indexPath.row];
    NSPAddTriggerViewController *addTriggerViewController = [[NSPAddTriggerViewController alloc] initWithRule:self.rule];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController pushViewController:addTriggerViewController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
