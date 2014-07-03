
@import UIKit;

@class Rule;

@interface NSPAddTriggerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak) IBOutlet UITableView *tableView;

- (id)initWithRule:(Rule *)rule;

@end
