
#import <Foundation/Foundation.h>

@class Puck;

@protocol NSPGattOperation <NSObject>

@property (nonatomic, strong) Puck *puck;
@property (copy) void (^completeOperation)(void);

- (void)addedToQueue:(NSPCompleteOperation)completeOperation;

@optional

@property (nonatomic, strong) NSUUID *serviceUUID;
@property (nonatomic, strong) NSUUID *characteristicUUID;

- (void)didFindPeripheral:(CBPeripheral *)peripheral withCentralManager:(CBCentralManager *)centralManager;
- (void)didConnect:(CBPeripheral *)peripheral;
- (void)didDisconnect:(CBPeripheral *)peripheral;

- (void)didDiscoverServices:(NSArray *)services forPeripheral:(CBPeripheral *)peripheral;
- (void)didDiscoverService:(CBService *)service forPeripheral:(CBPeripheral *)peripheral;
- (void)didDiscoverCharacteristic:(CBCharacteristic *)characteristic forPeripheral:(CBPeripheral *)peripheral;

- (void)didWriteValueForCharacteristic:(CBCharacteristic *)characteristic;
- (void)didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic;
- (void)didSubscribeToCharacteristic:(CBCharacteristic *)characteristic;

- (void)didAbortOperation;

@end
