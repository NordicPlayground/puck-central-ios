
#import "NSPRuleTableViewCell.h"
#import "Action.h"
#import "NSPActuator.h"
#import "NSPActuatorController.h"

@implementation NSPRuleTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        CGSize size = self.contentView.frame.size;
        
        self.triggerLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.f, 8.f, size.width - 16.f, 28.f)];
        [self.triggerLabel setFont:[UIFont boldSystemFontOfSize:20.f]];
        
        [self.contentView addSubview:self.triggerLabel];
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setActions:(NSArray *)actions
{
    CGSize size = self.contentView.frame.size;
    int i = 0;
    for (Action *action in actions) {
        UILabel *actionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16.f, 20.f * i + 36.f, size.width - 16.f, 18.f)];
        Class actuatorClass = [[NSPActuatorController actuators] objectForKey:action.actuatorId];
        if ([actuatorClass conformsToProtocol:@protocol(NSPActuator)]) {
            actionLabel.text = [actuatorClass name];
        }
        actionLabel.text = [actuatorClass name];
        [self.contentView addSubview:actionLabel];
        i++;
    }
}

@end
