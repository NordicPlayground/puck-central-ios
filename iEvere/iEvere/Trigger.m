
#import "Trigger.h"

@implementation Trigger

- (id)initWithDisplayName:(NSString *)displayName
forNotification:(NSString *)notificationString
{
    if (self = [super init]) {
        self.displayName = displayName;
        self.notificationString = notificationString;
    }
    return self;
}

@end
