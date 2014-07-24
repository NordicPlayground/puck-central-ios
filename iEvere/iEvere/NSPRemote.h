
@import Foundation;

#import <XLForm/XLForm.h>

@interface NSPRemote : NSObject <XLFormOptionObject>

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSArray *header;
@property (nonatomic, strong) NSArray *one;
@property (nonatomic, strong) NSArray *zero;
@property (nonatomic, assign) NSInteger predata;
@property (nonatomic, assign) NSInteger ptrail;

@property (nonatomic, strong) NSArray *codes;

- (id)initWithName:(NSString *)name;

@end
