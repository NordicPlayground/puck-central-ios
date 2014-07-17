
#import <Foundation/Foundation.h>
#import "NSPTransaction.h"
@import CoreBluetooth;

@class Puck;

@interface NSPBluetoothWriteTransaction : NSPTransaction

@property (nonatomic, strong) NSUUID *serviceUUID;
@property (nonatomic, copy) NSPBluetoothWriteTransactionBlock complete;

- (id)initWithPuck:(Puck *)puck serviceUUID:(NSUUID *)serviceUUID andCompletionBlock:(NSPBluetoothWriteTransactionBlock)complete;

@end
