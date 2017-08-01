//
//  UIImage+FCUtilities.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface UIImage (FCUtilities)

- (void)fc_enumeratePixelsUsingBlock:(void (^ _Nonnull)(NSUInteger x, NSUInteger y, UInt8 r, UInt8 g, UInt8 b, UInt8 a))callback;
- (float)fc_similarityToImageOfSameSize:(UIImage * _Nonnull)otherImage;

// Masked images are resource images that you provide in black (or any color) on a transparent background.
// Only their transparency values are used -- they're effectively just masks.
//
// On load, you can make the opaque portions of the source image any color you want.
// Useful when declaring your interface colors programatically or supporting multiple color schemes.

+ (UIImage * _Nullable)fc_maskedImageNamed:(NSString * _Nonnull)name color:(UIColor * _Nonnull)color;
- (UIImage * _Nullable)fc_maskedImageWithColor:(UIColor * _Nonnull)color;


// Convenience methods for using solid colors where UIKit wants images

#if ! TARGET_OS_TV
+ (UIImage * _Nonnull)fc_stretchableImageWithSolidColor:(UIColor * _Nonnull)solidColor;
#endif
+ (UIImage * _Nonnull)fc_solidColorImageWithSize:(CGSize)size color:(UIColor * _Nonnull)solidColor;
+ (UIImage * _Nonnull)fc_solidColorImageWithSize:(CGSize)size scale:(CGFloat)scale color:(UIColor * _Nonnull)solidColor;

// Basic effects

- (UIImage * _Nonnull)fc_desaturatedImage;
- (UIImage * _Nonnull)fc_tintedImageUsingColor:(UIColor * _Nonnull)tintColor;
- (UIImage * _Nonnull)fc_imageWithRoundedCornerRadius:(CGFloat)cornerRadius;
- (UIImage * _Nonnull)fc_imageWithJonyIveRoundedCornerRadius:(CGFloat)cornerRadius;
- (UIImage * _Nonnull)fc_imagePaddedWithColor:(UIColor * _Nonnull)color insets:(UIEdgeInsets)insets;


// Creation of new images (or annotation of existing ones) by using Quartz drawing commands:

+ (UIImage * _Nonnull)fc_imageWithSize:(CGSize)size drawing:(void (^ _Nonnull)(void))drawingCommands;
- (UIImage * _Nonnull)fc_imageWithAdditionalDrawing:(void (^ _Nonnull)(void))drawingCommands;

@end
