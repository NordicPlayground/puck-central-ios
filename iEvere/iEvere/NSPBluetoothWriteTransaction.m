
#import "NSPBluetoothWriteTransaction.h"

@implementation NSPBluetoothWriteTransaction

- (id)initWithPuck:(Puck *)puck serviceUUID:(NSUUID *)serviceUUID andCompletionBlock:(NSPBluetoothWriteTransactionBlock)complete
{
    self = [super init];
    if (self) {
        self.puck = puck;
        self.serviceUUID = serviceUUID;
        self.complete = complete;
    }
    return self;
}

@end
