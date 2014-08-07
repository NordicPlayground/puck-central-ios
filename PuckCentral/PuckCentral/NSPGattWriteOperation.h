
@import CoreBluetooth;

#import "NSPGattOperation.h"

@class Puck;

@interface NSPGattWriteOperation : NSObject <NSPGattOperation>

@property (nonatomic, strong) NSData *value;

- (id)initWithPuck:(Puck *)puck
       serviceUUID:(NSUUID *)serviceUUID
    characteristic:(NSUUID *)characteristicUUID
             value:(NSData *)value;

@end
