
#import <Foundation/Foundation.h>
#import "NSPGattOperation.h"

@interface NSPGattDiscoverOperation : NSObject <NSPGattOperation>

- (id)initWithPuck:(Puck *)puck;

@end
