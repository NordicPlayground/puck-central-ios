
@import Foundation;
@import CoreBluetooth;

typedef enum {
    NSPTriggerEnterZone = 0,
    NSPTriggerLeaveZone = 1
} NSPTrigger;

typedef NS_ENUM(NSUInteger, NSPCubeDirection) {
    NSPCubeDirectionUP,
    NSPCubeDirectionDOWN,
    NSPCubeDirectionLEFT,
    NSPCubeDirectionRIGHT,
    NSPCubeDirectionFRONT,
    NSPCubeDirectionBACK
};

typedef void(^NSPBluetoothWriteTransactionBlock)(CBPeripheral*, NSDictionary*);
typedef void(^NSPBluetoothSubscribeTransactionBlock)(CBPeripheral*);

extern NSString * const NSPDidFindNewBeacon;
extern NSString * const NSPDidEnterZone;
extern NSString * const NSPDidLeaveZone;

extern NSString * const NSPCubeChangedDirection;

extern NSString * const NSPCubeServiceUUIDString;
extern NSString * const NSPIRServiceUUIDString;
