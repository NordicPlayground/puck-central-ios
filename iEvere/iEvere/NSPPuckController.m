
@import CoreLocation;

#import "NSPPuckController.h"
#import "Puck.h"
#import "NSPServiceUUIDController.h"

@implementation NSPPuckController

+ (NSPPuckController *)sharedController
{
    static NSPPuckController *sharedController;
    
    @synchronized(self) {
        if (!sharedController) {
            sharedController = [[NSPPuckController alloc] init];
        }
        return sharedController;
    }
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Puck"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"minor" ascending:YES];
    [request setSortDescriptors:@[sortDescriptor]];
    return request;
}

- (Puck *)insertPuck:(NSString *)name
   withProximityUUID:(NSUUID *)proximityUUID
               major:(NSNumber *)major
               minor:(NSNumber *)minor
{
    Puck *puck = [NSEntityDescription insertNewObjectForEntityForName:@"Puck" inManagedObjectContext:self.managedObjectContext];
    
    puck.name = name;
    puck.proximityUUID = [proximityUUID UUIDString];
    puck.major = major;
    puck.minor = minor;
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error: %@", error);
    }
    
    return puck;
}


@end
