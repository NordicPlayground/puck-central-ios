
#import "NSPBluetoothSubscribeTransaction.h"

@implementation NSPBluetoothSubscribeTransaction

- (id)initWithPuck:(Puck *)puck andCharacteristicUUID:(NSUUID *)characteristicUUID
{
    self = [super init];
    if (self) {
        self.puck = puck;
        self.characteristicUUID = characteristicUUID;
    }
    return self;
}

@end
