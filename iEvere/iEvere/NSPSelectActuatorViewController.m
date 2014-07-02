
#import "NSPSelectActuatorViewController.h"
#import "NSPConfigureActionViewController.h"
#import "NSPActuatorController.h"
#import "NSPActuator.h"
#import "NSPActionController.h"
#import "NSPRuleController.h"
#import "Puck.h"
#import "Rule.h"

@interface NSPSelectActuatorViewController ()

@property (nonatomic, assign) NSPTrigger trigger;
@property (nonatomic, strong) Puck *puck;
@property (nonatomic, strong) NSDictionary *actuators;

@end

@implementation NSPSelectActuatorViewController

- (id)initWithTrigger:(NSPTrigger)trigger andPuck:(Puck *)puck
{
    self = [super initWithNibName:@"NSPSelectActuatorViewController" bundle:nil];
    if (self) {
        self.title = @"Select actuator";
        self.trigger = trigger;
        self.puck = puck;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.actuators = [NSPActuatorController actuators];
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
    id<NSPActuator> actuatorClass = [[self.actuators allValues] objectAtIndex:indexPath.row];

    NSPConfigureActionViewController *configureActionViewController = [[NSPConfigureActionViewController alloc] initWithTrigger:self.trigger andPuck:self.puck andActuator:actuatorClass];

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
