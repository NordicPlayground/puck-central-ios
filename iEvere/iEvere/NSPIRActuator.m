
#import "NSPIRActuator.h"
#import "NSPBluetoothManager.h"
#import "NSPPuckController.h"
#import "NSPUUIDUtils.h"
#import "NSPBluetoothWriteTransaction.h"

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

    XLFormRowDescriptor *deviceRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"device" rowType:XLFormRowDescriptorTypeSelectorAlertView title:@"Device"];
    deviceRow.required = YES;
    deviceRow.selectorOptions = @[@"Apple"];
    deviceRow.value = @"Apple";
    [section addFormRow:deviceRow];

    XLFormRowDescriptor *irCodeRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"irCode" rowType:XLFormRowDescriptorTypeNumber title:@"IR code"];
    irCodeRow.required = YES;
    [section addFormRow:irCodeRow];

    XLFormRowDescriptor *minorNumRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"minor" rowType:XLFormRowDescriptorTypeText title:@"Minor Number"];
    minorNumRow.required = YES;
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
    NSScanner *scanner = [NSScanner scannerWithString:options[@"minor"]];
    unsigned int minor;
    [scanner scanHexInt:&minor];

    NSError *error;
    NSFetchRequest *req = [[NSPPuckController sharedController] fetchRequest];
    req.predicate = [NSPredicate predicateWithFormat:@"minor == %@", [NSNumber numberWithInt:minor]];
    req.fetchLimit = 1;
    NSArray *result = [[[NSPPuckController sharedController] managedObjectContext] executeFetchRequest:req error:&error];
    if(result == nil) {
        NSLog(@"Error fetching puck for IR actuator");
    } else if (result.count > 0) {
         puck = result[0];
    }

    int dataRaw = 0x23281194;
    NSData *data = [NSData dataWithBytes:&dataRaw length:16];
    [self writeData:data
         forService:[NSPUUIDUtils stringToUUID:@"bftj ir         "]
             toPuck:puck];

}

- (void)writeData:(NSData *)data forService:(NSUUID *)serviceUUID toPuck:(Puck *)puck
{

    NSPBluetoothWriteTransaction *writeTransaction =
    [[NSPBluetoothWriteTransaction alloc] initWithPuck:puck
                                           serviceUUID:serviceUUID
                                    andCompletionBlock:^(CBPeripheral *peripheral, NSArray *characteristics) {
                                                            NSLog(@"Did call block from bluetoothwritetransaction");
                                                            for(CBCharacteristic *characteristic in characteristics) {
                                                              [peripheral writeValue:data
                                                                   forCharacteristic:characteristic
                                                                                type:CBCharacteristicWriteWithoutResponse];
                                                            }
                                                        }];

    [[NSPBluetoothManager sharedManager] addToTransactionQueue:writeTransaction];
}

@end
