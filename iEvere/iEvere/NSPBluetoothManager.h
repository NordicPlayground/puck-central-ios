
@import CoreBluetooth;
@import CoreLocation;

#import "Puck.h"
#import "NSPGattOperation.h"

@interface NSPBluetoothManager : CBCentralManager <CBCentralManagerDelegate, CBPeripheralDelegate>

+ (NSPBluetoothManager *)sharedManager;

- (void)queueOperation:(id<NSPGattOperation>)gattOperation;

@end
