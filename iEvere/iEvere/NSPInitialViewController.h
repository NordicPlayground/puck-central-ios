
@import UIKit;

@interface NSPInitialViewController : UIViewController <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *locationPucks;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
