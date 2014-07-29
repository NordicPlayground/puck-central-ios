
#import "Action.h"
#import "Rule.h"


@implementation Action

@dynamic actuatorId;
@dynamic options;
@dynamic rule;

- (NSDictionary *)decodedOptions
{
    NSData *jsonData = [self.options dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *parsedOptions = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
    if (error) {
        DDLogError(error.localizedDescription);
    }
    return parsedOptions;
}

@end
