
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
    self.puck.identifier = peripheral.identifier.UUIDString;
    NSError *error;
    if (![[[NSPPuckController sharedController] managedObjectContext] save:&error]) {
        NSLog(@"Error: %@", error);
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
        NSLog(@"Error saving context after adding serviceIDs: %@", error);
    }
}

@end
