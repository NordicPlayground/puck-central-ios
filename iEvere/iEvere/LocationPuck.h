
@import Foundation;
@import CoreData;
@import CoreLocation;


@interface LocationPuck : NSManagedObject

@property (nonatomic, retain) NSNumber *major;
@property (nonatomic, retain) NSNumber *minor;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *proximityUUID;

+ (instancetype)puckForBeacon:(CLBeacon *)beacon;

@end
