
#import "NSPSelectActuatorViewController.h"
#import "NSPConfigureActionViewController.h"
#import "NSPActuatorController.h"
#import "NSPActuator.h"
#import "NSPActionController.h"
#import "NSPRuleController.h"
#import "Puck.h"
#import "Rule.h"

@interface NSPSelectActuatorViewController ()

@property (nonatomic, strong) Rule *rule;
@property (nonatomic, strong) NSDictionary *actuators;

@end

@implementation NSPSelectActuatorViewController

- (id)initWithRule:(Rule *)rule
{
    self = [super initWithNibName:@"NSPSelectActuatorViewController" bundle:nil];
    if (self) {
        self.title = @"Select actuator";
        self.rule = rule;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self == [self.navigationController.viewControllers objectAtIndex:0]) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                     target:self
                                                                                     action:@selector(close)];
        self.navigationItem.leftBarButtonItem = closeButton;
    }
    
    self.actuators = [NSPActuatorController actuators];
}

- (void)close
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITableViewDelegate + UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.actuators.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    cell.textLabel.text = NSStringFromClass([[self.actuators allValues] objectAtIndex:indexPath.row]);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Class actuatorClass = [[self.actuators allValues] objectAtIndex:indexPath.row];

    NSPConfigureActionViewController *configureActionViewController = [[NSPConfigureActionViewController alloc] initWithRule:self.rule andActuator:actuatorClass];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController pushViewController:configureActionViewController animated:YES];
}

#pragma mark NSObject

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
