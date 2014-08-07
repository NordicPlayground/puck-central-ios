
#import "NSPServiceUUIDController.h"

@implementation NSPServiceUUIDController

+ (NSPServiceUUIDController *)sharedController
{
    static NSPServiceUUIDController *sharedController;

    @synchronized(self) {
        if (!sharedController) {
            sharedController = [[NSPServiceUUIDController alloc] init];
        }
        return sharedController;
    }
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ServiceID"];
    return request;
}

- (ServiceUUID *)addOrGetServiceID:(NSString *)uuid
{
    NSError *error;
    NSFetchRequest *req = [self fetchRequest];
    req.predicate = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
    req.fetchLimit = 1;
    NSArray *result = [self.managedObjectContext executeFetchRequest:req error:&error];
    if(result == nil) {
        DDLogError(@"Error fetching UUIDs %@", error.localizedDescription);
    } else if (result.count > 0) {
        return result[0];
    }
    ServiceUUID *sUUID = [NSEntityDescription insertNewObjectForEntityForName:@"ServiceID" inManagedObjectContext:self.managedObjectContext];

    sUUID.uuid = uuid;

    if (![self.managedObjectContext save:&error]) {
        DDLogError(error.localizedDescription);
    }

    return sUUID;
}

@end
