
#import "NSPRuleTableViewCell.h"
#import "Action.h"
#import "NSPActuator.h"
#import "NSPActuatorController.h"

@interface NSPRuleTableViewCell ()

@property (nonatomic, strong) UIView *actionsView;

@end

@implementation NSPRuleTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        CGSize size = self.contentView.frame.size;
        
        self.triggerLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.f, 8.f, size.width - 16.f, 28.f)];
        [self.triggerLabel setFont:[UIFont boldSystemFontOfSize:20.f]];
        
        [self.contentView addSubview:self.triggerLabel];
        
        self.actionsView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 36.f, size.width, size.height)];
        [self.contentView addSubview:self.actionsView];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setActions:(NSArray *)actions
{
    for (UIView *actionLabel in self.actionsView.subviews) {
        [actionLabel removeFromSuperview];
    }
    
    CGSize size = self.contentView.frame.size;
    int i = 0;
    for (Action *action in actions) {
        UILabel *actionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.f, 20.f * i, size.width - 16.f, 18.f)];
        actionLabel.font = [UIFont systemFontOfSize:14.f];
        
        Class actuatorClass = [[NSPActuatorController actuators] objectForKey:action.actuatorId];
        if ([actuatorClass conformsToProtocol:@protocol(NSPActuator)]) {
            id<NSPActuator> actuator = [[actuatorClass alloc] init];
            actionLabel.text = [NSString stringWithFormat:@"%@: %@", [actuatorClass name],
                                [actuator stringForOptions:[action decodedOptions]]];
        }
        [self.actionsView addSubview:actionLabel];
        i++;
    }
}

@end
