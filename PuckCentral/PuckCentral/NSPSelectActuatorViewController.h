
@import UIKit;

@class Rule;

@interface NSPSelectActuatorViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak) IBOutlet UITableView *tableView;

- (id)initWithRule:(Rule *)rule;

@end
