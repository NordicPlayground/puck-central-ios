
#import "NSPUUIDUtils.h"
#import "ServiceUUID.h"

@import Foundation;
@import CoreBluetooth;

@interface NSPServiceUUIDController : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

+ (NSPServiceUUIDController *)sharedController;
- (ServiceUUID *)addOrGetServiceID:(NSString *)uuid;
- (NSFetchRequest *)fetchRequest;

@end
