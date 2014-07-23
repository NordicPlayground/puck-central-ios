
#import "NSPGattWriteOperation.h"

@implementation NSPGattWriteOperation

@synthesize puck = _puck;
@synthesize completeOperation = _completeOperation;
@synthesize serviceUUID = _serviceUUID;
@synthesize characteristicUUID = _characteristicUUID;

- (id)initWithPuck:(Puck *)puck
       serviceUUID:(NSUUID *)serviceUUID
    characteristic:(NSUUID *)characteristicUUID
             value:(NSData *)value
{
    self = [super init];
    if (self) {
        self.puck = puck;
        self.serviceUUID = serviceUUID;
        self.characteristicUUID = characteristicUUID;
        self.value = value;
    }
    return self;
}

- (void)addedToQueue:(NSPCompleteOperation)completeOperation
{
    self.completeOperation = completeOperation;
}

- (void)didConnect:(CBPeripheral *)peripheral
{
    [peripheral discoverServices:@[self.serviceUUID]];
}

- (void)didDiscoverService:(CBService *)service forPeripheral:(CBPeripheral *)peripheral
{
    [peripheral discoverCharacteristics:@[self.characteristicUUID] forService:service];
}

- (void)didDiscoverCharacteristic:characteristic forPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Writing value %@", self.value);
    [peripheral writeValue:self.value
         forCharacteristic:characteristic
                      type:CBCharacteristicWriteWithResponse];
}

- (void)didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
{
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithNSUUID:self.characteristicUUID]]) {
        self.completeOperation();
    }
}

@end
