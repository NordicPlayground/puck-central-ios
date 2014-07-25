
#import "NSPCubeManager.h"
#import "NSPUUIDUtils.h"
#import "NSPBluetoothManager.h"
#import "NSPTriggerManager.h"
#import "NSPGattSubscribeOperation.h"
#import "ServiceUUID.h"
#import "Puck.h"
#import "Trigger.h"

@interface NSPCubeManager ()

@property (nonatomic, strong) NSUUID *cubeServiceUUID;
@property (nonatomic, strong) NSUUID *cubeDirectionCharacteristicUUID;
@property (nonatomic, strong) NSMutableArray *subscribedCubes;

@end

@implementation NSPCubeManager

+ (NSPCubeManager *)sharedManager
{
    static NSPCubeManager *sharedManager;

    @synchronized(self) {
        if (!sharedManager) {
            sharedManager = [[NSPCubeManager alloc] init];
        }
        return sharedManager;
    }
}

- (id)init
{
    if (self = [super init]) {
        self.cubeServiceUUID = [NSPUUIDUtils stringToUUID:NSPCubeServiceUUIDString];
        self.cubeDirectionCharacteristicUUID = [NSPUUIDUtils stringToUUID:@"bftj cube dirctn"];
        self.subscribedCubes = [[NSMutableArray alloc] init];

        [[NSPTriggerManager sharedManager] registerTriggers:@[
                      [[Trigger alloc] initWithDisplayName:@"Cube turns up" forNotification:NSPCubeChangedDirection],
                      [[Trigger alloc] initWithDisplayName:@"Cube turns down" forNotification:NSPCubeChangedDirection],
                      [[Trigger alloc] initWithDisplayName:@"Cube turns left" forNotification:NSPCubeChangedDirection],
                      [[Trigger alloc] initWithDisplayName:@"Cube turns right" forNotification:NSPCubeChangedDirection],
                      [[Trigger alloc] initWithDisplayName:@"Cube turns back" forNotification:NSPCubeChangedDirection],
                      [[Trigger alloc] initWithDisplayName:@"Cube turns front" forNotification:NSPCubeChangedDirection]
                                                             ]
                                             forServiceUUID:self.cubeServiceUUID
                                                 withPrefix:NSPTRIGGER_CUBE];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cubeChangedDirection:)
                                                     name:NSPCubeChangedDirection
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cubeDisconnected:)
                                                     name:NSPDidDisconnectFromPeripheral
                                                   object:nil];
    }
    return self;
}

- (void)cubeChangedDirection:(NSNotification *)notification
{
    CBCharacteristic *characteristic = notification.userInfo[@"characteristic"];

    NSUInteger value = 0;
    [characteristic.value getBytes:&value length:1];

    [[NSNotificationCenter defaultCenter] postNotificationName:NSPTriggerCubeChangedDirection
                                                        object:self
                                                      userInfo:@{
                                                                 @"puck": notification.userInfo[@"puck"],
                                                                 @"direction": [NSNumber numberWithUnsignedInteger:value]
                                                                 }];
}

- (void)checkAndConnectToCubePuck:(Puck *)puck
{
    if ([self.subscribedCubes containsObject:puck]) {
        return;
    }
    for(ServiceUUID *service in puck.serviceIDs) {
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:service.uuid];
        if([uuid isEqual:self.cubeServiceUUID]) {
            NSPGattSubscribeOperation *subscribeOperation =
             [[NSPGattSubscribeOperation alloc] initWithPuck:puck
                                                 serviceUUID:self.cubeServiceUUID
                                          characteristicUUID:self.cubeDirectionCharacteristicUUID];
            [[NSPBluetoothManager sharedManager] queueOperation:subscribeOperation];
            [self.subscribedCubes addObject:puck];
        }
    }
}

- (void)cubeDisconnected:(NSNotification *)notification
{
    CBPeripheral *peripheral = notification.userInfo[@"peripheral"];
    for (Puck *puck in self.subscribedCubes) {
        if ([[puck UUID] isEqual:peripheral.identifier]) {
            NSLog(@"Puck disconnected! %@", puck.name);
            [self.subscribedCubes removeObject:puck];
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPCubeChangedDirection object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPDidDisconnectFromPeripheral object:nil];
}

@end
