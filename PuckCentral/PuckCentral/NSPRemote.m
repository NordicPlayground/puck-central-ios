
#import "NSPRemote.h"
#import "NSPIRCode.h"

@implementation NSPRemote

- (id)initWithName:(NSString *)name
              type:(NSPRemoteType)type
{
    self = [super init];
    if (self) {
        self.name = name;
        self.type = type;
    }
    return self;
}

- (NSString *)formDisplayText
{
    return self.name;
}

- (id)formValue
{
    return self.name;
}

@end
