
#import "NSPBluetoothManager.h"
#import "NSPUUIDUtils.h"
#import "NSPServiceUUIDController.h"
#import "NSPPuckController.h"
#import "Puck.h"
#import "Constants.h"
#import "NSPUUIDUtils.h"
#import "NSPTransaction.h"
#import "NSPBluetoothWriteTransaction.h"
#import "NSPBluetoothScanTransaction.h"
#import "NSPBluetoothSubscribeTransaction.h"

@interface NSPBluetoothManager ()

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, assign) bool isCoreBluetoothReady;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSMutableArray *transactionQueue;
@property (nonatomic, strong) NSPTransaction *activeTransaction;

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
        dispatch_queue_t centralQueue = dispatch_queue_create("com.nordicsemi.ievere.centralqueue", DISPATCH_QUEUE_SERIAL);
        self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                   queue:centralQueue
                                                                 options:nil];
        self.activeTransaction = nil;
        self.transactionQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addToTransactionQueue:(id)object
{
    [self.transactionQueue addObject:object];

    if(self.activeTransaction == nil) {
        [self driveQueue];
    }
}

- (void)driveQueue
{
    if(self.activeTransaction != nil) {
        NSLog(@"Error: tried to drive queue before transaction was complete!");
        return;
    } else if (self.transactionQueue.count == 0) {
        NSLog(@"No more transactions for now");
        [self.centralManager stopScan];
        return;
    }
    NSPTransaction *nextTransaction = [self.transactionQueue objectAtIndex:0];
    [self.transactionQueue removeObjectAtIndex:0];
    self.activeTransaction = nextTransaction;
    [self findPeripheralFromBeacon];
}

- (void)findPeripheralFromBeacon
{
    if (self.isCoreBluetoothReady) {
        [_centralManager scanForPeripheralsWithServices:nil
                                                options:nil];
    } else {
        NSLog(@"Error, Core Bluetooth BLE harware not powered on and ready");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Error writing characteristic value %@",
              [error localizedDescription]);
    }
}

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
    NSLog(@"Did discover peripheral");
    if (self.activeTransaction.puck == nil) {
        return;
    }

    NSData *data = advertisementData[CBAdvertisementDataManufacturerDataKey];
    if (data != nil) {
        if ([data length] != 25) {
            NSLog(@"Error: Advertisement data payload too small");
            return;
        }

        BOOL isSamePuck = [self compareManufacturerSpecificData:data];

        if(isSamePuck) {
           [self.centralManager stopScan];
            self.peripheral = peripheral;

           [self.centralManager connectPeripheral:self.peripheral
                                          options:nil];
        }
    }
}

- (void)addServiceIDsToPuck:(NSArray *)services
{
    NSSet *servicesSet = [NSSet setWithArray:services];
    [self.activeTransaction.puck addServiceIDs:servicesSet];
    NSError *error;
    if (![[[NSPPuckController sharedController] managedObjectContext] save:&error]) {
        NSLog(@"Error saving context after adding serviceIDs: %@", error);
    }
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    peripheral.delegate = self;
    [self.peripheral discoverServices:@[
                                        [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:NSPCubeServiceUUIDString]],
                                        [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:NSPIRServiceUUIDString]]
                                        ]];
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services for %@", [error localizedDescription]);
        self.activeTransaction = nil;
        [self driveQueue];
        return;
    }

    BOOL scanning = [self.activeTransaction isKindOfClass:[NSPBluetoothScanTransaction class]];
    BOOL writing = [self.activeTransaction isKindOfClass:[NSPBluetoothWriteTransaction class]];
    BOOL subscribing = [self.activeTransaction isKindOfClass:[NSPBluetoothSubscribeTransaction class]];

    NSMutableArray *services = [[NSMutableArray alloc] init];

    for (CBService *service in peripheral.services) {
        if(scanning) {
            ServiceUUID *serviceUUID = [[NSPServiceUUIDController sharedController] addOrGetServiceID:[service.UUID UUIDString]];
            [services addObject:serviceUUID];
        } else if (writing || subscribing) {
            [self.peripheral discoverCharacteristics:nil forService:service];
        }
    }

    if(scanning) {
        [self addServiceIDsToPuck:services];
        [self setActiveTransaction:nil];
        [self.centralManager cancelPeripheralConnection:self.peripheral];
        [self driveQueue];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics %@", [error localizedDescription]);
        return;
    }

    BOOL writing = [self.activeTransaction isKindOfClass:[NSPBluetoothWriteTransaction class]];
    BOOL subscribing = [self.activeTransaction isKindOfClass:[NSPBluetoothSubscribeTransaction class]];

    if(writing) {
        NSPBluetoothWriteTransaction *writeTransaction = (NSPBluetoothWriteTransaction*)self.activeTransaction;
        NSMutableDictionary *characteristics = [[NSMutableDictionary alloc] init];
        for (CBCharacteristic *characteristic in service.characteristics) {
            characteristics[characteristic.UUID] = characteristic;
        }
        writeTransaction.complete(peripheral, characteristics);
        self.activeTransaction = nil;
        [self.centralManager cancelPeripheralConnection:self.peripheral];
        [self driveQueue];
    } else if (subscribing){
        NSPBluetoothSubscribeTransaction *subscribeTransaction = (NSPBluetoothSubscribeTransaction*)self.activeTransaction;
        for(CBCharacteristic *characteristic in service.characteristics) {
            if([characteristic.UUID isEqual:[CBUUID UUIDWithNSUUID:subscribeTransaction.characteristicUUID]]) {
                [peripheral setNotifyValue:YES
                         forCharacteristic:characteristic];
                subscribeTransaction.complete(peripheral);
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if(error) {
        NSLog(@"Error updating value for characteristic: %@ for peripheral: %@", characteristic, peripheral);
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSPCubeChangedDirection
                                                        object:self
                                                      userInfo:@{
                                                                 @"peripheral": peripheral,
                                                                 @"characteristic": characteristic
                                                                 }];
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if(error) {
        NSLog(@"Error changing notification state: %@", error);
        return;
    }
    NSLog(@"Did subscribe to characteristic: %@", characteristic);
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    NSLog(@"Did fail to connect to peripheral %@", peripheral);
    [self notifyAboutDisconnectFromPeripheral:peripheral];
}

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    if(error) {
        NSLog(@"Error disconnecting from peripheral: %@ with error: %@", peripheral, error);
        [self notifyAboutDisconnectFromPeripheral:peripheral];
        return;
    }
    [self notifyAboutDisconnectFromPeripheral:peripheral];
}

- (void)notifyAboutDisconnectFromPeripheral:(CBPeripheral *)peripheral
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NSPDidDisconnectFromPeripheral
                                                        object:self
                                                      userInfo:@{
                                                                 @"peripheral": peripheral
                                                                 }];
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

    return [self.activeTransaction.puck.proximityUUID isEqual:[proximityUUID UUIDString]] &&
        [self.activeTransaction.puck.major intValue] == major &&
        [self.activeTransaction.puck.minor intValue] == minor;
}

@end
