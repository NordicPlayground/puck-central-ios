
@import CoreLocation;

#import "NSPLocationPuckController.h"
#import "LocationPuck.h"

@implementation NSPLocationPuckController

+ (NSPLocationPuckController *)sharedController
{
    static NSPLocationPuckController *sharedController;
    
    @synchronized(self) {
        if (!sharedController) {
            sharedController = [[NSPLocationPuckController alloc] init];
        }
        return sharedController;
    }
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"LocationPuck"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"minor" ascending:YES];
    [request setSortDescriptors:@[sortDescriptor]];
    return request;
}

- (LocationPuck *)insertPuck:(NSString *)name
           withProximityUUID:(NSUUID *)proximityUUID
                       major:(NSNumber *)major
                       minor:(NSNumber *)minor
{
    LocationPuck *locationPuck = [NSEntityDescription insertNewObjectForEntityForName:@"LocationPuck" inManagedObjectContext:self.managedObjectContext];
    
    locationPuck.name = name;
    locationPuck.proximityUUID = [proximityUUID UUIDString];
    locationPuck.major = major;
    locationPuck.minor = minor;
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error: %@", error);
    }
    
    return locationPuck;
}


@end
