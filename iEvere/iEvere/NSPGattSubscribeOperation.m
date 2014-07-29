
#import "NSPGattSubscribeOperation.h"
#import "Puck.h"

@implementation NSPGattSubscribeOperation

@synthesize puck = _puck;
@synthesize completeOperation = _completeOperation;
@synthesize serviceUUID = _serviceUUID;
@synthesize characteristicUUID = _characteristicUUID;

- (id)initWithPuck:(Puck *)puck
       serviceUUID:(NSUUID *)serviceUUID
characteristicUUID:(NSUUID *)characteristicUUID
{
    self = [super init];
    if (self) {
        self.puck = puck;
        self.serviceUUID = serviceUUID;
        self.characteristicUUID = characteristicUUID;
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
    [peripheral discoverCharacteristics:@[self.characteristicUUID]
                             forService:service];
}

- (void)didDiscoverCharacteristic:(CBCharacteristic *)characteristic forPeripheral:(CBPeripheral *)peripheral
{
    [peripheral setNotifyValue:YES
             forCharacteristic:characteristic];
}

- (void)didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NSPCubeChangedDirection
                                                        object:self
                                                      userInfo:@{
                                                                 @"puck": self.puck,
                                                                 @"characteristic": characteristic
                                                                 }];
}

- (void)didDisconnect:(CBPeripheral *)peripheral
{
    self.puck.connected = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:NSPDidDisconnectFromPuck
                                                        object:self
                                                      userInfo:@{
                                                                 @"puck": self.puck
                                                                 }];
}

- (void)didAbortOperation
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NSPDidDisconnectFromPuck
                                                        object:self
                                                      userInfo:@{
                                                                 @"puck": self.puck
                                                                 }];
}

- (void)didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    self.completeOperation();
}

@end
