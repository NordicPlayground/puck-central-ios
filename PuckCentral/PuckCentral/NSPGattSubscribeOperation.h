
#import <Foundation/Foundation.h>
#import "NSPGattOperation.h"

@interface NSPGattSubscribeOperation : NSObject <NSPGattOperation>

- (id)initWithPuck:(Puck *)puck
       serviceUUID:(NSUUID *)serviceUUID
characteristicUUID:(NSUUID *)characteristicUUID;

@end
