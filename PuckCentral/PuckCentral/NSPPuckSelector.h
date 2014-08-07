
#import <XLForm/XLForm.h>

@interface NSPPuckSelector : XLFormRowDescriptor

- (id)initWithTag:(NSString *)tag serviceUUID:(NSUUID *)serviceUUID title:(NSString *)title;
+ (XLFormRowDescriptor *)formRowDescriptorWithTag:(NSString *)tag serviceUUID:(NSUUID *)serviceUUID title:(NSString *)title;

@end
