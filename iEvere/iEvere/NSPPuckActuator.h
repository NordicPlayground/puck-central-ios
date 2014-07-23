
@import Foundation;

@class Puck;

@interface NSPPuckActuator : NSObject

- (void)writeValue:(NSData *)value
        forService:(NSUUID *)serviceUUID
    characteristic:(NSUUID *)characteristicUUID
            onPuck:(Puck *)puck;
- (void)waitForDisconnect:(Puck *)puck;

@end
