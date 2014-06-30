
@import CoreLocation;

#import "NSPLocationManager.h"
#import "LocationPuck.h"

static const int THROTTLE = 3;

@interface NSPLocationManager ()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSDate *lastChanged;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;

@end

@implementation NSPLocationManager

+ (NSPLocationManager *)sharedManager
{
    static NSPLocationManager *sharedManager;
    
    @synchronized(self) {
        if (!sharedManager) {
            sharedManager = [[NSPLocationManager alloc] init];
        }
        return sharedManager;
    }
}

- (id)init
{
    if (self = [super init]) {
        self.lastChanged = [[NSDate alloc] init];
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;

        NSUUID *beaconUUID = [[NSUUID alloc] initWithUUIDString:@"E20A39F4-73F5-4BC4-A12F-17D1AD07A961"];
        CLBeaconMajorValue major = 0x1337;
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID
                                                                    major:major
                                                               identifier:@"Puck"];
        self.beaconRegion.notifyEntryStateOnDisplay = YES;
        [self.locationManager startMonitoringForRegion:self.beaconRegion];
        NSLog(@"Start monitoring");
    }
    return self;
}

- (void)forceRestartRanging
{
    [self.locationManager stopMonitoringForRegion:self.beaconRegion];
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    
    NSLog(@"Force restarted");
}

- (void)updateLocation:(NSArray *)beacons
{
    if ([[NSDate date] timeIntervalSinceDate:self.lastChanged] < THROTTLE) {
        return;
    }
    
    if (beacons.count == 0) {
        [self setLocation:nil];
        return;
    }
    
    beacons = [beacons sortedArrayUsingComparator:^NSComparisonResult(CLBeacon *beacon1, CLBeacon *beacon2) {
        return beacon1.accuracy - beacon2.accuracy < 0 ? 1 : -1;
    }];
    
    for (CLBeacon *beacon in beacons) {
        if (beacon.proximity == CLProximityImmediate) {
            [self setLocation:beacon];
            return;
        }
    }
    
    for (CLBeacon *beacon in beacons) {
        if (beacon.proximity == CLProximityNear) {
            [self setLocation:beacon];
            return;
        }
    }
}

- (void)setLocation:(CLBeacon *)beacon
{
    NSLog(@"setLocation");
    self.lastChanged = [[NSDate alloc] init];
    
    if (beacon == nil) {
        [self leaveCurrentZone];
        return;
    }
    
    LocationPuck *locationPuck = [LocationPuck puckForBeacon:beacon];
    if (locationPuck == nil) {
        NSLog(@"Found new beacon");
        if (beacon.proximity == CLProximityImmediate) {
            NSLog(@"Found immediate beacon");
            [[NSNotificationCenter defaultCenter] postNotificationName:NSPDidFindNewBeacon
                                                                object:self
                                                              userInfo:@{
                                                                         @"beacon": beacon
                                                                         }];
        } else {
            [self leaveCurrentZone];
        }
    } else if (![locationPuck isEqual:self.closestPuck]) {
        [self leaveCurrentZone];
        self.closestPuck = locationPuck;
        [self enterCurrentZone];
    }
}

- (void)leaveCurrentZone
{
    if (self.closestPuck == nil) {
        return;
    }
    
    // Trigger leave zone
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSPDidLeaveZone
                                                        object:self];
    
    self.closestPuck = nil;
}

- (void)enterCurrentZone
{
    // Trigger enter zone
    NSLog(@"Enter zone");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSPDidEnterZone
                                                        object:self
                                                      userInfo:@{
                                                                 @"title": self.closestPuck.name
                                                                 }];
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"Did start monitoring region");
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"Monitoring failed");
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"Did enter region");
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"Did leave region");
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region
{
    NSLog(@"Did range beacons %ld", beacons.count);
    [self updateLocation:beacons];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"Ranging did fail");
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Failed with error: %@", error);
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    NSLog(@"Did pause");
}

- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state
              forRegion:(CLRegion *)region
{
    NSLog(@"Did determine state");
    if (state == CLRegionStateInside) {
        [_locationManager startRangingBeaconsInRegion:self.beaconRegion];
    }
}

@end
