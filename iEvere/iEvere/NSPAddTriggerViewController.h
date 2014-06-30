
@import UIKit;

@class Puck;

@interface NSPAddTriggerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak) IBOutlet UITableView *tableView;

- (id)initWithPuck:(Puck *)puck;

@end
