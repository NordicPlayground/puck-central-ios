
@import CoreBluetooth;
@import CoreLocation;

#import "Puck.h"

@interface NSPBluetoothManager : CBCentralManager <CBCentralManagerDelegate, CBPeripheralDelegate>

+ (NSPBluetoothManager *)sharedManager;

- (CBPeripheral *)findPeripheralFromBeacon:(Puck *)puck;
- (void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type toPuck:(Puck *)puck;
- (void)stopSearchingForPeripherals;

@end
