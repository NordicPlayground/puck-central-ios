
@import Foundation;
@import CoreData;
@import CoreLocation;


@interface Puck : NSManagedObject

@property (nonatomic, retain) NSNumber *major;
@property (nonatomic, retain) NSNumber *minor;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *proximityUUID;
@property (nonatomic, retain) NSOrderedSet *rules;

+ (instancetype)puckForBeacon:(CLBeacon *)beacon;

@end
