
#import "NSPPuckSelector.h"
#import "NSPServiceUUIDController.h"

@implementation NSPPuckSelector

- (id)initWithTag:(NSString *)tag serviceUUID:(NSUUID *)serviceUUID title:(NSString *)title
{
    self = [super initWithTag:tag rowType:XLFormRowDescriptorTypeSelectorPush title:title];
    if (self) {
        NSFetchRequest *fetchRequest = [[NSPServiceUUIDController sharedController] fetchRequest];
        CBUUID *irServiceUUID = [CBUUID UUIDWithNSUUID:serviceUUID];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", irServiceUUID.UUIDString]];
        NSError *error;
        NSArray *service = [[[NSPServiceUUIDController sharedController] managedObjectContext] executeFetchRequest:fetchRequest
                                                                                                           error:&error];
        if (service != nil && service.count > 0) {
            self.selectorOptions = [[service[0] pucks] allObjects];
        } else {
            DDLogError(@"Error fetching pucks for service: %@", error);
        }
    }
    return self;
}

+ (XLFormRowDescriptor *)formRowDescriptorWithTag:(NSString *)tag serviceUUID:(NSUUID *)serviceUUID title:(NSString *)title
{
    return [[NSPPuckSelector alloc] initWithTag:tag serviceUUID:serviceUUID title:title];
}

@end
