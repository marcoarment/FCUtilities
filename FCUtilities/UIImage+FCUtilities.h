//
//  UIImage+FCUtilities.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface UIImage (FCUtilities)


// Masked images are resource images that you provide in black (or any color) on a transparent background.
// Only their transparency values are used -- they're effectively just masks.
//
// On load, you can make the opaque portions of the source image any color you want.
// Useful when declaring your interface colors programatically or supporting multiple color schemes.

+ (UIImage *)fc_maskedImageNamed:(NSString *)name color:(UIColor *)color;


// Convenience methods for using solid colors where UIKit wants images

+ (UIImage *)fc_stretchableImageWithSolidColor:(UIColor *)solidColor;
+ (UIImage *)fc_solidColorImageWithSize:(CGSize)size color:(UIColor *)solidColor;


// Basic effects

- (UIImage *)fc_desaturatedImage;
- (UIImage *)fc_tintedImageUsingColor:(UIColor *)tintColor;


// Creation of new images (or annotation of existing ones) by using Quartz drawing commands:

+ (UIImage *)fc_imageWithSize:(CGSize)size drawing:(void (^)())drawingCommands;
- (UIImage *)fc_imageWithAdditionalDrawing:(void (^)())drawingCommands;

@end
