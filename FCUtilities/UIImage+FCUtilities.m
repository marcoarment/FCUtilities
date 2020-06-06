//
//  UIImage+FCUtilities.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "UIImage+FCUtilities.h"
@import CoreServices;

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
        if (! uti || (
            ! UTTypeConformsTo(uti, kUTTypeJPEG) &&
            ! UTTypeConformsTo(uti, kUTTypePNG) &&
            ! UTTypeConformsTo(uti, kUTTypeGIF)
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
    CGFloat halfBorderWidth = borderWidth / 2.0f;
    CGRect outputRect = CGRectMake(0, 0, self.size.width, self.size.height);
    CGRect imageRect = CGRectInset(outputRect, borderWidth, borderWidth);
    CGRect borderRect = CGRectInset(outputRect, halfBorderWidth, halfBorderWidth);
    UIGraphicsBeginImageContextWithOptions(outputRect.size, NO, self.scale);
    CGFloat imageCornerRadius = MAX(0, borderCornerRadius - borderWidth);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    [[UIBezierPath bezierPathWithRoundedRect:imageRect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(imageCornerRadius, imageCornerRadius)] addClip];
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

- (void)fc_enumeratePixelsUsingBlock:(void (^ _Nonnull)(NSUInteger x, NSUInteger y, UInt8 r, UInt8 g, UInt8 b, UInt8 a))callback
{
    // Adapted from
    // http://stackoverflow.com/questions/448125/how-to-get-pixel-data-from-a-uiimage-cocoa-touch-or-cgimage-core-graphics
    
    CGImageRef imageRef = self.CGImage;
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char *) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);

    for (NSUInteger x = 0; x < width; x++) {
        for (NSUInteger y = 0; y < width; y++) {
            NSUInteger byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
            UInt8 red   = rawData[byteIndex];
            UInt8 green = rawData[byteIndex + 1];
            UInt8 blue  = rawData[byteIndex + 2];
            UInt8 alpha = rawData[byteIndex + 3];
            callback(x, y, red, green, blue, alpha);
        }
    }

    free(rawData);
}

- (float)fc_similarityToImageOfSameSize:(UIImage * _Nonnull)otherImage
{
    CGImageRef imageRef1 = self.CGImage, imageRef2 = otherImage.CGImage;
    NSUInteger width = CGImageGetWidth(imageRef1);
    NSUInteger height = CGImageGetHeight(imageRef1);
    
    if (CGImageGetWidth(imageRef2) != width || CGImageGetHeight(imageRef2) != height) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Images must be the same size" userInfo:nil] raise]; return 0;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData1 = (unsigned char *) calloc(height * width * 4, sizeof(unsigned char));
    unsigned char *rawData2 = (unsigned char *) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context1 = CGBitmapContextCreate(rawData1, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextRef context2 = CGBitmapContextCreate(rawData2, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context1, CGRectMake(0, 0, width, height), imageRef1);
    CGContextDrawImage(context2, CGRectMake(0, 0, width, height), imageRef2);
    CGContextRelease(context1);
    CGContextRelease(context2);

    NSUInteger totalDifferentPixels = 0;
    float totalDifference = 0.0f;
    for (NSUInteger x = 0; x < width; x++) {
        for (NSUInteger y = 0; y < width; y++) {
            NSUInteger byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
            NSUInteger differenceSquare =
                MAX(
                    ABS(rawData1[byteIndex] - rawData2[byteIndex]),
                    MAX(
                        ABS(rawData1[byteIndex + 1] - rawData2[byteIndex + 1]),
                        ABS(rawData1[byteIndex + 2] - rawData2[byteIndex + 2])
                    )
                )
            ;
            
            differenceSquare *= differenceSquare;
            totalDifference += MIN(1.0f, (float) differenceSquare / 256.0f);
            if (differenceSquare) totalDifferentPixels++;
        }
    }

    free(rawData1);
    free(rawData2);
    
    return totalDifferentPixels ? 1.0f - (totalDifference / (float) totalDifferentPixels) : 1.0f;
}


@end
