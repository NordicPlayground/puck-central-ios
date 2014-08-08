
@import MediaPlayer;

#import "NSPMusicActuator.h"

typedef NS_ENUM(NSUInteger, NSPMusicOptions) {
    NSPMusicOptionsPlay,
    NSPMusicOptionsPause
};

@implementation NSPMusicActuator

+ (NSNumber *)index
{
    return @(3);
}

+ (NSString *)name
{
    return @"Music Playback";
}

+ (XLFormDescriptor *)optionsForm
{
    XLFormDescriptor *form = [XLFormDescriptor formDescriptor];
    
    XLFormSectionDescriptor *section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    XLFormRowDescriptor *playPause = [XLFormRowDescriptor formRowDescriptorWithTag:@"playPause"
                                                                           rowType:XLFormRowDescriptorTypeSelectorPush
                                                                             title:@"Action"];
    playPause.selectorOptions = @[
                                  [XLFormOptionsObject formOptionsObjectWithValue:@(NSPMusicOptionsPlay)
                                                                      displayText:@"Start playing music"],
                                  [XLFormOptionsObject formOptionsObjectWithValue:@(NSPMusicOptionsPause)
                                                                      displayText:@"Stop playing music"]
                                  ];
    playPause.required = YES;
    [section addFormRow:playPause];
    
    return form;
}

- (NSString *)stringForOptions:(NSDictionary *)options
{
    NSString *info = @"";
    switch ([options[@"playPause"] intValue]) {
        case NSPMusicOptionsPlay:
            info = @"on";
            break;
        case NSPMusicOptionsPause:
            info = @"off";
            break;
    }
    return [NSString stringWithFormat:@"Turns music %@", info];
}

- (void)actuate:(NSDictionary *)options
{
    switch ([options[@"playPause"] intValue]) {
        case NSPMusicOptionsPlay:
            [[MPMusicPlayerController iPodMusicPlayer] play];
            break;
        case NSPMusicOptionsPause:
            [[MPMusicPlayerController iPodMusicPlayer] pause];
            break;
        default:
            break;
    }
}

@end
