//
//  FCOpenInSafariActivity.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCOpenInSafariActivity.h"

NSString *const FCActivityTypeOpenInSafari = @"FCActivityTypeOpenInSafari";

@interface FCOpenInSafariActivity ()
@property (nonatomic) NSURL *URL;
@end

@implementation FCOpenInSafariActivity

- (NSString *)activityType  { return FCActivityTypeOpenInSafari; }
- (NSString *)activityTitle { return NSLocalizedString(@"Open in Safari", NULL); }
- (UIImage *)activityImage  { return [self.class alphaSafariIconWithWidth:52 scale:UIScreen.mainScreen.scale]; }

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    for (id item in activityItems) {
        if ([item isKindOfClass:NSString.class]) {
            NSURL *u = [NSURL URLWithString:item];
            if (u && ! u.isFileURL) return YES;
        } else if ([item isKindOfClass:NSURL.class]) {
            if (! ((NSURL *)item).isFileURL) return YES;
        }
    }
    
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    NSURL *stringURL = nil;
    NSURL *URL = nil;
    for (id item in activityItems) {
        if ([item isKindOfClass:NSString.class]) {
            NSURL *u = [NSURL URLWithString:item];
            if (u && ! u.isFileURL) stringURL = u;
        } else if (! URL && [item isKindOfClass:NSURL.class]) {
            if (! ((NSURL *)item).isFileURL) URL = item;
        }
    }
    
    self.URL = URL ?: stringURL;
}

- (void)performActivity { [self activityDidFinish:[UIApplication.sharedApplication openURL:self.URL]]; }

+ (UIImage *)alphaSafariIconWithWidth:(CGFloat)width scale:(CGFloat)scale
{
    CGFloat halfWidth = width / 2.0f;
    CGFloat triangleTipToCircleGap = ceilf(0.012 * width);
    CGFloat triangleBaseHalfWidth = ceilf(0.125 * width) / 2.0;
    CGFloat tickMarkToCircleGap = ceilf(0.0325 * width);
    CGFloat tickMarkLengthLong = ceilf(0.08 * width);
    CGFloat tickMarkLengthShort = ceilf(0.045 * width);
    CGFloat tickMarkWidth = 1.0f / scale;
    CGFloat tickMarkHalfWidth = tickMarkWidth / 2.0f;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, width), NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Outer circle with gradient fill
    CGFloat colors[] = {
        0.0, 0.0, 0.0, 0.25,
        0.0, 0.0, 0.0, 0.50
    };
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, NULL, 2);
    CGColorSpaceRelease(baseSpace);
    CGContextSaveGState(context);
    {
        CGContextAddEllipseInRect(context, CGRectMake(0, 0, width, width));
        CGContextClip(context);
        CGContextDrawLinearGradient(context, gradient, CGPointMake(halfWidth, 0), CGPointMake(halfWidth, width), 0);
        CGGradientRelease(gradient);
    }
    CGContextRestoreGState(context);

    // Tick lines around the circle
    [[UIColor colorWithWhite:0.0 alpha:0.5] setStroke];
    int numTickLines = 72;
    for (int i = 0; i < numTickLines; i++) {
        CGContextSaveGState(context);
        {
            CGContextSetBlendMode(context, kCGBlendModeClear);
            
            CGContextTranslateCTM(context, halfWidth, halfWidth);
            CGContextRotateCTM(context, 2 * M_PI * ((float) i / numTickLines));
            CGContextTranslateCTM(context, -halfWidth, -halfWidth);
            
            UIBezierPath *tickLine = UIBezierPath.bezierPath;
            [tickLine moveToPoint:CGPointMake(halfWidth - tickMarkHalfWidth, tickMarkToCircleGap)];
            [tickLine addLineToPoint:CGPointMake(halfWidth - tickMarkHalfWidth, tickMarkToCircleGap + (i % 2 == 1 ? tickMarkLengthShort : tickMarkLengthLong))];
            tickLine.lineWidth = tickMarkWidth;
            [tickLine stroke];
        }
        CGContextRestoreGState(context);
    }

    // "Needle" triangles
    CGContextSaveGState(context);
    {
        CGContextTranslateCTM(context, halfWidth, halfWidth);
        CGContextRotateCTM(context, M_PI + M_PI_4);
        CGContextTranslateCTM(context, -halfWidth, -halfWidth);

        [UIColor.blackColor setFill];

        UIBezierPath *topTriangle = UIBezierPath.bezierPath;
        [topTriangle moveToPoint:CGPointMake(halfWidth, triangleTipToCircleGap)];
        [topTriangle addLineToPoint:CGPointMake(halfWidth - triangleBaseHalfWidth, halfWidth)];
        [topTriangle addLineToPoint:CGPointMake(halfWidth + triangleBaseHalfWidth, halfWidth)];
        [topTriangle closePath];

        CGContextSetBlendMode(context, kCGBlendModeClear);
        [topTriangle fill];

        UIBezierPath *bottomTriangle = UIBezierPath.bezierPath;
        [bottomTriangle moveToPoint:CGPointMake(halfWidth, width - triangleTipToCircleGap)];
        [bottomTriangle addLineToPoint:CGPointMake(halfWidth - triangleBaseHalfWidth, halfWidth)];
        [bottomTriangle addLineToPoint:CGPointMake(halfWidth + triangleBaseHalfWidth, halfWidth)];
        [bottomTriangle closePath];
        
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        [bottomTriangle fill];
    }
    CGContextRestoreGState(context);

    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return finalImage;
}

@end
