
#import "NSPPuckActuator.h"
#import "NSPGattTransaction.h"
#import "NSPGattWriteOperation.h"
#import "NSPGattWaitForDisconnectOperation.h"

@implementation NSPPuckActuator

- (void)writeValue:(NSData *)value
        forService:(NSUUID *)serviceUUID
    characteristic:(NSUUID *)characteristicUUID
            onPuck:(Puck *)puck
{
    NSPGattWriteOperation *writeOperation = [[NSPGattWriteOperation alloc] initWithPuck:puck
                                                                            serviceUUID:serviceUUID
                                                                         characteristic:characteristicUUID
                                                                                  value:value];
    [self.transaction addOperation:writeOperation];
}

- (void)waitForDisconnect:(Puck *)puck
{
    NSPGattWaitForDisconnectOperation *disconnectOperation = [[NSPGattWaitForDisconnectOperation alloc] initWithPuck:puck];
    [self.transaction addOperation:disconnectOperation];
}

@end
