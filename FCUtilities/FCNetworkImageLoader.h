//
//  FCNetworkImageLoader.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface FCNetworkImageLoader : NSObject

// Optional
+ (void)setCellularPolicyHandler:(BOOL (^)(void))returnIsCellularAllowed;

// Optional. Will be called from a background queue, so be careful with UI* calls.
// Use the fc_decodedImageFromData:… methods in UIImage+FCUtilities.h instead of UIImage-based processing or rendering.
+ (void)setFetchedImageDecoder:(UIImage * (^)(NSData *imageData))block;

+ (void)loadImageAtURL:(NSURL *)url intoImageView:(UIImageView *)imageView placeholderImage:(UIImage *)placeholder;
+ (void)loadImageAtURL:(NSURL *)url intoImageView:(UIImageView *)imageView placeholderImage:(UIImage *)placeholder cachePolicy:(NSURLRequestCachePolicy)cachePolicy;

+ (void)cancelLoadForImageView:(UIImageView *)imageView;
+ (void)setCachedImageLimit:(NSUInteger)imageCount;

@end
