
#import "NSPIRCode.h"

@interface NSPIRCode ()

@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSNumber *hexCode;

@end

@implementation NSPIRCode

- (id)initWithDisplayName:(NSString *)displayName andHexCode:(NSNumber *)hexCode
{
    if (self = [super init]) {
        self.displayName = displayName;
        self.hexCode = hexCode;
    }
    return self;
}

- (NSString *)formDisplayText
{
    return self.displayName;
}

- (id)formValue
{
    return self.hexCode;
}

@end
