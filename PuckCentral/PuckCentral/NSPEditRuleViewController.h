
@import UIKit;

@class Puck;
@class Rule;

@interface NSPEditRuleViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak) IBOutlet UITableView *tableView;

- (id)initWithRule:(Rule *)rule forPuck:(Puck *)puck;

@end
