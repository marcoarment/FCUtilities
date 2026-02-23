//
//  UIImage+FCUtilities.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "UIImage+FCUtilities.h"
@import UniformTypeIdentifiers;

@implementation UIImage (FCUtilities)

+ (UIImage * _Nullable)fc_decodedImageFromData:(NSData * _Nonnull)data
{
    return [self fc_decodedImageFromData:data resizedToMaxOutputDimension:0 maxSourceBytes:0 maxSourceDimension:0 onlyIfCommonSourceFormat:NO];
}

+ (UIImage * _Nullable)fc_decodedImageFromData:(NSData * _Nonnull)data resizedToMaxOutputDimension:(int)outputDimension
{
    return [self fc_decodedImageFromData:data resizedToMaxOutputDimension:outputDimension maxSourceBytes:0 maxSourceDimension:0 onlyIfCommonSourceFormat:NO];
}
+ (UIImage * _Nullable)fc_decodedImageFromData:(NSData * _Nonnull)data resizedToMaxOutputDimension:(int)outputDimension maxSourceBytes:(int)maxSourceBytes maxSourceDimension:(int)maxSourceDimension onlyIfCommonSourceFormat:(BOOL)onlyIfCommonSourceFormat
{
    if (! data.length) return nil;
    if (maxSourceBytes > 0 && data.length > maxSourceBytes) return nil;

    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef) data, (__bridge CFDictionaryRef) @{
        ((__bridge NSString *) kCGImageSourceShouldCache) : @NO
    });
    if (! imageSource) return nil;

    if (onlyIfCommonSourceFormat) {
        // JPEG and PNG only to avoid huge CPU/RAM usage when using more-obscure, less-optimized formats like JPEG 2000
        CFStringRef uti = CGImageSourceGetType(imageSource);
        UTType *utt = uti ? [UTType typeWithIdentifier:(__bridge NSString * _Nonnull)(uti)] : nil;
        if (! utt || (
            ! [utt conformsToType:UTTypeJPEG] &&
            ! [utt conformsToType:UTTypePNG] &&
            ! [utt conformsToType:UTTypeGIF]
        )) {
            CFRelease(imageSource);
            return nil;
        }
    }

    CFDictionaryRef dictRef = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    if (! dictRef) {
        CFRelease(imageSource);
        return nil;
    }
    
    NSDictionary *dict = (__bridge NSDictionary *)dictRef;
    int sourceWidth = [dict[(__bridge NSString *) kCGImagePropertyPixelWidth] intValue];
    int sourceHeight = [dict[(__bridge NSString *) kCGImagePropertyPixelHeight] intValue];
    CFRelease(dictRef);

    if (maxSourceDimension > 0 && (
        sourceWidth <= 0 || sourceHeight <= 0 || sourceWidth > maxSourceDimension || sourceHeight > maxSourceDimension
    )) {
        CFRelease(imageSource);
        return nil;
    }
    
    CGImageRef decodedImage;
    UIImage *outputImage = nil;
    if (outputDimension > 0 && MAX(sourceWidth, sourceHeight) > outputDimension) {
        decodedImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef) @{
            ((__bridge NSString *) kCGImageSourceCreateThumbnailFromImageAlways) : @YES,
            ((__bridge NSString *) kCGImageSourceShouldCacheImmediately) : @YES,
            ((__bridge NSString *) kCGImageSourceCreateThumbnailWithTransform) : @YES,
            ((__bridge NSString *) kCGImageSourceThumbnailMaxPixelSize) : @(outputDimension),
        });
    } else {
        decodedImage = CGImageSourceCreateImageAtIndex(imageSource, 0, (__bridge CFDictionaryRef) @{
            ((__bridge NSString *) kCGImageSourceShouldCacheImmediately) : @YES,
        });
    }

    if (decodedImage) {
        outputImage = [UIImage imageWithCGImage:decodedImage];
        CFRelease(decodedImage);
    }

    CFRelease(imageSource);
    return outputImage;
}

+ (UIImage *)fc_stretchableImageWithSolidColor:(UIColor *)solidColor
{
    UIGraphicsBeginImageContext(CGSizeMake(1, 1));
    CGRect drawRect = CGRectMake(0, 0, 1, 1);
    [solidColor set];
    UIRectFill(drawRect);
    UIImage *drawnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [drawnImage stretchableImageWithLeftCapWidth:0 topCapHeight:0];
}

+ (UIImage *)fc_solidColorImageWithSize:(CGSize)size scale:(CGFloat)scale color:(UIColor *)solidColor
{
    UIGraphicsBeginImageContextWithOptions(size, YES, scale);
    CGRect drawRect = CGRectMake(0, 0, size.width, size.height);
    [solidColor set];
    UIRectFill(drawRect);
    UIImage *drawnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return drawnImage;
}

+ (UIImage *)fc_solidColorImageWithSize:(CGSize)size color:(UIColor *)solidColor
{
    UIGraphicsBeginImageContext(size);
    CGRect drawRect = CGRectMake(0, 0, size.width, size.height);
    [solidColor set];
    UIRectFill(drawRect);
    UIImage *drawnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return drawnImage;
}

- (UIImage *)fc_maskedImageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.scale);
    CGContextRef c = UIGraphicsGetCurrentContext();
    [self drawInRect:rect];
    CGContextSetFillColorWithColor(c, [color CGColor]);
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    CGContextFillRect(c, rect);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	return result;
}

+ (UIImage *)fc_maskedImageNamed:(NSString *)name color:(UIColor *)color
{
    UIImage *image = [UIImage imageNamed:name];
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, image.scale);
    CGContextRef c = UIGraphicsGetCurrentContext();
    [image drawInRect:rect];
    CGContextSetFillColorWithColor(c, [color CGColor]);
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    CGContextFillRect(c, rect);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	return result;
}

- (UIImage *)fc_desaturatedImage
{
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.scale);
    CGContextRef c = UIGraphicsGetCurrentContext();
    [self drawInRect:rect];
    CGContextSetFillColorWithColor(c, [UIColor blackColor].CGColor);
    CGContextSetBlendMode(c, kCGBlendModeSaturation);
    CGContextFillRect(c, rect);
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	return result;
}

- (UIImage *)fc_tintedImageUsingColor:(UIColor *)tintColor
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    CGRect drawRect = CGRectMake(0, 0, self.size.width, self.size.height);
    [self drawInRect:drawRect];
    [tintColor set];
    UIRectFillUsingBlendMode(drawRect, kCGBlendModeSourceAtop);
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [UIImage imageWithCGImage:tintedImage.CGImage scale:self.scale orientation:UIImageOrientationUp];
}

+ (UIImage *)fc_imageWithSize:(CGSize)size drawing:(void (^)(void))drawingCommands
{
    if (size.width == 0 || size.height == 0) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    drawingCommands();
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return finalImage;
}

- (UIImage *)fc_imageWithAdditionalDrawing:(void (^)(void))drawingCommands
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    CGRect drawRect = CGRectMake(0, 0, self.size.width, self.size.height);
    CGContextClearRect(UIGraphicsGetCurrentContext(), drawRect);
    [self drawInRect:drawRect];
    drawingCommands();
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return finalImage;
}

- (UIImage *)fc_imageWithRoundedCornerRadius:(CGFloat)cornerRadius
{
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.scale);
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius] addClip];
    [self drawInRect:rect];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	return result;
}

- (UIImage *)fc_imageWithJonyIveRoundedCornerRadius:(CGFloat)cornerRadius
{
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.scale);
    [[UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(cornerRadius, cornerRadius)] addClip];
    [self drawInRect:rect];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	return result;
}

- (UIImage *)fc_imageWithJonyIveRoundedCornerRadius:(CGFloat)borderCornerRadius borderColor:(UIColor *)borderColor borderWidth:(CGFloat)borderWidth
{
    return [self fc_imageWithJonyIveRoundedCornerRadius:borderCornerRadius borderColor:borderColor borderWidth:borderWidth backgroundColor:nil];
}

- (UIImage *)fc_imageWithJonyIveRoundedCornerRadius:(CGFloat)borderCornerRadius borderColor:(UIColor *)borderColor borderWidth:(CGFloat)borderWidth backgroundColor:(UIColor *)backgroundColor
{
    CGFloat halfBorderWidth = borderWidth / 2.0f;
    CGRect outputRect = CGRectMake(0, 0, self.size.width, self.size.height);
    CGRect imageRect = CGRectInset(outputRect, borderWidth, borderWidth);
    CGRect borderRect = CGRectInset(outputRect, halfBorderWidth, halfBorderWidth);
    UIGraphicsBeginImageContextWithOptions(outputRect.size, NO, self.scale);
    CGFloat imageCornerRadius = MAX(0, borderCornerRadius - borderWidth);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    [[UIBezierPath bezierPathWithRoundedRect:imageRect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(imageCornerRadius, imageCornerRadius)] addClip];
    if (backgroundColor) {
        [backgroundColor setFill];
        [[UIBezierPath bezierPathWithRect:outputRect] fill];
    }
    [self drawInRect:imageRect];
    CGContextRestoreGState(ctx);

    UIBezierPath *borderPath = [UIBezierPath bezierPathWithRoundedRect:borderRect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(borderCornerRadius, borderCornerRadius)];
    borderPath.lineWidth = borderWidth;
    [borderColor setStroke];
    [borderPath stroke];

    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

- (UIImage * _Nonnull)fc_imagePaddedWithColor:(UIColor * _Nonnull)color insets:(UIEdgeInsets)insets
{
    // Only ever adds size to the image, doesn't remove it
    insets.top = ABS(insets.top);
    insets.bottom = ABS(insets.bottom);
    insets.left = ABS(insets.left);
    insets.right = ABS(insets.right);
    
    CGSize originalSize = self.size;
    CGSize newSize = CGSizeMake(originalSize.width + (insets.left + insets.right), originalSize.height + (insets.top + insets.bottom));
    return [self.class fc_imageWithSize:newSize drawing:^{
        CGRect entireImageRect = CGRectMake(0, 0, newSize.width, newSize.height);
        [color setFill];
        [[UIBezierPath bezierPathWithRect:entireImageRect] fill];
        [self drawInRect:UIEdgeInsetsInsetRect(entireImageRect, insets)];
    }];
}


@end
