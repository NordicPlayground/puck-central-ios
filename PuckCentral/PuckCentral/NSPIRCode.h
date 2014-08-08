
@import Foundation;

#import <XLForm/XLForm.h>

@interface NSPIRCode : NSObject <XLFormOptionObject>

@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSNumber *hexCode;

- (id)initWithDisplayName:(NSString *)displayName andHexCode:(NSNumber *)hexCode;

@end
