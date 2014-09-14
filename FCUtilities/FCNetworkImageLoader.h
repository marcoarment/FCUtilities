//
//  FCNetworkImageLoader.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <Foundation/Foundation.h>

@interface FCNetworkImageLoader : NSOperationQueue

+ (void)loadImageAtURL:(NSURL *)url intoImageView:(UIImageView *)imageView placeholderImage:(UIImage *)placeholder;

+ (void)cancelLoadForImageView:(UIImageView *)imageView;

@end
