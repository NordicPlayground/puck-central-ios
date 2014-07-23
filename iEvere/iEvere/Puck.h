
@import Foundation;
@import CoreData;
@import CoreLocation;

#import <XLForm/XLForm.h>

@class ServiceUUID;

@interface Puck : NSManagedObject <XLFormOptionObject>

@property (nonatomic, retain) NSNumber *major;
@property (nonatomic, retain) NSNumber *minor;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *proximityUUID;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSOrderedSet *rules;
@property (nonatomic, retain) NSSet *serviceIDs;

- (void)addServiceIDs:(NSSet *)objects;
- (void)addServiceIDsObject:(ServiceUUID *)object;

+ (instancetype)puckForBeacon:(CLBeacon *)beacon;

- (NSUUID *)UUID;

@end
