
#import "LocationPuck.h"
#import "NSPLocationPuckController.h"

@implementation LocationPuck

@dynamic major;
@dynamic minor;
@dynamic name;
@dynamic proximityUUID;

+ (instancetype)puckForBeacon:(CLBeacon *)beacon
{
    NSPLocationPuckController *locationPuckController = [NSPLocationPuckController sharedController];
    NSFetchRequest *request = [locationPuckController fetchRequest];
    
    request.predicate = [NSPredicate predicateWithFormat:@"minor == %@", beacon.minor];
    
    NSError *error;
    NSArray *puckResults = [[locationPuckController managedObjectContext] executeFetchRequest:request error:&error];
    if (puckResults == nil) {
        NSLog(@"Fetch error: %@", error);
    } else if (puckResults.count > 0) {
        return puckResults[0];
    }
    return nil;
}

@end
