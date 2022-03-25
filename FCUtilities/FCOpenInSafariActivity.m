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
- (UIImage *)activityImage  { return [UIImage systemImageNamed:@"safari" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:23.0f]]; }

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

- (void)performActivity
{
    [UIApplication.sharedApplication openURL:self.URL options:@{} completionHandler:^(BOOL success) {
        [self activityDidFinish:success];
    }];
}

@end
