
#import "NSPAddTriggerViewController.h"
#import "NSPSelectActuatorViewController.h"
#import "Puck.h"

@interface NSPAddTriggerViewController ()

@property (nonatomic, strong) Puck *puck;

@end

@implementation NSPAddTriggerViewController

- (instancetype)initWithPuck:(Puck *)puck
{
    self = [super initWithNibName:@"NSPAddTriggerViewController" bundle:nil];
    if (self) {
        self.puck = puck;
        
        self.title = [NSString stringWithFormat:@"Add trigger for %@", puck.name];
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
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    switch (indexPath.row) {
        case NSPTriggerEnterZone:
            cell.textLabel.text = @"Enter zone";
            break;
        case NSPTriggerLeaveZone:
            cell.textLabel.text = @"Leave zone";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSPSelectActuatorViewController *selectActuatorViewController = [[NSPSelectActuatorViewController alloc] initWithTrigger:(int)indexPath.row andPuck:self.puck];
    [self.navigationController pushViewController:selectActuatorViewController animated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
