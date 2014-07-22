
#import "NSPCubeManager.h"
#import "NSPUUIDUtils.h"
#import "NSPBluetoothManager.h"
#import "NSPBluetoothSubscribeTransaction.h"
#import "ServiceUUID.h"
#import "Puck.h"

@interface NSPCubeManager ()

@property (nonatomic, strong) NSUUID *cubeServiceUUID;
@property (nonatomic, strong) NSUUID *cubeDirectionCharacteristicUUID;
@property (nonatomic, strong) NSMutableDictionary *connectedCubes;

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
        self.connectedCubes = [[NSMutableDictionary alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cubeChangedDirection:)
                                                     name:NSPCubeChangedDirection
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(checkAndDeleteCubeOnDisconnect:)
                                                     name:NSPDidDisconnectFromPeripheral
                                                   object:nil];
    }
    return self;
}

- (void)cubeChangedDirection:(NSNotification *)notification
{
    Puck *puck = [self.connectedCubes objectForKey:notification.userInfo[@"peripheral"]];
    CBCharacteristic *characteristic = notification.userInfo[@"characteristic"];

    NSUInteger value = 0;
    [characteristic.value getBytes:&value length:1];

    [[NSNotificationCenter defaultCenter] postNotificationName:NSPTriggerCubeChangedDirection
                                                        object:self
                                                      userInfo:@{
                                                                 @"puck": puck,
                                                                 @"direction": [NSNumber numberWithUnsignedInteger:value]
                                                                 }];
}

- (void)checkAndDeleteCubeOnDisconnect:(NSNotification *)notification
{
    CBPeripheral *peripheral = notification.userInfo[@"peripheral"];

    if([self.connectedCubes objectForKey:peripheral]) {
        [self.connectedCubes removeObjectForKey:peripheral];
    }
}

- (void)checkAndConnectToCubePuck:(Puck *)puck
{
    for(ServiceUUID *service in puck.serviceIDs) {
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:service.uuid];
        if([uuid isEqual:self.cubeServiceUUID]) {
            NSPBluetoothSubscribeTransaction *subscribeTransaction =
             [[NSPBluetoothSubscribeTransaction alloc] initWithPuck:puck
                                                 characteristicUUID:self.cubeDirectionCharacteristicUUID
                                                 andCompletionBlock:^(CBPeripheral *peripheral) {
                                                     [self.connectedCubes setObject:puck forKey:peripheral];
                                                 }];
            [[NSPBluetoothManager sharedManager] addToTransactionQueue:subscribeTransaction];
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPCubeChangedDirection object:nil];
}

@end
