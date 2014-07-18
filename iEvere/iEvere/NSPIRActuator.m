
#import "NSPIRActuator.h"
#import "NSPBluetoothManager.h"
#import "NSPPuckController.h"
#import "NSPUUIDUtils.h"
#import "NSPBluetoothWriteTransaction.h"
#import "NSPIRCode.h"
#import "NSPServiceUUIDController.h"

@implementation NSPIRActuator

+ (NSNumber *)index
{
    return @(2);
}

+ (NSString *)name
{
    return @"IR Actuator";
}

+ (XLFormDescriptor *)optionsForm
{
    XLFormDescriptor *form = [XLFormDescriptor formDescriptor];

    XLFormSectionDescriptor *section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];

    XLFormRowDescriptor *deviceRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"device"
                                                                           rowType:XLFormRowDescriptorTypeSelectorPush
                                                                             title:@"Device"];
    deviceRow.required = YES;
    deviceRow.selectorOptions = @[@"Apple"];
    deviceRow.value = @"Apple";
    [section addFormRow:deviceRow];

    XLFormRowDescriptor *irCodeRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"irCode"
                                                                           rowType:XLFormRowDescriptorTypeSelectorPush
                                                                             title:@"IR code"];
    irCodeRow.required = YES;
    irCodeRow.selectorOptions = @[
                                  [[NSPIRCode alloc] initWithDisplayName:@"Play/pause" andHexCode:@0xA0A8],
                                  [[NSPIRCode alloc] initWithDisplayName:@"Left" andHexCode:@0x9016],
                                  [[NSPIRCode alloc] initWithDisplayName:@"Right" andHexCode:@0x6016]
                                  ];
    [section addFormRow:irCodeRow];

    XLFormRowDescriptor *minorNumRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"minor"
                                                                             rowType:XLFormRowDescriptorTypeSelectorPush
                                                                               title:@"Puck"];
    minorNumRow.required = YES;
    NSFetchRequest *fetchRequest = [[NSPServiceUUIDController sharedController] fetchRequest];
    CBUUID *irServiceUUID = [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir         "]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", irServiceUUID.UUIDString]];
    NSError *error;
    NSArray *service = [[[NSPServiceUUIDController sharedController] managedObjectContext] executeFetchRequest:fetchRequest
                                                                                                       error:&error];
    if (service != nil && service.count > 0) {
        minorNumRow.selectorOptions = [[service[0] pucks] allObjects];
    } else {
        NSLog(@"Error: %@", error);
    }
    [section addFormRow:minorNumRow];

    return form;
}

- (NSString *)stringForOptions:(NSDictionary *)options
{
    return [NSString stringWithFormat:@"SEND IR CODE %@ to %@", options[@"irCode"], options[@"device"]];
}

- (void)actuate:(NSDictionary *)options
{
    if(![options[@"device"] isEqualToString:@"Apple"]) {
        NSLog(@"Error, device not Apple!");
        return;
    }
    Puck *puck = nil;

    NSError *error;
    NSFetchRequest *req = [[NSPPuckController sharedController] fetchRequest];
    req.predicate = [NSPredicate predicateWithFormat:@"minor == %@", options[@"minor"]];
    req.fetchLimit = 1;
    NSArray *result = [[[NSPPuckController sharedController] managedObjectContext] executeFetchRequest:req error:&error];
    if(result == nil) {
        NSLog(@"Error fetching puck for IR actuator");
    } else if (result.count > 0) {
         puck = result[0];
    }

    [self writeToPuck:puck
         withService:[NSPUUIDUtils stringToUUID:@"bftj ir         "]
             andOptions:options];

}

- (void)writeToPuck:(Puck *)puck withService:(NSUUID *)serviceUUID andOptions:(NSDictionary *)options
{
    void (^transactionBlock)(CBPeripheral *, NSDictionary *) = ^(CBPeripheral *peripheral, NSDictionary *characteristics) {
        
        NSArray *header, *one, *zero;
        NSInteger pre, ptrail;
        
        if ([options[@"device"] isEqual:@"Apple"]) {
            header = @[@9000, @4500];
            one = @[@560, @1690];
            zero = @[@560, @560];
            pre = CFSwapInt16(0x77E1);
            ptrail = CFSwapInt16(560);
        }
        
        NSInteger code = CFSwapInt16([options[@"irCode"] intValue]);
        
        NSData *headerData = [self dataWithArray:header];
        NSData *oneData = [self dataWithArray:one];
        NSData *zeroData = [self dataWithArray:zero];
        NSData *preData = [NSData dataWithBytes:&pre length:2];
        NSData *ptrailData = [NSData dataWithBytes:&ptrail length:2];
        NSData *codeData = [NSData dataWithBytes:&code length:2];
    
        CBUUID *headerUUID  = [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir header  "]];
        CBUUID *oneUUID     = [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir one     "]];
        CBUUID *zeroUUID    = [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir zero    "]];
        CBUUID *ptrailUUID  = [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir ptrail  "]];
        CBUUID *predataUUID = [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir predata "]];
        CBUUID *codeUUID    = [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:@"bftj ir code    "]];
        
        [peripheral writeValue:headerData
             forCharacteristic:characteristics[headerUUID]
                          type:CBCharacteristicWriteWithoutResponse];
        [peripheral writeValue:oneData
             forCharacteristic:characteristics[oneUUID]
                          type:CBCharacteristicWriteWithoutResponse];
        [peripheral writeValue:zeroData
             forCharacteristic:characteristics[zeroUUID]
                          type:CBCharacteristicWriteWithoutResponse];
        [peripheral writeValue:ptrailData
             forCharacteristic:characteristics[ptrailUUID]
                          type:CBCharacteristicWriteWithoutResponse];
        [peripheral writeValue:preData
             forCharacteristic:characteristics[predataUUID]
                          type:CBCharacteristicWriteWithoutResponse];
        [peripheral writeValue:codeData
             forCharacteristic:characteristics[codeUUID]
                          type:CBCharacteristicWriteWithoutResponse];
    };
    
    NSPBluetoothWriteTransaction *writeTransaction = [[NSPBluetoothWriteTransaction alloc] initWithPuck:puck
                                                                                            serviceUUID:serviceUUID
                                                                                     andCompletionBlock:transactionBlock];

    [[NSPBluetoothManager sharedManager] addToTransactionQueue:writeTransaction];
}

- (NSData *)dataWithArray:(NSArray *)array
{
    uint32_t tmp = 0;
    for (int i=0; i < array.count; i++) {
        tmp |= [array[i] intValue] << (16 * (array.count - i - 1));
    }
    tmp = CFSwapInt32(tmp);
    return [NSData dataWithBytes:&tmp length:(array.count * 2)];
}

@end
