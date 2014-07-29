
@import Foundation;
@import CoreBluetooth;

#define NSPTRIGGER_LOCATION 0
#define NSPTRIGGER_CUBE 8

typedef NS_ENUM(NSUInteger, NSPCubeDirection) {
    NSPCubeDirectionUP,
    NSPCubeDirectionDOWN,
    NSPCubeDirectionLEFT,
    NSPCubeDirectionRIGHT,
    NSPCubeDirectionFRONT,
    NSPCubeDirectionBACK
};

typedef void(^NSPCompleteOperation)();

extern NSString * const NSPDidFindNewBeacon;
extern NSString * const NSPDidEnterZone;
extern NSString * const NSPDidLeaveZone;

extern NSString * const NSPDidDisconnectFromPuck;
extern NSString * const NSPDidSubscribeToCharacteristic;

extern NSString * const NSPCubeChangedDirection;
extern NSString * const NSPTriggerCubeChangedDirection;

extern NSString * const NSPServiceUUIDString;
extern NSString * const NSPCubeServiceUUIDString;
extern NSString * const NSPIRServiceUUIDString;
extern NSString * const NSPDisplayServiceUUIDString;
