
#import <Foundation/Foundation.h>
#import "NSPTransaction.h"

@interface NSPBluetoothSubscribeTransaction : NSPTransaction

@property (nonatomic, strong) NSUUID *characteristicUUID;

- (id)initWithPuck:(Puck *)puck andCharacteristicUUID:(NSUUID *)characteristicUUID;

@end
