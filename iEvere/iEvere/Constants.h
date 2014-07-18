
@import Foundation;
@import CoreBluetooth;

typedef enum {
    NSPTriggerEnterZone = 0,
    NSPTriggerLeaveZone = 1
} NSPTrigger;

typedef void(^NSPBluetoothWriteTransactionBlock)(CBPeripheral*, NSDictionary*);

extern NSString * const NSPDidFindNewBeacon;
extern NSString * const NSPDidEnterZone;
extern NSString * const NSPDidLeaveZone;