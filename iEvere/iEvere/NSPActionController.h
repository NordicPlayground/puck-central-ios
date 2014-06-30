
@import Foundation;

@class Action;

@interface NSPActionController : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

+ (NSPActionController *)sharedController;
- (NSFetchRequest *)fetchRequest;
- (Action *)insertAction:(NSNumber *)actuatorId
             withOptions:(NSDictionary *)options;

@end
