
@import CoreBluetooth;
@import CoreLocation;

@class NSPGattTransaction;

@interface NSPBluetoothManager : CBCentralManager <CBCentralManagerDelegate, CBPeripheralDelegate>

+ (NSPBluetoothManager *)sharedManager;

- (void)queueTransaction:(NSPGattTransaction *)gattTransaction;

@end
