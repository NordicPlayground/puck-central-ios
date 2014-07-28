
@import Foundation;

#import "NSPGattOperation.h"

@interface NSPGattTransaction : NSObject

@property (nonatomic, strong) NSMutableArray *operationQueue;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, assign) NSInteger timeout;

- (id)initWithTimeout:(NSInteger)timeout;
+ (NSPGattTransaction *)transactionWithOperation:(id<NSPGattOperation>)operation;

- (void)addOperation:(id<NSPGattOperation>)operation;
- (id<NSPGattOperation>)nextOperation;

@end
