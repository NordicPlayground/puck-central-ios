
@import UIKit;

#import <XLForm/XLForm.h>

@class Puck;

@interface NSPConfigureActionViewController : XLFormViewController

- (id)initWithTrigger:(NSPTrigger)trigger
              andPuck:(Puck *)puck
          andActuator:(Class)actuatorClass;

@end
