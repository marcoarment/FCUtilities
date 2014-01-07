//
//  UIColor+FCUtilities.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "UIColor+FCUtilities.h"

@implementation UIColor (FCUtilities)

- (UIColor *)fc_colorByModifyingRGBA:(void (^)(CGFloat *red, CGFloat *green, CGFloat *blue, CGFloat *alpha))modifyingBlock
{
    CGFloat red, green, blue, alpha;
    
    if (! [self getRed:&red green:&green blue:&blue alpha:&alpha]) {
        if ([self getWhite:&red alpha:&alpha]) {
            green = red;
            blue = red;
        } else {
            [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Color is not in a decomposable format" userInfo:nil] raise];
        }
    }

    modifyingBlock(&red, &green, &blue, &alpha);
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (UIColor *)fc_colorByModifyingHSBA:(void (^)(CGFloat *hue, CGFloat *saturation, CGFloat *brightness, CGFloat *alpha))modifyingBlock
{
    CGFloat hue, saturation, brightness, alpha;
    
    if (! [self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        if ([self getWhite:&brightness alpha:&alpha]) {
            hue = 0;
            saturation = 0;
        } else {
            [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Color is not in a decomposable format" userInfo:nil] raise];
        }
    }

    modifyingBlock(&hue, &saturation, &brightness, &alpha);
    hue = MAX(0.0f, MIN(1.0f, hue));
    saturation = MAX(0.0f, MIN(1.0f, saturation));
    brightness = MAX(0.0f, MIN(1.0f, brightness));
    alpha = MAX(0.0f, MIN(1.0f, alpha));
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

- (NSString *)fc_CSSColor
{
    CGFloat r, g, b, a;
    if ([self getRed:&r green:&g blue:&b alpha:&a]) {
        return [NSString stringWithFormat:@"rgba(%d, %d, %d, %g)", (int) (r * 255.0f), (int) (g * 255.0f), (int) (b * 255.0f), a];
    } else if ([self getWhite:&r alpha:&a]) {
        return [NSString stringWithFormat:@"rgba(%d, %d, %d, %g)", (int) (r * 255.0f), (int) (r * 255.0f), (int) (r * 255.0f), a];
    } else {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Cannot convert this color space to CSS color" userInfo:nil] raise];
        return nil;
    }
}

+ (UIColor *)fc_colorWithHexString:(NSString *)hexString
{
	unsigned hexNum;
	if (! [[NSScanner scannerWithString:hexString] scanHexInt:&hexNum]) return nil;
	return fc_UIColorFromHexInt(hexNum);
}


@end
