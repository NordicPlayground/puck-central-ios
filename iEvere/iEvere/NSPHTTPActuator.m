
#import "NSPHTTPActuator.h"

@implementation NSPHTTPActuator

+ (NSNumber *)index
{
    return @(1);
}

+ (NSString *)name
{
    return @"HTTP Actuator";
}

- (void)actuate:(NSDictionary *)options
{
    NSURL *URL = [NSURL URLWithString:options[@"url"]];
    NSLog(@"Post data to %@", URL);
    [self postData:options[@"data"] toURL:URL];
}

- (void)postData:(NSString *)data toURL:(NSURL *)URL
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [data dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    [[[NSURLConnection alloc] initWithRequest:request delegate:self] start];
}

@end
