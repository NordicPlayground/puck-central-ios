
@import CoreData;

@interface ServiceUUID : NSManagedObject

@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, retain) NSSet *pucks;

@end
