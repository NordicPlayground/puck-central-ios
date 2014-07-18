
#import "Puck.h"
#import "NSPPuckController.h"

@class Rule;
@class ServiceUUID;

@implementation Puck

@dynamic major;
@dynamic minor;
@dynamic name;
@dynamic proximityUUID;
@dynamic rules;
@dynamic serviceIDs;

- (void)addServiceIDsObject:(ServiceUUID *)object
{
    self.serviceIDs = [self.serviceIDs setByAddingObject:object];
}

- (void)addServiceIDs:(NSSet *)objects
{
    self.serviceIDs = [self.serviceIDs setByAddingObjectsFromSet:objects];
}

+ (instancetype)puckForBeacon:(CLBeacon *)beacon
{
    NSPPuckController *puckController = [NSPPuckController sharedController];
    NSFetchRequest *request = [puckController fetchRequest];
    
    request.predicate = [NSPredicate predicateWithFormat:@"minor == %@", beacon.minor];
    
    NSError *error;
    NSArray *puckResults = [[puckController managedObjectContext] executeFetchRequest:request error:&error];
    if (puckResults == nil) {
        NSLog(@"Fetch error: %@", error);
    } else if (puckResults.count > 0) {
        return puckResults[0];
    }
    return nil;
}

- (NSString *)formDisplayText
{
    return self.name;
}

- (id)formValue
{
    return self.minor;
}

@end
