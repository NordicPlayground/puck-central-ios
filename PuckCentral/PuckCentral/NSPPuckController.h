
@import Foundation;

@class Puck;

@interface NSPPuckController : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

+ (NSPPuckController *)sharedController;
- (NSFetchRequest *)fetchRequest;
- (Puck *)insertPuck:(NSString *)name
   withProximityUUID:(NSUUID *)proximityUUID
               major:(NSNumber *)major
               minor:(NSNumber *)minor;

@end
