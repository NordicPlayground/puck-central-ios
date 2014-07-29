
#import "NSPWeatherService.h"
#import <KissXML/DDXML.h>
@import Foundation;

@interface NSPWeatherService () <NSURLConnectionDataDelegate>

@property (nonatomic, copy) NSPWeatherServiceResults completion;
@property (nonatomic, strong) NSMutableData *responseData;

@end

@implementation NSPWeatherService

- (void)currentTemperature:(NSPWeatherServiceResults)completion
{
    self.completion = completion;
    self.responseData = [[NSMutableData alloc] init];
    DDLogDebug(@"get current temp");
    NSURL *url = [NSURL URLWithString:@"http://www.yr.no/sted/Norge/S%C3%B8r-Tr%C3%B8ndelag/Trondheim/Trondheim/varsel.xml"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSURLConnection connectionWithRequest:request delegate:self];
    });
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    DDLogError(error.localizedDescription);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    DDLogDebug(@"Finished loading");
    NSError *error;
    DDXMLDocument *doc = [[DDXMLDocument alloc] initWithData:self.responseData options:0 error:&error];
    NSString *xpathPattern= @"//temperature";
    NSArray *resultNodes = [doc nodesForXPath: xpathPattern error:&error];
    DDLogDebug(@"result %@, %@", resultNodes[0], [resultNodes[0] attributeForName:@"value"]);
    
    self.completion([[resultNodes[0] attributeForName:@"value"] stringValue]);
}

@end
