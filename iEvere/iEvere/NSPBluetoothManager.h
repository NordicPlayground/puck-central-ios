
@import CoreBluetooth;
@import CoreLocation;

#import "Puck.h"

@interface NSPBluetoothManager : CBCentralManager <CBCentralManagerDelegate, CBPeripheralDelegate>

+ (NSPBluetoothManager *)sharedManager;

- (void)addToTransactionQueue:(id)object;

@end
