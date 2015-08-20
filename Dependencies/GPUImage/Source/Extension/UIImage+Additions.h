
#import <UIKit/UIKit.h>

#ifndef rgb
#define rgb(r, g, b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1]
#endif

#ifndef bw
#define bw(w) [UIColor colorWithWhite:w/255.0f alpha:1]
#endif

#ifndef Screen4Inch
#define Screen4Inch ([[UIScreen mainScreen] bounds].size.height == 568)
#endif

#ifndef iPad
#define iPad ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#endif

#define ccr(x, y, w, h) CGRectMake(floorf(x), floorf(y), floorf(w), floorf(h))
#define ccp(x, y) CGPointMake(floorf(x), floorf(y))
#define ccs(w, h) CGSizeMake(floorf(w), floorf(h))
#define edi(top, left, bottom, right) UIEdgeInsetsMake(floorf(top), floorf(left), floorf(bottom), floorf(right))

#define WinSize [UIScreen mainScreen].bounds.size


@interface UIImage (OCMAdditions)

- (UIImage *)subImageAtRect:(CGRect)rect;
- (UIImage *)imageRotatedToUp;
- (UIImage *)imageRotatedToUpWithMaxWidth:(CGFloat)maxWidth maxHeight:(CGFloat)maxHeight;
- (CGFloat)largerSize; // max of width & height
- (CGFloat)aspectRatio; // width / height
- (UIImage *)stretchableImageFromCenter;
+ (UIImage *)imageWithName:(NSString *)imageName;

@end
