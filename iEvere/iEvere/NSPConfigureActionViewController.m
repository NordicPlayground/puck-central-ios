
#import "NSPConfigureActionViewController.h"
#import "NSPActuator.h"
#import "NSPActionController.h"
#import "NSPRuleController.h"
#import "Rule.h"

@interface NSPConfigureActionViewController ()

@property (nonatomic, assign) NSPTrigger trigger;
@property (nonatomic, strong) Puck *puck;
@property (nonatomic, strong) Class actuatorClass;

@end

@implementation NSPConfigureActionViewController

- (id)initWithTrigger:(NSPTrigger)trigger andPuck:(Puck *)puck andActuator:(Class)actuatorClass
{
    self = [super init];
    if (self) {
        self.trigger = trigger;
        self.puck = puck;
        self.actuatorClass = actuatorClass;
        
        self.form = [actuatorClass optionsForm];
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
    NSNumber *actuatorId = [self.actuatorClass index];
    
    NSPActionController *actionController = [NSPActionController sharedController];
    
    Action *action = [actionController insertAction:actuatorId withOptions:[self formValues]];
    
    NSPRuleController *ruleController = [NSPRuleController sharedController];
    Rule *rule = [ruleController insertRuleWithTrigger:@(self.trigger)
                                                  puck:self.puck];
    [rule addActionsObject:action];
    
    NSError *error;
    [[ruleController managedObjectContext] save:&error];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark NSObject

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
