
#import "NSPIRActuator.h"
#import "NSPBluetoothManager.h"
#import "NSPPuckController.h"
#import "NSPUUIDUtils.h"
#import "NSPGattWriteOperation.h"
#import "NSPGattWaitForDisconnectOperation.h"
#import "NSPIRCode.h"
#import "NSPServiceUUIDController.h"
#import "NSPLocationManager.h"

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

- (void)actuateOnPuck:(Puck *)puck withOptions:(NSDictionary *)options
{
    [[NSPLocationManager sharedManager] startUsingPuck:puck];

    [self writeToPuck:puck
          withService:[NSPUUIDUtils stringToUUID:@"bftj ir         "]
           andOptions:options];
    
    [[NSPLocationManager sharedManager] stopUsingPuck:puck];
}

- (void)writeToPuck:(Puck *)puck withService:(NSUUID *)serviceUUID andOptions:(NSDictionary *)options
{
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

    NSUUID *headerUUID  = [NSPUUIDUtils stringToUUID:@"bftj ir header  "];
    NSUUID *oneUUID     = [NSPUUIDUtils stringToUUID:@"bftj ir one     "];
    NSUUID *zeroUUID    = [NSPUUIDUtils stringToUUID:@"bftj ir zero    "];
    NSUUID *ptrailUUID  = [NSPUUIDUtils stringToUUID:@"bftj ir ptrail  "];
    NSUUID *predataUUID = [NSPUUIDUtils stringToUUID:@"bftj ir predata "];
    NSUUID *codeUUID    = [NSPUUIDUtils stringToUUID:@"bftj ir code    "];
    
    [self writeValue:headerData forService:serviceUUID characteristic:headerUUID onPuck:puck];
    [self writeValue:oneData forService:serviceUUID characteristic:oneUUID onPuck:puck];
    [self writeValue:zeroData forService:serviceUUID characteristic:zeroUUID onPuck:puck];
    [self writeValue:ptrailData forService:serviceUUID characteristic:ptrailUUID onPuck:puck];
    [self writeValue:preData forService:serviceUUID characteristic:predataUUID onPuck:puck];
    [self writeValue:codeData forService:serviceUUID characteristic:codeUUID onPuck:puck];
    
    [self waitForDisconnect:puck];
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
