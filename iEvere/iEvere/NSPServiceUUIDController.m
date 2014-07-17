
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

- (void)populateUUIDs
{
    NSArray *serivceUUIDs = @[
                              [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir         "]],
                              [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir header  "]],
                              [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir one     "]],
                              [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir zero    "]],
                              [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir ptrail  "]],
                              [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir predata "]],
                              [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir code    "]]
                              ];

    NSError *error = nil;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:[self fetchRequest] error:&error];

    if(!(count == serivceUUIDs.count)) {
        NSFetchRequest *removeRequest = [self fetchRequest];
        [removeRequest setIncludesPropertyValues:NO];

        NSError *error = nil;
        NSArray *oldUUIDs = [self.managedObjectContext executeFetchRequest:removeRequest error:&error];
        if(error) {
            NSLog(@"Error: %@", error);
            return;
        }

        for (NSManagedObject *oldUUID in oldUUIDs) {
            [self.managedObjectContext deleteObject:oldUUID];
        }
        [self.managedObjectContext save:&error];
        if(error) {
            NSLog(@"Error: %@", error);
            return;
        }

        for (int i = 0; i < serivceUUIDs.count; i++) {
            NSLog(@"Did not already find serviceuuids");
            ServiceUUID *service = [NSEntityDescription insertNewObjectForEntityForName:@"ServiceID" inManagedObjectContext:self.managedObjectContext];

            service.uuid = [[serivceUUIDs objectAtIndex:i] UUIDString];

            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Error: %@", error);
            }
        }
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
        NSLog(@"Error fetching UUIDs");
    } else if (result.count > 0) {
        return result[0];
    }
    ServiceUUID *sUUID = [NSEntityDescription insertNewObjectForEntityForName:@"ServiceID" inManagedObjectContext:self.managedObjectContext];

    sUUID.uuid = uuid;

    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error: %@", error);
    }

    return sUUID;
}

@end
