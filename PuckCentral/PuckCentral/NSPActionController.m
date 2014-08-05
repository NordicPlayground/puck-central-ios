
#import "NSPActionController.h"
#import "Action.h"

@implementation NSPActionController

+ (NSPActionController *)sharedController
{
    static NSPActionController *sharedController;
    
    @synchronized(self) {
        if (!sharedController) {
            sharedController = [[NSPActionController alloc] init];
        }
        return sharedController;
    }
}

- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Action"];
    return request;
}

- (Action *)insertAction:(NSNumber *)actuatorId
             withOptions:(NSDictionary *)options
{
    Action *action = [NSEntityDescription insertNewObjectForEntityForName:@"Action"
                                               inManagedObjectContext:self.managedObjectContext];

    action.actuatorId = actuatorId;
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:options
                                                       options:0
                                                         error:&error];
    if (jsonData) {
        action.options = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } else {
        DDLogError(error.localizedDescription);
    }
    
    if (![self.managedObjectContext save:&error]) {
        DDLogError(error.localizedDescription);
    }
    
    DDLogDebug(@"Inserted action");
    
    return action;
}

@end
