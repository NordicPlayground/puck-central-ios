
@import Foundation;

@class LocationPuck;

@interface NSPLocationPuckController : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

+ (NSPLocationPuckController *)sharedController;
- (NSFetchRequest *)fetchRequest;
- (LocationPuck *)insertPuck:(NSString *)name
           withProximityUUID:(NSUUID *)proximityUUID
                       major:(NSNumber *)major
                       minor:(NSNumber *)minor;

@end
