
@import Foundation;

@class Puck;

@interface NSPCubeManager : NSObject

+ (NSPCubeManager *)sharedManager;
- (void)checkAndConnectToCubePuck:(Puck *)puck;

@end
