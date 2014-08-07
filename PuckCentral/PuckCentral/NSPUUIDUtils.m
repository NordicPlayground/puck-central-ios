
#import "NSPUUIDUtils.h"

@implementation NSPUUIDUtils

+(NSUUID *)stringToUUID:(NSString *)string
{
    uuid_t bytes;

    for(int i = 0; i < 16; i++) {
        bytes[i] = (int)[string characterAtIndex:i];
    }

    return [[NSUUID alloc] initWithUUIDBytes:bytes];
}

@end
