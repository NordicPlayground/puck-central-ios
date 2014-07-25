
#import "NSPBluetoothManager.h"
#import "Puck.h"
#import "NSPGattTransaction.h"
#import "NSPGattOperation.h"
#import "NSPLocationManager.h"

#define TIMEOUT_IN_SECONDS 9

@interface NSPBluetoothManager ()

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, assign) bool isCoreBluetoothReady;
@property (nonatomic, strong) dispatch_queue_t centralQueue;
@property (nonatomic, strong) NSMutableSet *activePeripherals;

@property (nonatomic, strong) NSMutableArray *transactionQueue;
@property (nonatomic, strong) NSPGattTransaction *activeTransaction;
@property (nonatomic, strong) id<NSPGattOperation> activeOperation;
@property (nonatomic, strong) NSMutableArray *subscribedOperations;

@end

@implementation NSPBluetoothManager

+ (NSPBluetoothManager *)sharedManager
{
    static NSPBluetoothManager *sharedManager;

    @synchronized(self) {
        if (!sharedManager) {
            sharedManager = [[NSPBluetoothManager alloc] init];
        }
        return sharedManager;
    }
}

- (id)init
{
    if (self = [super init]) {
        self.centralQueue = dispatch_queue_create("com.nordicsemi.ievere.centralqueue", DISPATCH_QUEUE_SERIAL);
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                   queue:self.centralQueue
                                                                 options:nil];
        self.activeTransaction = nil;
        self.activeOperation = nil;
        self.transactionQueue = [[NSMutableArray alloc] init];
        self.subscribedOperations = [[NSMutableArray alloc] init];
        self.activePeripherals = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)queueTransaction:(NSPGattTransaction *)gattTransaction
{
    NSLog(@"queue transaction %@", gattTransaction);
    [self.transactionQueue addObject:gattTransaction];
    
    for (id<NSPGattOperation> gattOperation in gattTransaction.operationQueue) {
        [gattOperation addedToQueue:^() {
            NSLog(@"Did complete the operation");
            [self nextOperation];
        }];
    }

    if (self.activeTransaction == nil) {
        [self nextTransaction];
    }
}

- (void)setActiveOperation:(id<NSPGattOperation>)activeOperation
{
    if (_activeOperation != nil) {
        [[NSPLocationManager sharedManager] stopUsingPuck:_activeOperation.puck];
    }
    
    _activeOperation = activeOperation;
    
    if (activeOperation != nil) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(TIMEOUT_IN_SECONDS * NSEC_PER_SEC)), self.centralQueue, ^{
            if ([self.activeOperation isEqual:activeOperation]) {
                NSLog(@"%@ timed out", [self.activeOperation class]);
                [self abortTransaction];
            }
        });
        
        [[NSPLocationManager sharedManager] startUsingPuck:activeOperation.puck];
        [self findPeripheralFromBeacon];
    }
}

- (void)nextOperation
{
    if (self.activeTransaction == nil) {
        [self nextTransaction];
        return;
    }
    
    id<NSPGattOperation> nextOperation = [self.activeTransaction nextOperation];
    if (nextOperation == nil) {
        self.activeOperation = nil;
        self.activeTransaction = nil;
        [self nextTransaction];
        return;
    } else {
        self.activeOperation = nextOperation;
    }
}

- (void)subscribeOperation:(id<NSPGattOperation>)gattOperation
{
    [self.subscribedOperations addObject:gattOperation];
}

- (void)unsubscribeOperation:(id<NSPGattOperation>)gattOperation
{
    [self.subscribedOperations removeObject:gattOperation];
}

- (void)nextTransaction
{
    if (self.activeTransaction != nil) {
        NSLog(@"Error: tried to drive queue before operation was complete!");
        return;
    } else if (self.transactionQueue.count == 0) {
        NSLog(@"No more transactions for now");
        [self.centralManager stopScan];
        return;
    }
    self.activeTransaction = self.transactionQueue[0];
    [self.transactionQueue removeObjectAtIndex:0];
    self.activeOperation = [self.activeTransaction nextOperation];
}

- (void)abortTransaction
{
    if (self.activeTransaction != nil) {
        NSLog(@"Aborting transaction %@", [self.activeOperation class]);
        [_centralManager cancelPeripheralConnection:self.activeTransaction.peripheral];
        self.activeOperation = nil;
        self.activeTransaction = nil;
        [self nextTransaction];
    }
}

- (void)findPeripheralFromBeacon
{
    if (self.isCoreBluetoothReady) {
        NSArray *peripherals = [_centralManager retrievePeripheralsWithIdentifiers:@[
                                                                                     [self.activeOperation.puck UUID]
                                                                                     ]];
        if (peripherals.count > 0) {
            [self didFindPeripheral:peripherals[0]];
        } else {
            if ([self.activeOperation respondsToSelector:@selector(serviceUUID)]) {
                peripherals = [_centralManager retrieveConnectedPeripheralsWithServices:@[
                                                                                          [CBUUID UUIDWithNSUUID:self.activeOperation.serviceUUID]
                                                                                          ]];
            }
            if (peripherals.count > 0) {
                for (CBPeripheral *peripheral in peripherals) {
                    if ([peripheral.identifier isEqual:[self.activeOperation.puck UUID]]) {
                        [self didFindPeripheral:peripheral];
                    }
                }
            } else {
                [_centralManager scanForPeripheralsWithServices:nil
                                                        options:nil];
            }
        }
    } else {
        NSLog(@"Error, Core Bluetooth BLE harware not powered on and ready");
    }
}

- (void)didFindPeripheral:(CBPeripheral *)peripheral
{
    [self.activePeripherals addObject:peripheral];
    self.activeTransaction.peripheral = peripheral;
    peripheral.delegate = self;
    if ([self.activeOperation respondsToSelector:@selector(didFindPeripheral:withCentralManager:)]) {
        [self.activeOperation didFindPeripheral:peripheral
                             withCentralManager:self.centralManager];
    } else {
        [_centralManager connectPeripheral:peripheral options:nil];
    }
}

#pragma mark CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    self.isCoreBluetoothReady = NO;
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
            self.isCoreBluetoothReady = YES;
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CoreBluetooth BLE hardware is powered off");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CoreBluetooth BLE hardware is resetting");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CoreBluetooth BLE hardware is unsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CoreBluetooth BLE hardware is unauthorized");
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"CoreBluetooth BLE hardware is in an unknown state");
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    if (self.activeOperation.puck == nil) {
        return;
    }

    NSData *data = advertisementData[CBAdvertisementDataManufacturerDataKey];
    if (data != nil) {
        if ([data length] != 25) {
            NSLog(@"Error: Advertisement data payload too small");
            return;
        }

        BOOL isSamePuck = [self compareManufacturerSpecificData:data];

        if (isSamePuck) {
            [self.centralManager stopScan];

            [self didFindPeripheral:peripheral];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    if ([self.activeOperation respondsToSelector:@selector(didConnect:)]) {
        [self.activeOperation didConnect:peripheral];
    }
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    NSLog(@"Did fail to connect to peripheral %@", peripheral);
    [self.activePeripherals removeObject:peripheral];
    [self abortTransaction];
}

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    NSLog(@"Disconnect from peripheral %@", peripheral.identifier.UUIDString);
    if (error && error.code != CBErrorPeripheralDisconnected) {
        NSLog(@"Error: %@", error.localizedDescription);
        if ([self.activeTransaction.peripheral isEqual:peripheral]) {
            [self abortTransaction];
        }
    }
    
    if ([self.activeOperation respondsToSelector:@selector(didDisconnect:)]) {
        if ([peripheral.identifier isEqual:[self.activeOperation.puck UUID]]) {
            [self.activeOperation didDisconnect:peripheral];
        }
    }
    for (id<NSPGattOperation> gattOperation in self.subscribedOperations) {
        if ([gattOperation respondsToSelector:@selector(didDisconnect:)]) {
            if ([peripheral.identifier isEqual:[gattOperation.puck UUID]]) {
                [gattOperation didDisconnect:peripheral];
                [self unsubscribeOperation:gattOperation];
            }
        }
    }
}

#pragma mark CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services for %@. Aborting operation.", [error localizedDescription]);
        [self abortTransaction];
        return;
    }

    if ([self.activeOperation respondsToSelector:@selector(didDiscoverServices:forPeripheral:)]) {
        [self.activeOperation didDiscoverServices:peripheral.services
                                    forPeripheral:peripheral];
    } else if ([self.activeOperation respondsToSelector:@selector(didDiscoverService:forPeripheral:)]) {
        if (![self.activeOperation respondsToSelector:@selector(serviceUUID)]) {
            [NSException raise:@"Missing property serviceUUID" format:@"This needs to be set when implementing didDiscoverService"];
        }
        for (CBService *service in peripheral.services) {
            if ([service.UUID isEqual:[CBUUID UUIDWithNSUUID:[self.activeOperation serviceUUID]]]) {
                [self.activeOperation didDiscoverService:service forPeripheral:peripheral];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics %@", [error localizedDescription]);
        [self abortTransaction];
        return;
    }

    if ([self.activeOperation respondsToSelector:@selector(didDiscoverCharacteristic:forPeripheral:)]) {
        if (![self.activeOperation respondsToSelector:@selector(characteristicUUID)]) {
            [NSException raise:@"Missing property characteristicUUID" format:@"This needs to be set when implementing didDiscoverCharacteristic"];
            return;
        }
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithNSUUID:[self.activeOperation characteristicUUID]]]) {
                [self.activeOperation didDiscoverCharacteristic:characteristic forPeripheral:peripheral];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Error writing characteristic value %@", [error localizedDescription]);
        [self abortTransaction];
        return;
    }
    if ([self.activeOperation respondsToSelector:@selector(didWriteValueForCharacteristic:)]) {
        [self.activeOperation didWriteValueForCharacteristic:characteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Error updating value for characteristic: %@ for peripheral: %@", characteristic, peripheral);
        return;
    }
    
    for (id<NSPGattOperation> operation in self.subscribedOperations) {
        [operation didUpdateValueForCharacteristic:characteristic];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@", error);
        return;
    }
    NSLog(@"Did subscribe to characteristic: %@", characteristic.UUID.UUIDString);
    
    [self subscribeOperation:self.activeOperation];
    if ([self.activeOperation respondsToSelector:@selector(didSubscribeToCharacteristic:)]) {
        [self.activeOperation didSubscribeToCharacteristic:characteristic];
    }
}

- (BOOL)compareManufacturerSpecificData:(NSData *)data
{
    uint16_t companyID = 0;
    uint16_t major = 0;
    uint16_t minor = 0;
    uint8_t dataType = 0;
    uint8_t dataLength = 0;
    uint8_t measuredPower = 0;
    char uuidBytes[17] = {0};

    NSRange companyIDRange = NSMakeRange(0,2);
    NSRange dataTypeRange = NSMakeRange(2,1);
    NSRange dataLengthRange = NSMakeRange(3,1);

    [data getBytes:&companyID range:companyIDRange];
    [data getBytes:&dataLength range:dataLengthRange];
    [data getBytes:&dataType range:dataTypeRange];

    if (dataType != 0x02 || dataLength != 0x15) {
        NSLog(@"Wrong start to payload, expected: 0xXXXX0215 got: 0xXXXX%x%x", dataType, dataLength);
        return NO;
    }

    NSRange uuidRange = NSMakeRange(4, 16);
    NSRange majorRange = NSMakeRange(20, 2);
    NSRange minorRange = NSMakeRange(22, 2);
    NSRange powerRange = NSMakeRange(24, 1);

    [data getBytes:&uuidBytes range:uuidRange];
    [data getBytes:&major range:majorRange];
    [data getBytes:&minor range:minorRange];
    [data getBytes:&measuredPower range:powerRange];

    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDBytes:(const unsigned char*)&uuidBytes];
    major = (major >> 8) | (major << 8);
    minor = (minor >> 8) | (minor << 8);

    return [self.activeOperation.puck.proximityUUID isEqual:[proximityUUID UUIDString]] &&
        [self.activeOperation.puck.major intValue] == major &&
        [self.activeOperation.puck.minor intValue] == minor;
}

@end
