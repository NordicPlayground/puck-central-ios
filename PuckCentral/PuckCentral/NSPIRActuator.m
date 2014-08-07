
#import "NSPIRActuator.h"
#import "NSPBluetoothManager.h"
#import "NSPUUIDUtils.h"
#import "NSPIRCode.h"
#import "NSPRemote.h"
#import "NSPPuckSelector.h"
#import "Puck.h"
#import "NSPGattTransaction.h"

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
    NSPRemote *appleRemote = [[NSPRemote alloc] initWithName:@"Apple" type:NSPRemoteTypeNEC];
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
    
    NSPRemote *samsungRemote = [[NSPRemote alloc] initWithName:@"Samsung" type:NSPRemoteTypeNEC];
    samsungRemote.header = @[@4500, @4500];
    samsungRemote.one = @[@560, @1680];
    samsungRemote.zero = @[@560, @560];
    samsungRemote.predata = 0xE0E0;
    samsungRemote.ptrail = 560;
    samsungRemote.codes = @[
                            [[NSPIRCode alloc] initWithDisplayName:@"Power on/off" andHexCode:@0x20DF],
                            ];

    NSPRemote *meetingRoom31ScreenRemote = [[NSPRemote alloc] initWithName:@"Screen at 3-1" type:NSPRemoteTypeScreen];
    meetingRoom31ScreenRemote.one = @[@1260, @420];
    meetingRoom31ScreenRemote.zero = @[@420, @1260];
    meetingRoom31ScreenRemote.codes = @[
                            [[NSPIRCode alloc] initWithDisplayName:@"Screen up" andHexCode:@0xF01],
                            [[NSPIRCode alloc] initWithDisplayName:@"Screen middle" andHexCode:@0xF02],
                            [[NSPIRCode alloc] initWithDisplayName:@"Screen down" andHexCode:@0xF04],
                            ];
    
    return @{
             appleRemote.name: appleRemote,
             samsungRemote.name: samsungRemote,
             meetingRoom31ScreenRemote.name: meetingRoom31ScreenRemote
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
    [self writeToPuck:puck
          withService:[NSPUUIDUtils stringToUUID:NSPIRServiceUUIDString]
           andOptions:options];
}

- (void)writeToPuck:(Puck *)puck withService:(NSUUID *)serviceUUID andOptions:(NSDictionary *)options
{
    NSPRemote *remote = [[[self class] remotes] objectForKey:options[@"device"]];
    
    NSInteger code = [options[@"irCode"] intValue];

    NSUUID *periodUUID  = [NSPUUIDUtils stringToUUID:@"bftj ir period  "];
    NSUUID *commandUUID = [NSPUUIDUtils stringToUUID:@"bftj ir command "];
    NSUUID *dataUUID    = [NSPUUIDUtils stringToUUID:@"bftj ir data    "];
    
    NSInteger commandStart = 0;
    NSInteger commandEnd = 1;
    NSInteger period = 26;
    
    self.transaction = [[NSPGattTransaction alloc] init];
    
    [self writeValue:[NSData dataWithBytes:&period length:1]
          forService:serviceUUID
      characteristic:periodUUID
              onPuck:puck];
    
    [self writeValue:[NSData dataWithBytes:&commandStart length:1]
          forService:serviceUUID
      characteristic:commandUUID
              onPuck:puck];
    
    int sourceLength = 200; // Max length
    uint16_t source[sourceLength];
    
    if (remote.type == NSPRemoteTypeNEC) {
        sourceLength = 70;
        
        source[0] = [remote.header[0] intValue];
        source[1] = [remote.header[1] intValue];
        
        [self convertCode:remote.predata
               withRemote:remote
                   output:&source[2]
                   length:16];
        
        [self convertCode:code
               withRemote:remote
                   output:&source[34]
                   length:16];
        
        source[66] = remote.ptrail;
        source[67] = 0;
        source[68] = 0;
        source[69] = 0;
    } else if (remote.type == NSPRemoteTypeScreen) {
        sourceLength = 50;
        
        [self convertCode:code
               withRemote:remote
                   output:&source[0]
                   length:12];
        
        source[24] = 0;
        source[25] = 20 * 1680;
        
        [self convertCode:code
               withRemote:remote
                   output:&source[26]
                   length:12];
    }
    
    uint8_t array[20];
    for (int i = 0; i < sourceLength; i++) {
        array[(i % 10) * 2] = (uint8_t) ((source[i] & 0xFF00) >> 8 );
        array[(i % 10) * 2 + 1] = (uint8_t) (source[i] & 0xFF);
        
        if (i % 10 == 9) {
            [self writeValue:[NSData dataWithBytes:array length:20]
                  forService:serviceUUID
              characteristic:dataUUID
                      onPuck:puck];
            memset(array, 0, sizeof(array));
        }
    }
    
    [self writeValue:[NSData dataWithBytes:&commandEnd length:1]
          forService:serviceUUID
      characteristic:commandUUID
              onPuck:puck];
    
    [self waitForDisconnect:puck];
    
    [[NSPBluetoothManager sharedManager] queueTransaction:self.transaction];
}

- (void)convertCode:(uint16_t)code withRemote:(NSPRemote *)remote output:(uint16_t *)output length:(int)length
{
    NSLog(@"hexcode %X", code);
    int mask = 1 << (length - 1);
    NSLog(@"mask %X", mask);
    for (int i = 0; i < length * 2; i += 2) {
        int res = code & mask;
        NSLog(@"res %d", res);
        NSArray *signal = res ? remote.one : remote.zero;
        output[i] = [signal[0] intValue];
        output[i + 1] = [signal[1] intValue];
        code <<= 1;
    }
}

#pragma mark NSPConfigureActionFormDelegate protocol

- (void)form:(XLFormViewController *)formViewController
didUpdateRow:(XLFormRowDescriptor *)row
        from:(id)oldValue
          to:(id)newValue
{
    if ([row.tag isEqualToString:@"device"]) {
        XLFormRowDescriptor *irCodeRow = [formViewController.form formRowWithTag:@"irCode"];
        if (![newValue isEqual:[NSNull null]]) {
            NSString *remoteName = [newValue formValue];
            NSDictionary *remotes = [[self class] remotes];
            irCodeRow.selectorOptions = [remotes[remoteName] codes];
        } else {
            irCodeRow.selectorOptions = nil;
        }
        irCodeRow.value = nil;
        [formViewController reloadFormRow:irCodeRow];
    }
}


@end
