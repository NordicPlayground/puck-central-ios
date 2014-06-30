
@import Foundation;
@import CoreLocation;

@class Puck;

@interface NSPLocationManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) Puck *closestPuck;

+ (NSPLocationManager *)sharedManager;
- (void)forceRestartRanging;
- (void)updateLocation:(NSArray *)beacons;

@end
