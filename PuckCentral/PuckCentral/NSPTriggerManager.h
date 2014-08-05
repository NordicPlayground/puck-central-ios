
#import <Foundation/Foundation.h>

@class Puck;
@class Trigger;

@interface NSPTriggerManager : NSObject

+ (NSPTriggerManager *)sharedManager;
- (void)registerTriggers:(NSArray *)triggers forServiceUUID:(NSUUID *)uuid withPrefix:(int)prefix;
- (NSArray *)triggersForPuck:(Puck *)puck;
- (NSArray *)triggersForNotification:(NSString *)notification;
- (Trigger *)triggerForIdentifier:(NSNumber *)identifier;

@end
