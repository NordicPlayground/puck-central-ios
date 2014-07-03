
@import Foundation;

@class Rule;

@interface NSPRuleController : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

+ (NSPRuleController *)sharedController;
- (NSFetchRequest *)fetchRequest;
- (void)conditionalInsertRule:(Rule *)rule;

@end
