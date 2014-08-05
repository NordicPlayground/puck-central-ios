
@import CoreText;
@import CoreGraphics;

#import "NSPDisplayActuator.h"
#import "NSPUUIDUtils.h"
#import "NSPBluetoothManager.h"
#import "NSPPuckController.h"
#import "NSPGattTransaction.h"
#import "lz.h"
#import "NSPPuckSelector.h"
#import "NSPWeatherService.h"

typedef NS_ENUM(NSUInteger, NSPImageSection) {
    NSPImageSectionUpper,
    NSPImageSectionLower
};

@interface NSPDisplayActuator ()

@property (readonly) NSUUID *SERVICE_DISPLAY_UUID;
@property (readonly) NSUUID *CHARACTERISTIC_COMMAND_UUID;
@property (readonly) NSUUID *CHARACTERISTIC_DATA_UUID;
@property (readonly, assign) Byte COMMAND_BEGIN_IMAGE_UPPER;
@property (readonly, assign) Byte COMMAND_BEGIN_IMAGE_LOWER;
@property (readonly, assign) Byte COMMAND_END_IMAGE_UPPER;
@property (readonly, assign) Byte COMMAND_END_IMAGE_LOWER;

@end

@implementation NSPDisplayActuator

- (id)init
{
    self = [super init];
    if (self) {
        _SERVICE_DISPLAY_UUID = [NSPUUIDUtils stringToUUID:@"bftj display    "];
        _CHARACTERISTIC_COMMAND_UUID = [NSPUUIDUtils stringToUUID:@"bftj display com"];
        _CHARACTERISTIC_DATA_UUID = [NSPUUIDUtils stringToUUID:@"bftj display dat"];
        _COMMAND_BEGIN_IMAGE_UPPER = 4;
        _COMMAND_BEGIN_IMAGE_LOWER = 5;
        _COMMAND_END_IMAGE_UPPER = 2;
        _COMMAND_END_IMAGE_LOWER = 3;
    }
    return self;
}

+ (NSString *)name
{
    return @"Display Actuator";
}

+ (NSNumber *)index
{
    return @4;
}

+ (XLFormDescriptor *)optionsForm
{
    XLFormDescriptor *form = [XLFormDescriptor formDescriptor];
    
    XLFormSectionDescriptor *section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    XLFormRowDescriptor *type = [XLFormRowDescriptor formRowDescriptorWithTag:@"type"
                                                                      rowType:XLFormRowDescriptorTypeSelectorPush
                                                                        title:@"Type"];
    type.required = YES;
    type.selectorOptions = @[@"Space", @"Weather", @"Custom text", @"Email"];
    [section addFormRow:type];
    
    XLFormRowDescriptor *text = [XLFormRowDescriptor formRowDescriptorWithTag:@"text"
                                                                      rowType:XLFormRowDescriptorTypeTextView
                                                                        title:@"Text"];
    text.required = YES;
    [section addFormRow:text];
    
    XLFormRowDescriptor *puckRow = [[NSPPuckSelector alloc] initWithTag:@"minor"
                                                            serviceUUID:[NSPUUIDUtils stringToUUID:NSPDisplayServiceUUIDString]
                                                                  title:@"Puck"];
    puckRow.required = YES;
    [section addFormRow:puckRow];
    
    return form;
}

- (NSString *)stringForOptions:(NSDictionary *)options
{
    return [NSString stringWithFormat:@"Display %@: %@", options[@"type"], options[@"text"]];
}

- (void)actuateOnPuck:(Puck *)puck withOptions:(NSDictionary *)options
{
    if ([options[@"type"] isEqualToString:@"Space"]) {
        [self writeImage:[self renderImage:[UIImage imageNamed:@"display-space"]
                              withHeadline:@"Space count"
                                  andLabel:@"6"]
                  toPuck:puck];
    } else if ([options[@"type"] isEqualToString:@"Custom text"]) {
        [self writeImage:[self render:options[@"text"]] toPuck:puck];
    } else if ([options[@"type"] isEqualToString:@"Weather"]) {
        NSPWeatherService *weatherService = [[NSPWeatherService alloc] init];
        [weatherService currentTemperature:^(NSString *temperature) {
            [self writeImage:[self renderImage:[UIImage imageNamed:@"display-weather"]
                                  withHeadline:@"Weather"
                                      andLabel:temperature]
                      toPuck:puck];
        }];
    } else if ([options[@"type"] isEqualToString:@"Email"]) {
        [self writeImage:[self renderImage:[UIImage imageNamed:@"display-email"]
                              withHeadline:@"Unread email"
                                  andLabel:@"3"]
                  toPuck:puck];
    }
}

- (void)writeImage:(UIImage *)image toPuck:(Puck *)puck
{
    DDLogInfo(@"Write image");
    self.transaction = [[NSPGattTransaction alloc] initWithTimeout:20];
    [self writeImage:image
             section:NSPImageSectionUpper
              toPuck:puck];
    [self writeImage:image
             section:NSPImageSectionLower
              toPuck:puck];
    
    [[NSPBluetoothManager sharedManager] queueTransaction:self.transaction];
}

- (void)writeImage:(UIImage *)image section:(NSPImageSection)section toPuck:(Puck *)puck
{
    Byte beginCommand = (section == NSPImageSectionUpper) ? _COMMAND_BEGIN_IMAGE_UPPER : _COMMAND_BEGIN_IMAGE_LOWER;
    Byte endCommand = (section == NSPImageSectionUpper) ? _COMMAND_END_IMAGE_UPPER : _COMMAND_END_IMAGE_LOWER;
    
    const int max_bytes_per_write = 20;
    
    [self writeValue:[NSData dataWithBytes:&beginCommand length:1]
          forService:_SERVICE_DISPLAY_UUID
      characteristic:_CHARACTERISTIC_COMMAND_UUID
              onPuck:puck];
    
    // Send half the image, and each 8 pixels are grouped in one byte
    int ePaperFormatLength = image.size.width * image.size.height / 2 / 8;
    DDLogDebug(@"length: %d", ePaperFormatLength);
    
    uint8_t ePaperFormat[ePaperFormatLength];
    [self convertImage:image toEPaperFormat:ePaperFormat section:section];
    
    uint8_t unpaddedPayload[ePaperFormatLength * (257/256) + 1]; // Worst case compression is 0.4% + 1 byte larger than insize
    int unpaddedPayloadLength = LZ_Compress(ePaperFormat, unpaddedPayload, ePaperFormatLength);
    DDLogDebug(@"payload size: %d", unpaddedPayloadLength);
    
    int paddingLength = (unpaddedPayloadLength % 20 == 0)
        ? 0
        : 20 - unpaddedPayloadLength % 20;
    int payloadLength = unpaddedPayloadLength + paddingLength;
    uint8_t payload[payloadLength];
    [self padPayload:unpaddedPayload
              output:payload
              length:unpaddedPayloadLength
       paddingLength:paddingLength];
    
    for (int i=0; i < payloadLength; i += max_bytes_per_write) {
        NSData *value = [NSData dataWithBytes:&payload[i]
                                       length:max_bytes_per_write];
        [self writeValue:value
              forService:_SERVICE_DISPLAY_UUID
          characteristic:_CHARACTERISTIC_DATA_UUID
                  onPuck:puck];
    }
    
    [self writeValue:[NSData dataWithBytes:&endCommand length:1]
          forService:_SERVICE_DISPLAY_UUID
      characteristic:_CHARACTERISTIC_COMMAND_UUID
              onPuck:puck];
    
    [self waitForDisconnect:puck];
}

/*! Pads the image data so it can be divided in even groups of 20 byes
 * \param unpaddedPayload The input buffer
 * \param output The output buffer
 * \param length The unpadded length
 * \param paddingLength How many bytes to add
 */
- (void)padPayload:(uint8_t *)unpaddedPayload
            output:(uint8_t *)output
            length:(int)unpaddedPayloadLength
     paddingLength:(int)paddingLength
{
    for (int i = 1; i < unpaddedPayloadLength - 1; i++) {
        if (unpaddedPayload[i] == unpaddedPayload[0] && unpaddedPayload[i + 1] != 0) {
            i++;
            memcpy(&output[0], &unpaddedPayload[0], i);
            for (int j = 0; j < paddingLength; j++) {
                output[i + j] = 0x80;
            }
            memcpy(&output[i + paddingLength], &unpaddedPayload[i], unpaddedPayloadLength - i);
            break;
        }
    }
}

/*! Converts a UIImage to the format necessary for transmitting to the display puck
 * \param image The image you want to transmit
 * \param ePaperFormat The output buffer
 * \param section Which part of the image to convert
 * \return void
 */
- (void)convertImage:(UIImage *)image toEPaperFormat:(uint8_t *)ePaperFormat section:(NSPImageSection)section
{
    int byteCounter = 0;
    int halfHeight = image.size.height / 2;
    int startY = (section == NSPImageSectionLower) ? halfHeight : 0;
    
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const uint8_t *data = CFDataGetBytePtr(pixelData);
    
    long bpr = CGImageGetBytesPerRow(image.CGImage);
    long numberOfChannels = CGImageGetBitsPerPixel(image.CGImage) / 8;
    
    for (int y = startY; y < startY + halfHeight; y++) {
        for (int x = 0; x < image.size.width / 8; x++) {
            long pixelIndex = (bpr * y) + (x * 8 * numberOfChannels);
            uint8_t b = 0;
            for (int i = 0; i < 8; i++) {
                pixelIndex += numberOfChannels;
                if ((data[pixelIndex] + data[(pixelIndex+1)] + data[(pixelIndex+2)]) < (255 * 3 / 2)) {
                    b |= (1 << i);
                }
            }
            ePaperFormat[byteCounter++] = b;
        }
    }
    CFRelease(pixelData);
}

/*! Renders a text string to a UIImage
 * \param text The text string to display
 * \returns The rendered UIImage
 */
- (UIImage *)render:(NSString *)text
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(264.0, 176.0), YES, 1.f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor whiteColor] setFill];
    CGContextFillRect(context, CGRectMake(0.0, 0.0, 264.0, 176.0));
    
    [[UIColor blackColor] set];
    
    CGContextTranslateCTM(context, 0.0, 176.0);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    
    CFStringRef textString = (__bridge CFStringRef)text;
    
    NSDictionary *fontAttributes = @{
                                     (NSString *)kCTFontFamilyNameAttribute: @"Georgia",
                                     (NSString *)kCTFontStyleNameAttribute: @"Regular",
                                     (NSString *)kCTFontSizeAttribute: @36.0,
                                     };
    CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)fontAttributes);
    
    CTFontRef font = CTFontCreateWithFontDescriptor(descriptor, 0.0, NULL);
    
    CFRelease(descriptor);
    
    CFStringRef keys[] = { kCTFontAttributeName };
    CFTypeRef values[] = { font };
    
    CFDictionaryRef attributes =
        CFDictionaryCreate(
                           kCFAllocatorDefault,
                           (const void**)&keys,
                           (const void**)&values,
                           sizeof(keys) / sizeof(keys[0]),
                           &kCFTypeDictionaryKeyCallBacks,
                           &kCFTypeDictionaryValueCallBacks
                           );
    CFAttributedStringRef attrString = CFAttributedStringCreate(kCFAllocatorDefault, textString, attributes);

    
    CFRelease(textString);
    CFRelease(attributes);
    
    CTLineRef line = CTLineCreateWithAttributedString(attrString);
    
    CGRect bounds = CTLineGetBoundsWithOptions(line, kCTLineBoundsUseGlyphPathBounds);
    
    CGContextSetTextPosition(context, 132.0 - bounds.size.width / 2, 88.0 - bounds.size.height / 2);
    CTLineDraw(line, context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)renderImage:(UIImage *)background withHeadline:(NSString *)headline andLabel:(NSString *)label
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(264.0, 176.0), YES, 1.f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0.0, 176.0);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    
    CGContextDrawImage(context, CGRectMake(0.0, 0.0, 264.0, 176.0), background.CGImage);
    
    NSDictionary *fontAttributes = @{
                                     (NSString *)kCTFontFamilyNameAttribute: @"Helvetica",
                                     (NSString *)kCTFontStyleNameAttribute: @"Regular",
                                     (NSString *)kCTFontSizeAttribute: @42,
                                     };
    [self drawText:label
    withAttributes:fontAttributes
           atPoint:CGPointMake(77.0, 80.0)
         withColor:[UIColor whiteColor]
         inContext:context];
    
    fontAttributes = @{
                       (NSString *)kCTFontFamilyNameAttribute: @"Georgia",
                       (NSString *)kCTFontStyleNameAttribute: @"Regular",
                       (NSString *)kCTFontSizeAttribute: @22,
                       };
    [self drawText:headline
    withAttributes:fontAttributes
           atPoint:CGPointMake(77.0, 140.0)
         withColor:[UIColor blackColor]
         inContext:context];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)drawText:(NSString *)text
  withAttributes:(NSDictionary *)fontAttributes
         atPoint:(CGPoint)point
       withColor:(UIColor *)color
       inContext:(CGContextRef)context
{
    CFStringRef textString = (__bridge CFStringRef)text;
    CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)fontAttributes);
    
    CTFontRef font = CTFontCreateWithFontDescriptor(descriptor, 0.0, NULL);
    
    CFRelease(descriptor);
    
    CFStringRef keys[] = { kCTFontAttributeName, kCTForegroundColorAttributeName };
    CFTypeRef values[] = { font, color.CGColor };
    
    CFDictionaryRef attributes =
        CFDictionaryCreate(
                           kCFAllocatorDefault,
                           (const void**)&keys,
                           (const void**)&values,
                           sizeof(keys) / sizeof(keys[0]),
                           &kCFTypeDictionaryKeyCallBacks,
                           &kCFTypeDictionaryValueCallBacks
                           );
    CFAttributedStringRef attrString = CFAttributedStringCreate(kCFAllocatorDefault, textString, attributes);

    
    CFRelease(textString);
    CFRelease(attributes);
    
    CTLineRef line = CTLineCreateWithAttributedString(attrString);
    CGRect bounds = CTLineGetBoundsWithOptions(line, kCTLineBoundsUseGlyphPathBounds);
    
    CGContextSetTextPosition(context, point.x - bounds.size.width / 2, point.y - bounds.size.height / 2);
    CTLineDraw(line, context);
}

@end
