
@import Foundation;

#import <XLForm/XLForm.h>

@interface NSPIRCode : NSObject <XLFormOptionObject>

- (id)initWithDisplayName:(NSString *)displayName andHexCode:(NSNumber *)hexCode;

@end
