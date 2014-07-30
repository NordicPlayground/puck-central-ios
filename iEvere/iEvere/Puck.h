
@import Foundation;
@import CoreData;
@import CoreLocation;

#import <XLForm/XLForm.h>

@class ServiceUUID;

typedef NS_ENUM(NSUInteger, PuckConnectedState) {
    DISCONNECTED,
    PENDING,
    CONNECTED,
};

@interface Puck : NSManagedObject <XLFormOptionObject>

@property (nonatomic, retain) NSNumber *major;
@property (nonatomic, retain) NSNumber *minor;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *proximityUUID;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSOrderedSet *rules;
@property (nonatomic, retain) NSSet *serviceIDs;
@property (nonatomic, assign) PuckConnectedState connectedState;

- (void)addServiceIDs:(NSSet *)objects;
- (void)addServiceIDsObject:(ServiceUUID *)object;

+ (instancetype)puckForBeacon:(CLBeacon *)beacon;
+ (instancetype)puckWithMinorNumber:(NSNumber *)minor;

- (NSUUID *)UUID;

@end
