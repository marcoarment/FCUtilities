//
//  UIColor+FCUtilities.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <UIKit/UIKit.h>


#define fc_UIColorFromRGB(r, g, b)     [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f]
#define fc_UIColorFromRGBA(r, g, b, a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define fc_UIColorFromHexInt(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface UIColor (FCUtilities)

- (UIColor *)fc_colorByModifyingRGBA:(void (^)(CGFloat *red, CGFloat *green, CGFloat *blue, CGFloat *alpha))modifyingBlock;
- (UIColor *)fc_colorByModifyingHSBA:(void (^)(CGFloat *hue, CGFloat *saturation, CGFloat *brightness, CGFloat *alpha))modifyingBlock;
- (NSString *)fc_CSSColor;
+ (UIColor *)fc_colorWithHexString:(NSString *)hexString;

@end
