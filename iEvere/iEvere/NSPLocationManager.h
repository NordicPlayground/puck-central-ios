
@import Foundation;
@import CoreLocation;

@class LocationPuck;

@interface NSPLocationManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) LocationPuck *closestPuck;

+ (NSPLocationManager *)sharedManager;
- (void)forceRestartRanging;
- (void)updateLocation:(NSArray *)beacons;

@end
