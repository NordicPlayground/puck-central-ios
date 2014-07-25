
#import "NSPConfigureActionViewController.h"
#import "NSPActuator.h"
#import "NSPActionController.h"
#import "NSPRuleController.h"
#import "Rule.h"

@interface NSPConfigureActionViewController () <XLFormDescriptorDelegate>

@property (nonatomic, strong) Rule *rule;
@property (nonatomic, strong) id<NSPActuator> actuator;

@end

@implementation NSPConfigureActionViewController

- (id)initWithRule:(Rule *)rule andActuator:(Class)actuatorClass
{
    self = [super init];
    if (self) {
        self.rule = rule;
        self.actuator = [[actuatorClass alloc] init];
        
        self.form = [actuatorClass optionsForm];
        self.form.delegate = self;
        if ([self.actuator conformsToProtocol:@protocol(NSPConfigureActionFormDelegate)]) {
            self.delegate = (id<NSPConfigureActionFormDelegate>)self.actuator;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *donebutton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(done)];
    self.navigationItem.rightBarButtonItem = donebutton;
}

- (void)done
{
    NSArray *errors = [self formValidationErrors];
    if (errors.count > 0) {
        NSLog(@"Errors");
        [self showFormValidationError:[errors firstObject]];
        return;
    }

    NSNumber *actuatorId = [[self.actuator class] index];
    
    NSPActionController *actionController = [NSPActionController sharedController];
    
    Action *action = [actionController insertAction:actuatorId withOptions:self.httpParameters];
    
    NSPRuleController *ruleController = [NSPRuleController sharedController];
    [ruleController conditionalInsertRule:self.rule];
    [self.rule addActionsObject:action];
    
    NSError *error;
    [[ruleController managedObjectContext] save:&error];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - XLFormDescriptorDelegate protocol

- (void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)formRow oldValue:(id)oldValue newValue:(id)newValue
{
    [super formRowDescriptorValueHasChanged:formRow oldValue:oldValue newValue:newValue];
    
    if (self.delegate != nil) {
        [self.delegate form:self didUpdateRow:formRow from:oldValue to:newValue];
    }
}

- (void)formRowHasBeenAdded:(XLFormRowDescriptor *)formRow atIndexPath:(NSIndexPath *)indexPath
{
    [super formRowHasBeenAdded:formRow atIndexPath:indexPath];
}

- (void)formRowHasBeenRemoved:(XLFormRowDescriptor *)formRow atIndexPath:(NSIndexPath *)indexPath
{
    [super formRowHasBeenRemoved:formRow atIndexPath:indexPath];
}

- (void)formSectionHasBeenAdded:(XLFormSectionDescriptor *)formSection atIndex:(NSUInteger)index
{
    [super formSectionHasBeenAdded:formSection atIndex:index];
}

- (void)formSectionHasBeenRemoved:(XLFormSectionDescriptor *)formSection atIndex:(NSUInteger)index
{
    [super formSectionHasBeenRemoved:formSection atIndex:index];
}

#pragma mark - NSObject

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
