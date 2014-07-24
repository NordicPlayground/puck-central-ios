
@import CoreText;
@import CoreGraphics;

#import "NSPDisplayActuator.h"
#import "NSPUUIDUtils.h"
#import "NSPGattWriteOperation.h"
#import "NSPBluetoothManager.h"
#import "NSPServiceUUIDController.h"
#import "NSPPuckController.h"
#import "lz.h"
#import "NSPLocationManager.h"

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
    
    XLFormRowDescriptor *text = [XLFormRowDescriptor formRowDescriptorWithTag:@"text"
                                                                      rowType:XLFormRowDescriptorTypeTextView
                                                                        title:@"Text"];
    
    text.required = YES;
    [section addFormRow:text];
    
    XLFormRowDescriptor *minorNumRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"minor"
                                                                             rowType:XLFormRowDescriptorTypeSelectorPush
                                                                               title:@"Puck"];
    minorNumRow.required = YES;
    NSFetchRequest *fetchRequest = [[NSPServiceUUIDController sharedController] fetchRequest];
    CBUUID *displayServiceUUID = [CBUUID UUIDWithNSUUID:[NSPUUIDUtils stringToUUID:NSPDisplayServiceUUIDString]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", displayServiceUUID.UUIDString]];
    NSError *error;
    NSArray *service = [[[NSPServiceUUIDController sharedController] managedObjectContext] executeFetchRequest:fetchRequest
                                                                                                       error:&error];
    if (service != nil && service.count > 0) {
        minorNumRow.selectorOptions = [[service[0] pucks] allObjects];
    } else {
        NSLog(@"Error: %@", error);
    }
    [section addFormRow:minorNumRow];
    
    return form;
}

- (NSString *)stringForOptions:(NSDictionary *)options
{
    return [NSString stringWithFormat:@"Display %@", options[@"text"]];
}

- (void)actuateOnPuck:(Puck *)puck withOptions:(NSDictionary *)options
{
    [[NSPLocationManager sharedManager] startUsingPuck:puck];
    
    UIImage *image = [self render:options[@"text"]];
    
    NSLog(@"Write image");
    [self writeImage:image
             section:NSPImageSectionUpper
              toPuck:puck];
    [self writeImage:image
             section:NSPImageSectionLower
              toPuck:puck];
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
    
    uint8_t *ePaperFormat = [self imageToEPaperFormat:image section:section];
    
    // Send half the image, and each 8 pixels are grouped in one byte
    int ePaperFormatLength = image.size.width * image.size.height / 2 / 8;
    
    uint8_t payload[ePaperFormatLength * (257/256) + 1]; // Worst case compression is 0.4% + 1 byte larger than insize
    int payloadLength = LZ_Compress(ePaperFormat, payload, ePaperFormatLength);
    
    for (int i=0; i < payloadLength; i += max_bytes_per_write) {
        NSData *value = [NSData dataWithBytes:(payload+i)
                                       length:MIN(max_bytes_per_write, payloadLength - i)];
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

/*! Converts a UIImage to the format necessary for transmitting to the display puck
 * \param image The image you want to transmit
 * \param section Which part of the image to convert
 * \return a byte array where each byte represents 8 pixels' on/off value
 */
- (uint8_t *)imageToEPaperFormat:(UIImage *)image section:(NSPImageSection)section
{
    int byteCounter = 0;
    int halfHeight = image.size.height / 2;
    int startY = (section == NSPImageSectionLower) ? halfHeight : 0;
    
    int numberOfBytes = image.size.width / 8 * halfHeight;
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    const uint8_t *data = CFDataGetBytePtr(pixelData);
    
    long bpr = CGImageGetBytesPerRow(image.CGImage);
    long numberOfChannels = CGImageGetBitsPerPixel(image.CGImage) / 8;
    
    uint8_t *value = malloc(sizeof(uint8_t) * numberOfBytes);
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
            value[byteCounter++] = b;
        }
    }
    CFRelease(pixelData);
    return value;
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

@end
