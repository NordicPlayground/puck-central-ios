
#import "NSPIRActuator.h"
#import "NSPBluetoothManager.h"
#import "NSPPuckController.h"
#import "NSPUUIDUtils.h"
#import "NSPGattWriteOperation.h"
#import "NSPGattWaitForDisconnectOperation.h"
#import "NSPIRCode.h"
#import "NSPRemote.h"
#import "NSPServiceUUIDController.h"
#import "NSPLocationManager.h"
#import "NSPPuckSelector.h"

@implementation NSPIRActuator

+ (NSNumber *)index
{
    return @(2);
}

+ (NSString *)name
{
    return @"IR Actuator";
}

+ (NSDictionary *)remotes
{
    NSPRemote *appleRemote = [[NSPRemote alloc] initWithName:@"Apple"];
    appleRemote.header = @[@9000, @4500];
    appleRemote.one = @[@560, @1690];
    appleRemote.zero = @[@560, @560];
    appleRemote.predata = 0x77E1;
    appleRemote.ptrail = 560;
    appleRemote.codes = @[
                          [[NSPIRCode alloc] initWithDisplayName:@"Play/pause" andHexCode:@0xA0A8],
                          [[NSPIRCode alloc] initWithDisplayName:@"Left" andHexCode:@0x9016],
                          [[NSPIRCode alloc] initWithDisplayName:@"Right" andHexCode:@0x6016],
                          ];
    
    NSPRemote *samsungRemote = [[NSPRemote alloc] initWithName:@"Samsung"];
    samsungRemote.header = @[@4500, @4500];
    samsungRemote.one = @[@560, @1680];
    samsungRemote.zero = @[@560, @560];
    samsungRemote.predata = 0xE0E0;
    samsungRemote.ptrail = 560;
    samsungRemote.codes = @[
                            [[NSPIRCode alloc] initWithDisplayName:@"Power on/off" andHexCode:@0x20DF],
                            ];
    
    return @{
             appleRemote.name: appleRemote,
             samsungRemote.name: samsungRemote
             };
}

+ (XLFormDescriptor *)optionsForm
{
    NSDictionary *remotes = [self remotes];
    
    XLFormDescriptor *form = [XLFormDescriptor formDescriptor];

    XLFormSectionDescriptor *section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];

    XLFormRowDescriptor *deviceRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"device"
                                                                           rowType:XLFormRowDescriptorTypeSelectorPush
                                                                             title:@"Device"];
    deviceRow.required = YES;
    deviceRow.selectorOptions = [remotes allValues];
    deviceRow.value = @"Apple";
    [section addFormRow:deviceRow];

    XLFormRowDescriptor *irCodeRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"irCode"
                                                                           rowType:XLFormRowDescriptorTypeSelectorPush
                                                                             title:@"IR code"];
    irCodeRow.required = YES;
    irCodeRow.selectorOptions = [remotes[deviceRow.value] codes];

    [section addFormRow:irCodeRow];

    XLFormRowDescriptor *puckRow = [NSPPuckSelector formRowDescriptorWithTag:@"minor"
                                                                 serviceUUID:[NSPUUIDUtils stringToUUID:NSPIRServiceUUIDString]
                                                                       title:@"Puck"];
    puckRow.required = YES;
    [section addFormRow:puckRow];

    return form;
}

- (NSString *)stringForOptions:(NSDictionary *)options
{
    Puck *puck = [Puck puckWithMinorNumber:options[@"minor"]];
    return [NSString stringWithFormat:@"Send %@ code %X to %@",
            options[@"device"],
            [options[@"irCode"] intValue],
            puck.name];
}

- (void)actuateOnPuck:(Puck *)puck withOptions:(NSDictionary *)options
{
    [[NSPLocationManager sharedManager] startUsingPuck:puck];

    [self writeToPuck:puck
          withService:[NSPUUIDUtils stringToUUID:NSPIRServiceUUIDString]
           andOptions:options];
    
    [[NSPLocationManager sharedManager] stopUsingPuck:puck];
}

- (void)writeToPuck:(Puck *)puck withService:(NSUUID *)serviceUUID andOptions:(NSDictionary *)options
{
    NSPRemote *remote = [[[self class] remotes] objectForKey:options[@"device"]];
    
    NSData *headerData = [self dataWithArray:remote.header];
    NSData *oneData = [self dataWithArray:remote.one];
    NSData *zeroData = [self dataWithArray:remote.zero];
    
    NSInteger pre = CFSwapInt16(remote.predata);
    NSData *preData = [NSData dataWithBytes:&pre length:2];
    
    NSInteger ptrail = CFSwapInt16(remote.ptrail);
    NSData *ptrailData = [NSData dataWithBytes:&ptrail length:2];
    
    NSInteger code = CFSwapInt16([options[@"irCode"] intValue]);
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

#pragma mark NSPConfigureActionFormDelegate protocol

- (void)form:(XLFormDescriptor *)form didUpdateRow:(XLFormRowDescriptor *)row from:(id)oldValue to:(id)newValue
{
    if ([row.tag isEqualToString:@"device"]) {
        XLFormRowDescriptor *irCodeRow = [form formRowWithTag:@"irCode"];
        NSString *remoteName = [newValue formValue];
        NSDictionary *remotes = [[self class] remotes];
        irCodeRow.selectorOptions = [remotes[remoteName] codes];
        irCodeRow.value = nil;
    }
}


@end
