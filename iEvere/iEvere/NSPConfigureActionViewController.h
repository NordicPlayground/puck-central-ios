
@import UIKit;

#import <XLForm/XLForm.h>

@class Rule;

@interface NSPConfigureActionViewController : XLFormViewController

- (id)initWithRule:(Rule *)rule
       andActuator:(Class)actuatorClass;

@end
