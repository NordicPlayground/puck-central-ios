
#import "NSPCubeManager.h"
#import "NSPUUIDUtils.h"
#import "NSPBluetoothManager.h"
#import "NSPBluetoothSubscribeTransaction.h"
#import "ServiceUUID.h"
#import "Puck.h"

@interface NSPCubeManager ()

@property (nonatomic, strong) NSUUID *cubeServiceUUID;
@property (nonatomic, strong) NSUUID *cubeDirectionCharacteristicUUID;

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
    }
    return self;
}

- (void)checkAndConnectToCubePuck:(Puck *)puck
{
    for(ServiceUUID *service in puck.serviceIDs) {
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:service.uuid];
        if([uuid isEqual:self.cubeServiceUUID]) {
            NSPBluetoothSubscribeTransaction *subscribeTransaction =
             [[NSPBluetoothSubscribeTransaction alloc] initWithPuck:puck
                                              andCharacteristicUUID:self.cubeDirectionCharacteristicUUID];
            [[NSPBluetoothManager sharedManager] addToTransactionQueue:subscribeTransaction];
        }
    }
}

@end
