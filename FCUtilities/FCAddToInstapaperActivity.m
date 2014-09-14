//
//  FCAddToInstapaperActivity.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCAddToInstapaperActivity.h"

NSString *const FCActivityTypeAddToInstapaper = @"FCActivityTypeAddToInstapaper";

@interface FCAddToInstapaperActivity ()
@property (nonatomic) NSURL *URL;
@property (nonatomic, copy) NSString *xCallbackSource;
@property (nonatomic) NSURL *xCallbackSuccessURL;
@end

@implementation FCAddToInstapaperActivity

- (instancetype)initWithSourceName:(NSString *)xCallbackSource successCallbackURL:(NSURL *)xCallbackURL
{
    if ( (self = [super init]) ) {
        self.xCallbackSource = xCallbackSource;
        self.xCallbackSuccessURL = xCallbackURL;
    }
    return self;
}

- (NSString *)activityType  { return FCActivityTypeAddToInstapaper; }
- (NSString *)activityTitle { return NSLocalizedString(@"Add to Instapaper", NULL); }

- (UIImage *)activityImage
{
    return [self.class instapaperLogoWithHeight:28];
}

+ (UIImage *)instapaperLogoWithHeight:(CGFloat)outputHeight
{
    CGSize outputSize = CGSizeMake(ceilf(0.475f * outputHeight), outputHeight);
    UIGraphicsBeginImageContextWithOptions(outputSize, NO, UIScreen.mainScreen.scale);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGFloat scale = outputHeight / 80.0f;
    CGContextConcatCTM(ctx, CGAffineTransformMakeScale(scale, scale));

    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(28.22, 67.53)];
    [bezierPath addCurveToPoint:CGPointMake(38, 75.17) controlPoint1:CGPointMake(28.22, 73.6) controlPoint2:CGPointMake(29.12, 74.49)];
    [bezierPath addLineToPoint:CGPointMake(38, 80)];
    [bezierPath addLineToPoint:CGPointMake(0, 80)];
    [bezierPath addLineToPoint:CGPointMake(0, 75.17)];
    [bezierPath addCurveToPoint:CGPointMake(9.78, 67.53) controlPoint1:CGPointMake(8.88, 74.49) controlPoint2:CGPointMake(9.78, 73.6)];
    [bezierPath addLineToPoint:CGPointMake(9.78, 12.36)];
    [bezierPath addCurveToPoint:CGPointMake(0, 4.72) controlPoint1:CGPointMake(9.78, 6.4) controlPoint2:CGPointMake(8.88, 5.39)];
    [bezierPath addLineToPoint:CGPointMake(0, 0)];
    [bezierPath addLineToPoint:CGPointMake(38, 0)];
    [bezierPath addLineToPoint:CGPointMake(38, 4.72)];
    [bezierPath addCurveToPoint:CGPointMake(28.22, 12.36) controlPoint1:CGPointMake(29.12, 5.39) controlPoint2:CGPointMake(28.22, 6.4)];
    [bezierPath addLineToPoint:CGPointMake(28.22, 67.53)];
    [bezierPath closePath];
    bezierPath.miterLimit = 4;

    [UIColor.blackColor setFill];
    [bezierPath fill];

    CGContextRestoreGState(ctx);
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return finalImage;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    if (! [UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:@"x-callback-instapaper://"]]) return NO;
    
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

- (void)performActivity
{
    if (! self.URL) {
        [self activityDidFinish:NO];
        return;
    }
    
    NSString *escURL = [self.URL.absoluteString stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    NSString *escCallbackSource = self.xCallbackSource ? [self.xCallbackSource stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet] : @"";
    NSString *escCallbackURL = self.xCallbackSuccessURL ? [self.xCallbackSuccessURL.absoluteString stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet] : @"";

    NSURL *ipURL = [NSURL URLWithString:[NSString stringWithFormat:@"x-callback-instapaper://x-callback-url/add?url=%@&x-success=%@&x-source=%@", escURL, escCallbackURL, escCallbackSource]];
    [self activityDidFinish:[[UIApplication sharedApplication] openURL:ipURL]];
}


@end
