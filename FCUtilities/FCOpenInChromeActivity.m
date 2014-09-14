//
//  FCOpenInChromeActivity.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCOpenInChromeActivity.h"

NSString *const FCActivityTypeOpenInChrome = @"FCActivityTypeOpenInChrome";

@interface FCOpenInChromeActivity ()
@property (nonatomic, copy) NSString *callbackSource;
@property (nonatomic) NSURL *URL;
@property (nonatomic) NSURL *successCallbackURL;
@end

@implementation FCOpenInChromeActivity

+ (NSString *)conservativelyPercentEscapeString:(NSString *)str
{
    static NSMutableCharacterSet *allowedCharacters = nil;
    if (! allowedCharacters) {
        allowedCharacters = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
        [allowedCharacters removeCharactersInString:@"?=&+:;@/$!'()\",*"];
    }
    return [str stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
}

- (instancetype)initWithSourceName:(NSString *)xCallbackSource successCallbackURL:(NSURL *)xCallbackURL
{
    if ( (self = [super init]) ) {
        self.callbackSource = xCallbackSource;
        self.successCallbackURL = xCallbackURL;
    }
    return self;
}

- (NSString *)activityType  { return FCActivityTypeOpenInChrome; }
- (NSString *)activityTitle { return NSLocalizedString(@"Open in Chrome", NULL); }

- (UIImage *)activityImage
{
    return [self.class chromeLogoWithHeight:33];
}

+ (UIImage *)chromeLogoWithHeight:(CGFloat)outputHeight
{
    CGSize outputSize = CGSizeMake(outputHeight, outputHeight);
    UIGraphicsBeginImageContextWithOptions(outputSize, NO, UIScreen.mainScreen.scale);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGFloat scale = outputHeight / 31.0f;
    CGContextConcatCTM(ctx, CGAffineTransformMakeScale(scale, scale));

    [UIColor.blackColor setStroke];

    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(0.5, 0.5, 30, 30)];
    [ovalPath stroke];

    UIBezierPath* oval2Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(9.5, 9.5, 12, 12)];
    [oval2Path stroke];

    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(16.5, 9.5)];
    [bezierPath addCurveToPoint: CGPointMake(29.5, 9.5) controlPoint1: CGPointMake(28.5, 9.5) controlPoint2: CGPointMake(29.5, 9.5)];
    [bezierPath stroke];

    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(20.5, 18.5)];
    [bezier2Path addLineToPoint: CGPointMake(14.5, 30.5)];
    [bezier2Path stroke];

    UIBezierPath* bezier3Path = [UIBezierPath bezierPath];
    [bezier3Path moveToPoint: CGPointMake(9.5, 17.5)];
    [bezier3Path addLineToPoint: CGPointMake(3.5, 6.5)];
    [bezier3Path stroke];

    CGContextRestoreGState(ctx);
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return finalImage;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
	if (! [UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:@"googlechrome-x-callback://"]]) return NO;

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
    [self activityDidFinish:[UIApplication.sharedApplication openURL:[NSURL URLWithString:[NSString stringWithFormat:
        @"googlechrome-x-callback://x-callback-url/open/?url=%@&x-success=%@&x-source=%@",
        [self.class conservativelyPercentEscapeString:self.URL.absoluteString],
        [self.class conservativelyPercentEscapeString:(self.successCallbackURL ? self.successCallbackURL.absoluteString : @"")],
        [self.class conservativelyPercentEscapeString:(self.callbackSource ?: @"")]
    ]]]];
}

@end
