
@import Foundation;
@import CoreData;
@import CoreLocation;

@class ServiceUUID;

@interface Puck : NSManagedObject

@property (nonatomic, retain) NSNumber *major;
@property (nonatomic, retain) NSNumber *minor;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *proximityUUID;
@property (nonatomic, retain) NSOrderedSet *rules;
@property (nonatomic, retain) NSSet *serviceIDs;

- (void)addServiceIDs:(NSSet *)objects;
- (void)addServiceIDsObject:(ServiceUUID *)object;

+ (instancetype)puckForBeacon:(CLBeacon *)beacon;

@end
