
@import Foundation;
@import CoreBluetooth;

@class Puck;

typedef enum {
    NSPTriggerEnterZone = 0,
    NSPTriggerLeaveZone = 1
} NSPTrigger;

typedef void(^NSPBluetoothWriteTransactionBlock)(CBPeripheral*, NSArray*);

extern NSString * const NSPDidFindNewBeacon;
extern NSString * const NSPDidEnterZone;
extern NSString * const NSPDidLeaveZone;