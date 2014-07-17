
#import "NSPBluetoothScanTransaction.h"

@implementation NSPBluetoothScanTransaction

- (id)initWithPuck:(Puck *)puck
{
    self = [super init];
    if (self) {
        self.puck = puck;
    }
    return self;
}

@end
