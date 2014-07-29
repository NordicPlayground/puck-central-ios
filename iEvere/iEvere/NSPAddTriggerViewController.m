
#import "NSPAddTriggerViewController.h"
#import "NSPSelectActuatorViewController.h"
#import "NSPRuleController.h"
#import "NSPTriggerManager.h"
#import "Puck.h"
#import "Rule.h"
#import "Trigger.h"

@interface NSPAddTriggerViewController ()

@property (nonatomic, strong) Rule *rule;
@property (nonatomic, strong) NSArray *triggers;

@end

@implementation NSPAddTriggerViewController

- (instancetype)initWithRule:(Rule *)rule
{
    self = [super initWithNibName:@"NSPAddTriggerViewController" bundle:nil];
    if (self) {
        self.rule = rule;
        
        self.title = [NSString stringWithFormat:@"Add trigger for %@", rule.puck.name];
        self.triggers = [[NSPTriggerManager sharedManager] triggersForPuck:rule.puck];
        DDLogDebug(@"Did initialize triggers: %@", self.triggers);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark UITableViewDelegate + UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.triggers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    cell.textLabel.text = [(Trigger *)self.triggers[indexPath.row] displayName];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.rule.trigger =[(Trigger *)self.triggers[indexPath.row] identifier];
    NSPSelectActuatorViewController *selectActuatorViewController = [[NSPSelectActuatorViewController alloc] initWithRule:self.rule];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController pushViewController:selectActuatorViewController animated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
