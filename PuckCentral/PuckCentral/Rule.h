
@import Foundation;
@import CoreData;

@class Puck;
@class Action;

@interface Rule : NSManagedObject

@property (nonatomic, retain) NSNumber *trigger;
@property (nonatomic, retain) Puck *puck;
@property (nonatomic, retain) NSSet *actions;

- (void)addActionsObject:(Action *)object;
- (void)addActions:(NSSet *)objects;

@end
