
@import UIKit;

#import <XLForm/XLForm.h>

@class Rule;

@protocol NSPConfigureActionFormDelegate <NSObject>

- (void)form:(XLFormViewController *)formViewController didUpdateRow:(XLFormRowDescriptor *)row from:(id)oldValue to:(id)newValue;

@end

@interface NSPConfigureActionViewController : XLFormViewController

@property (nonatomic, weak) id<NSPConfigureActionFormDelegate> delegate;

- (id)initWithRule:(Rule *)rule
       andActuator:(Class)actuatorClass;

@end
