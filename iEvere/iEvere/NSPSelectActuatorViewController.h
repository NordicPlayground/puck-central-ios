
@import UIKit;

@class Puck;

@interface NSPSelectActuatorViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak) IBOutlet UITableView *tableView;

- (id)initWithTrigger:(NSPTrigger)trigger andPuck:(Puck *)puck;

@end
