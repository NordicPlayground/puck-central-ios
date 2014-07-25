
#import <Foundation/Foundation.h>

@interface Trigger : NSObject

@property (nonatomic, retain) NSString *displayName;
@property (nonatomic, retain) NSString *notificationString;
@property (nonatomic, retain) NSNumber *identifier;

- (id)initWithDisplayName:(NSString *)displayName forNotification:(NSString *)notificationString;

@end
