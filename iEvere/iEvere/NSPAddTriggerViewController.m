
#import "NSPAddTriggerViewController.h"
#import "NSPSelectActuatorViewController.h"
#import "NSPRuleController.h"
#import "Puck.h"
#import "Rule.h"

@interface NSPAddTriggerViewController ()

@property (nonatomic, strong) Rule *rule;

@end

@implementation NSPAddTriggerViewController

- (instancetype)initWithRule:(Rule *)rule
{
    self = [super initWithNibName:@"NSPAddTriggerViewController" bundle:nil];
    if (self) {
        self.rule = rule;
        
        self.title = [NSString stringWithFormat:@"Add trigger for %@", rule.puck.name];
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
    return NSPTriggerNumberOfTriggers;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    cell.textLabel.text = [Rule nameForTrigger:(NSPTrigger)indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.rule.trigger = @(indexPath.row);
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
