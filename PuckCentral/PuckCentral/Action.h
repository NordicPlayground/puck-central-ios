
@import Foundation;
@import CoreData;

@class Rule;

@interface Action : NSManagedObject

@property (nonatomic, retain) NSNumber * actuatorId;
@property (nonatomic, retain) NSString * options;
@property (nonatomic, retain) Rule *rule;

-(NSDictionary *)decodedOptions;

@end
