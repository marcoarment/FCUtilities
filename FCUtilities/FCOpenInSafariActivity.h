//
//  FCOpenInSafariActivity.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <UIKit/UIKit.h>

extern NSString *const FCActivityTypeOpenInSafari;

@interface FCOpenInSafariActivity : UIActivity

+ (UIImage *)alphaSafariIconWithWidth:(CGFloat)width scale:(CGFloat)scale;

@end
