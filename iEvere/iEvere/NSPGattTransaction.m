
#import "NSPGattTransaction.h"

#define DEFAULT_TIMEOUT 6

@implementation NSPGattTransaction

- (id)init
{
    self = [super init];
    if (self) {
        self.operationQueue = [[NSMutableArray alloc] init];
        self.timeout = DEFAULT_TIMEOUT;
    }
    return self;
}

- (id)initWithTimeout:(NSInteger)timeout
{
    self = [self init];
    if (self) {
        self.timeout = timeout;
    }
    return self;
}

+ (NSPGattTransaction *)transactionWithOperation:(id<NSPGattOperation>)operation
{
    NSPGattTransaction *transaction = [[NSPGattTransaction alloc] init];
    [transaction addOperation:operation];
    return transaction;
}

- (void)addOperation:(id<NSPGattOperation>)operation
{
    [self.operationQueue addObject:operation];
}

- (id<NSPGattOperation>)nextOperation
{
    if (self.operationQueue.count == 0) {
        return nil;
    }
    
    id<NSPGattOperation> nextOperation = self.operationQueue[0];
    [self.operationQueue removeObjectAtIndex:0];
    return nextOperation;
}

@end
