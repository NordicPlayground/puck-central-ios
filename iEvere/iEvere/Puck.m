
#import "Puck.h"
#import "NSPPuckController.h"
#import "NSPBluetoothManager.h"

@class Rule;
@class ServiceUUID;

@implementation Puck

@dynamic major;
@dynamic minor;
@dynamic name;
@dynamic proximityUUID;
@dynamic identifier;
@dynamic rules;
@dynamic serviceIDs;
@synthesize connectedState = _connectedState;

- (void)awakeFromInsert
{
    self.connectedState = DISCONNECTED;
}

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
    return [self puckWithMinorNumber:beacon.minor];
}

+ (instancetype)puckWithMinorNumber:(NSNumber *)minor
{
    NSPPuckController *puckController = [NSPPuckController sharedController];
    NSFetchRequest *request = [puckController fetchRequest];
    
    request.predicate = [NSPredicate predicateWithFormat:@"minor == %@", minor];
    
    NSError *error;
    NSArray *puckResults = [[puckController managedObjectContext] executeFetchRequest:request error:&error];
    if (puckResults == nil) {
        DDLogError(error.localizedDescription);
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

- (NSUUID *)UUID
{
    return [[NSUUID alloc] initWithUUIDString:self.identifier];
}

@end
