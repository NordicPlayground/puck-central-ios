
@import Foundation;

@class Puck;
@class NSPGattTransaction;

@interface NSPPuckActuator : NSObject

@property (nonatomic, strong) NSPGattTransaction *transaction;

- (void)writeValue:(NSData *)value
        forService:(NSUUID *)serviceUUID
    characteristic:(NSUUID *)characteristicUUID
            onPuck:(Puck *)puck;
- (void)waitForDisconnect:(Puck *)puck;

@end
