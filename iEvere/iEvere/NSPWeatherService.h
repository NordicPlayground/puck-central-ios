
typedef void (^NSPWeatherServiceResults)(NSString *);

@interface NSPWeatherService : NSObject

- (void)currentTemperature:(NSPWeatherServiceResults)completion;

@end
