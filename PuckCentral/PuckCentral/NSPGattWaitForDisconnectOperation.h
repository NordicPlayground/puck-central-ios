
#import "NSPGattOperation.h"

@class Puck;

@interface NSPGattWaitForDisconnectOperation : NSObject <NSPGattOperation>

- (id)initWithPuck:(Puck *)puck;

@end
