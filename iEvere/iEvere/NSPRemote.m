
#import "NSPRemote.h"

@implementation NSPRemote

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        self.name = name;
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
