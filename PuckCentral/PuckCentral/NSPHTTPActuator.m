
#import "NSPHTTPActuator.h"
#import <XLForm/XLForm.h>

@implementation NSPHTTPActuator

+ (NSNumber *)index
{
    return @(1);
}

+ (NSString *)name
{
    return @"HTTP Actuator";
}

+ (XLFormDescriptor *)optionsForm
{
    XLFormDescriptor *form = [XLFormDescriptor formDescriptor];
    
    XLFormSectionDescriptor *section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    XLFormRowDescriptor *URLRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"url" rowType:XLFormRowDescriptorTypeURL title:@"URL"];
    URLRow.required = YES;
    [section addFormRow:URLRow];
    
    XLFormRowDescriptor *dataRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"data" rowType:XLFormRowDescriptorTypeTextView title:@"Data"];
    dataRow.required = YES;
    [section addFormRow:dataRow];
    
    return form;
}

- (void)actuate:(NSDictionary *)options
{
    NSURL *URL = [NSURL URLWithString:options[@"url"]];
    DDLogDebug(@"Post data %@ to %@", options[@"data"], URL);
    [self postData:options[@"data"] toURL:URL];
}

- (NSString *)stringForOptions:(NSDictionary *)options
{
    return [NSString stringWithFormat:@"POST %@ to %@", options[@"data"], options[@"url"]];
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
