
#import "NSPTriggerManager.h"
#import "Trigger.h"
#import "NSPUUIDUtils.h"
#import "ServiceUUID.h"
#import "Puck.h"

@interface NSPTriggerManager ()

@property (nonatomic, strong) NSMutableDictionary *triggers;
@property (nonatomic, strong) NSMutableDictionary *triggersForNotification;

@end

@implementation NSPTriggerManager

+ (NSPTriggerManager *)sharedManager
{
    static NSPTriggerManager *sharedManager;

    @synchronized(self) {
        if (!sharedManager) {
            sharedManager = [[NSPTriggerManager alloc] init];
        }
        return sharedManager;
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.triggers = [[NSMutableDictionary alloc] init];
        self.triggersForNotification = [[NSMutableDictionary alloc] init];

        [self registerTriggers:@[
                                 [[Trigger alloc] initWithDisplayName:@"Enter zone"
                                               forNotification:NSPDidEnterZone],

                                 [[Trigger alloc] initWithDisplayName:@"Leave zone"
                                               forNotification:NSPDidLeaveZone]
                                 ]
                forServiceUUID:[NSPUUIDUtils stringToUUID:NSPServiceUUIDString]
                    withPrefix:NSPTRIGGER_LOCATION];
    }
    return self;
}

- (Trigger *)triggerForIdentifier:(NSNumber *)identifier
{
    __block Trigger *trigger = nil;
    [self.triggers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        for(Trigger *elem in [self.triggers objectForKey:key]) {
            if([elem.identifier isEqual:identifier]) {
                trigger = elem;
            }
        }
    }];

    return trigger;
}

- (NSArray *)triggersForNotification:(NSString *)notification
{
    return self.triggersForNotification[notification];
}

- (NSArray *)triggersForService:(NSUUID *)uuid
{
    return [self.triggers objectForKey:uuid.UUIDString];
}

- (NSArray *)triggersForPuck:(Puck *)puck
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for(ServiceUUID *serviceUUID in puck.serviceIDs) {
        [array addObjectsFromArray:[self triggersForService:[[NSUUID alloc] initWithUUIDString:serviceUUID.uuid]]];
    }
    NSMutableArray *returnValues = [self standardTriggersForPuck];
    [returnValues addObjectsFromArray:array];
    return returnValues;
}

- (NSMutableArray *)standardTriggersForPuck
{
    return [NSMutableArray arrayWithArray:[self triggersForService:[NSPUUIDUtils stringToUUID:NSPServiceUUIDString]]];
}

- (void)registerTriggers:(NSArray *)triggers forServiceUUID:(NSUUID *)uuid withPrefix:(int)prefix
{
    [triggers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if([obj isKindOfClass:[Trigger class]]) {
            Trigger *trigger = (Trigger *)obj;
            trigger.identifier = [NSNumber numberWithUnsignedLong:idx + (1 << prefix)];

            if([self.triggersForNotification objectForKey:trigger.notificationString]) {
                [self.triggersForNotification[trigger.notificationString] addObject:trigger];
            } else {
                [self.triggersForNotification setObject:[NSMutableArray arrayWithObject:trigger]
                                                forKey:trigger.notificationString];
            }
        }
    }];
    [self.triggers setObject:triggers forKey:uuid.UUIDString];
}

@end
