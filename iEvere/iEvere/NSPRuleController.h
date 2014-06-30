
@import Foundation;

@class Rule;
@class Puck;
@class Action;

@interface NSPRuleController : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

+ (NSPRuleController *)sharedController;
- (NSFetchRequest *)fetchRequest;
- (Rule *)insertRuleWithTrigger:(NSNumber *)trigger
                           puck:(Puck *)puck;

@end
