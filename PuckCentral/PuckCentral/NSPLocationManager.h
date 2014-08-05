
@import Foundation;
@import CoreLocation;

@class Puck;

@interface NSPLocationManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) Puck *closestPuck;

+ (NSPLocationManager *)sharedManager;
- (void)forceRestartRanging;
- (void)stopLookingForBeacons;
- (void)startLookingForBeacons;
- (void)updateLocation:(NSArray *)beacons;

@end
