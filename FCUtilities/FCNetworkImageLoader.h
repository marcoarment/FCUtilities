//
//  FCNetworkImageLoader.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface FCNetworkImageLoader : NSObject

// Optional
+ (void)setCellularPolicyHandler:(BOOL (^ _Nullable)(void))returnIsCellularAllowed;

// Optional. Will be called from a background queue, so be careful with UI* calls.
// Use the fc_decodedImageFromData:… methods in UIImage+FCUtilities.h instead of UIImage-based processing or rendering.
+ (void)setFetchedImageDecoder:(UIImage * _Nullable (^ _Nullable)(NSData * _Nonnull imageData))block;

// Optional. Called after each completed request to report its data usage.
+ (void)setDataTransferHandler:(void (^ _Nullable)(int64_t totalBytesTransferred, int64_t cellularBytesTransferred))dataTransferHandler;

+ (void)loadImageAtURL:(NSURL * _Nonnull)url intoImageView:(UIImageView * _Nonnull)imageView placeholderImage:(UIImage * _Nullable)placeholder;
+ (void)loadImageAtURL:(NSURL * _Nonnull)url intoImageView:(UIImageView * _Nonnull)imageView placeholderImage:(UIImage * _Nullable)placeholder cachePolicy:(NSURLRequestCachePolicy)cachePolicy;
+ (void)loadImageAtURL:(NSURL * _Nonnull)url intoImageView:(UIImageView * _Nonnull)imageView placeholderImage:(UIImage * _Nullable)placeholder cachePolicy:(NSURLRequestCachePolicy)cachePolicy imageTransformer:(UIImage * _Nonnull (^ _Nullable)(UIImage * _Nonnull image, CGSize imageViewSize))imageTransformer;

+ (void)cancelLoadForImageView:(UIImageView * _Nonnull)imageView;

@end
