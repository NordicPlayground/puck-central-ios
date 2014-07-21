
#import <Foundation/Foundation.h>
#import "NSPTransaction.h"

@interface NSPBluetoothSubscribeTransaction : NSPTransaction

@property (nonatomic, strong) NSUUID *characteristicUUID;
@property (nonatomic, copy) NSPBluetoothSubscribeTransactionBlock complete;

- (id)initWithPuck:(Puck *)puck characteristicUUID:(NSUUID *)characteristicUUID andCompletionBlock:(NSPBluetoothSubscribeTransactionBlock)complete;

@end
