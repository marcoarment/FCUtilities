//
//  FCAddToInstapaperActivity.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <UIKit/UIKit.h>

extern NSString *const FCActivityTypeAddToInstapaper;

@interface FCAddToInstapaperActivity : UIActivity

- (instancetype)initWithSourceName:(NSString *)xCallbackSource successCallbackURL:(NSURL *)xCallbackURL;

@end
