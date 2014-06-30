
@import Foundation;

@class LocationPuck;

@interface NSPLocationManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) LocationPuck *closestPuck;

- (void)forceRestartRanging;

@end
