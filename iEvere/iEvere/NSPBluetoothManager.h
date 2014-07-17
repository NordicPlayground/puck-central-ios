
@import CoreBluetooth;
@import CoreLocation;

#import "Puck.h"

@interface NSPBluetoothManager : CBCentralManager <CBCentralManagerDelegate, CBPeripheralDelegate>

+ (NSPBluetoothManager *)sharedManager;

- (void)stopSearchingForPeripherals;
- (void)addToTransactionQueue:(id)object;

@end
