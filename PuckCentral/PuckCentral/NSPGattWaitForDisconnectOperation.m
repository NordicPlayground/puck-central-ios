
#import "NSPGattWaitForDisconnectOperation.h"

@implementation NSPGattWaitForDisconnectOperation

@synthesize puck = _puck;
@synthesize completeOperation = _completeOperation;

- (id)initWithPuck:(Puck *)puck
{
    self = [super init];
    if (self) {
        self.puck = puck;
    }
    return self;
}

- (void)addedToQueue:(NSPCompleteOperation)completeOperation
{
    self.completeOperation = completeOperation;
}

- (void)didDisconnect:(CBPeripheral *)peripheral
{
    self.completeOperation();
}

@end
