
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
    }
    return self;
}

- (void)cubeChangedDirection:(NSNotification *)notification
{
    Puck *puck = [self.connectedCubes objectForKey:notification.userInfo[@"peripheral"]];
    CBCharacteristic *characteristic = notification.userInfo[@"characteristic"];

    NSUInteger value = 0;
    [characteristic.value getBytes:&value length:1];

    switch (value) {
        case NSPCubeDirectionUP:
            NSLog(@"UP from puck: %@", puck);
            break;

        case NSPCubeDirectionDOWN:
            NSLog(@"DOWN from puck: %@", puck);
            break;

        case NSPCubeDirectionBACK:
            NSLog(@"BACK from puck: %@", puck);
            break;

        case NSPCubeDirectionFRONT:
            NSLog(@"FRONT from puck: %@", puck);
            break;

        case NSPCubeDirectionLEFT:
            NSLog(@"LEFT from puck: %@", puck);
            break;

        case NSPCubeDirectionRIGHT:
            NSLog(@"RIGHT from puck: %@", puck);
            break;

        default:
            NSLog(@"Unknown value: %ld for cube puck: %@", (unsigned long)value, puck);
            break;
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
