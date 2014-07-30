
#import "NSPGattDiscoverOperation.h"
#import "Puck.h"
#import "NSPPuckController.h"
#import "NSPServiceUUIDController.h"

@implementation NSPGattDiscoverOperation

@synthesize puck = _puck;
@synthesize completeOperation = _completeOperation;

- (id)initWithPuck:(Puck *)puck
{
    self = [super init];
    if (self) {
        self.puck = puck;
    }
    return self;
}

- (void)addedToQueue:(NSPCompleteOperation)completeOperation
{
    self.completeOperation = completeOperation;
}

- (void)didFindPeripheral:(CBPeripheral *)peripheral withCentralManager:(CBCentralManager *)centralManager
{
    NSString *uuidString = peripheral.identifier.UUIDString;

    NSError *error;
    NSFetchRequest *req = [[NSPPuckController sharedController] fetchRequest];
    req.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", uuidString];
    req.fetchLimit = 1;
    NSArray *result = [[[NSPPuckController sharedController] managedObjectContext] executeFetchRequest:req error:&error];
    if (error) {
        DDLogError(error.localizedDescription);
    } else if (result.count > 0) {
        Puck *puck = result[0];
        NSString *message = [NSString stringWithFormat:@"You already have this puck and it's named: %@. To avoid unexpected behaviour, please delete %@.", puck.name, puck.name];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Duplicate puck found!"
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        alertView.alertViewStyle = UIAlertViewStyleDefault;

        dispatch_async(dispatch_get_main_queue(), ^{
            if(!alertView.visible) {
                [alertView show];
            }
        });
    }

    self.puck.identifier = uuidString;
    if (![[[NSPPuckController sharedController] managedObjectContext] save:&error]) {
        DDLogError(error.localizedDescription);
    }
    [centralManager connectPeripheral:peripheral options:nil];
}

- (void)didConnect:(CBPeripheral *)peripheral
{
    [peripheral discoverServices:nil];
}

- (void)didDiscoverServices:(NSArray *)services forPeripheral:(CBPeripheral *)peripheral
{
    NSMutableArray *serviceUUIDs = [[NSMutableArray alloc] init];
    for (CBService *service in services) {
        ServiceUUID *serviceUUID = [[NSPServiceUUIDController sharedController] addOrGetServiceID:[service.UUID UUIDString]];
        [serviceUUIDs addObject:serviceUUID];
    }
    [self addServiceIDsToPuck:serviceUUIDs];
    
    self.completeOperation();
}

- (void)addServiceIDsToPuck:(NSArray *)services
{
    NSSet *servicesSet = [NSSet setWithArray:services];
    [self.puck addServiceIDs:servicesSet];
    NSError *error;
    if (![[[NSPPuckController sharedController] managedObjectContext] save:&error]) {
        DDLogError(@"Error saving context after adding serviceIDs: %@", error);
    }
}

@end
