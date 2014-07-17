
#import "NSPBluetoothManager.h"
#import "NSPUUIDUtils.h"
#import "NSPServiceUUIDController.h"
#import "NSPPuckController.h"
#import "Puck.h"
#import "NSPUUIDUtils.h"

@interface NSPBluetoothManager ()

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, assign) bool isCoreBluetoothReady;
@property (nonatomic, strong) NSMutableArray *tempServices;
@property (nonatomic, strong) Puck *tempPuck;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSMutableArray *connectedPeripherals;

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
        self.tempPuck = nil;
        self.tempServices = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)stopSearchingForPeripherals
{
    [self.centralManager stopScan];
}

- (CBPeripheral *)findPeripheralFromBeacon:(Puck *)puck
{
    if (self.isCoreBluetoothReady) {
        self.tempPuck = puck;
        NSDictionary *options = @{CBCentralManagerScanOptionAllowDuplicatesKey: @YES};
        [_centralManager scanForPeripheralsWithServices:nil
                                                options:options];
    } else {
        NSLog(@"Error, Core Bluetooth BLE harware not powered on and ready");
    }

    return nil;
}

- (void)writeValue:(NSData *)data
 forCharacteristic:(CBCharacteristic *)characteristic
              type:(CBCharacteristicWriteType)type
            toPuck:(Puck *)puck
{
    for(CBPeripheral *peripheral in self.connectedPeripherals) {
        [peripheral writeValue:data
             forCharacteristic:characteristic
                          type:type];
        NSLog(@"Sent IR to %@", peripheral);
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
    NSLog(@"Did write value to characteristic: %@", characteristic);
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
    if (self.tempPuck == nil) {
        return;
    }

    NSData *data = advertisementData[CBAdvertisementDataManufacturerDataKey];
    if (data != nil) {
        if ([data length] != 25) {
            NSLog(@"Advertisement data payload too small");
            return;
        }

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
            return;
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

        if([self.tempPuck.proximityUUID isEqual:[proximityUUID UUIDString]] &&
           [self.tempPuck.major intValue] == major &&
           [self.tempPuck.minor intValue] == minor) {

           [self.centralManager stopScan];
            self.peripheral = peripheral;

           [self.centralManager connectPeripheral:self.peripheral
                                          options:nil];
        }
    }
}

- (void)addServiceIDsToPuck
{
    NSSet *services = [NSSet setWithArray:self.tempServices];
    [self.tempPuck addServiceIDs:services];
    NSError *error;
    if (![[[NSPPuckController sharedController] managedObjectContext] save:&error]) {
        NSLog(@"Error saving context after adding serviceIDs: %@", error);
    }
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Did successfully connect to peripheral %@", peripheral);
    peripheral.delegate = self;
    [self.connectedPeripherals addObject:peripheral];
    [self.peripheral discoverServices:@[
                                        [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir         "]]
                                        ]];
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services for %@", [error localizedDescription]);
        return;
    }

    for (CBService *service in peripheral.services) {
        ServiceUUID *serviceUUID = [[NSPServiceUUIDController sharedController] addOrGetServiceID:[service.UUID UUIDString]];
        [self.tempServices addObject:serviceUUID];
        [self.peripheral discoverCharacteristics:nil
                                      forService:service];

    }

    [self addServiceIDsToPuck];
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics %@", [error localizedDescription]);
        return;
    }

    for(CBCharacteristic *characteristic in service.characteristics) {
        int dataRaw = 0x28281194;
        NSData *data = [NSData dataWithBytes:&dataRaw length:sizeof(data)];
        [peripheral writeValue:data
             forCharacteristic:characteristic
                          type:CBCharacteristicWriteWithResponse];
        NSLog(@"Characteristic: %@", characteristic);
    }
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    NSLog(@"Did fail to connect to peripheral %@", peripheral);
}

- (void)centralManager:(CBCentralManager *)central
didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
    NSLog(@"Currently connected peripherals:");
    int i = 0;
    for(CBPeripheral *peripheral in peripherals) {
        NSLog(@"[%d] peripherpal: %@", i, peripheral);
        i++;
    }
}

- (void)centralManager:(CBCentralManager *)central
 didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Known peripherals:");
    int i = 0;
    for(CBPeripheral *peripheral in peripherals) {
        NSLog(@"[%d] peripheral: %@", i, peripheral);
        i++;
    }
}

@end
