
@import Foundation;
@import CoreBluetooth;

typedef NS_ENUM(NSUInteger, NSPTrigger) {
    NSPTriggerEnterZone,
    NSPTriggerLeaveZone,

    NSPTriggerCubeDirectionUP,
    NSPTriggerCubeDirectionDOWN,
    NSPTriggerCubeDirectionLEFT,
    NSPTriggerCubeDirectionRIGHT,
    NSPTriggerCubeDirectionFRONT,
    NSPTriggerCubeDirectionBACK,

    NSPTriggerNumberOfTriggers
};

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

extern NSString * const NSPDidDisconnectFromPeripheral;

extern NSString * const NSPCubeChangedDirection;
extern NSString * const NSPTriggerCubeChangedDirection;

extern NSString * const NSPCubeServiceUUIDString;
extern NSString * const NSPIRServiceUUIDString;
