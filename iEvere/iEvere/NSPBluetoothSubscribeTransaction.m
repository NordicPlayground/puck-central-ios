
#import "NSPBluetoothSubscribeTransaction.h"

@implementation NSPBluetoothSubscribeTransaction

- (id)initWithPuck:(Puck *)puck
characteristicUUID:(NSUUID *)characteristicUUID
andCompletionBlock:(NSPBluetoothSubscribeTransactionBlock)complete
{
    self = [super init];
    if (self) {
        self.puck = puck;
        self.characteristicUUID = characteristicUUID;
        self.complete = complete;
    }
    return self;
}

@end
