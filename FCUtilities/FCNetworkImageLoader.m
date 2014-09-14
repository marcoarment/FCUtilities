//
//  FCNetworkImageLoader.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCNetworkImageLoader.h"

// If we're currently on the main thread, run block() sync, otherwise dispatch block() sync to main thread.
static inline __attribute__((always_inline)) void FCNetworkImageLoader_executeOnMainThread(void (^block)())
{
    if (block) {
        if ([NSThread isMainThread]) block(); else dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@interface FCNetworkImageLoader ()
@property (nonatomic) NSCache *imageCache;
@property (nonatomic) NSMapTable *imageToOperationMapTable;
+ (instancetype)sharedInstance;
@end


@interface FCNetworkImageLoadOperation : NSOperation
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, weak) UIImageView *weakImageView;
@end

@implementation FCNetworkImageLoadOperation
- (void)main
{
    __strong UIImageView *imageViewStillExists = self.weakImageView;
    if (! imageViewStillExists || self.isCancelled) return;
    imageViewStillExists = nil;

    NSData *imageData = [NSData dataWithContentsOfURL:self.URL];
    if (! imageData || self.isCancelled) return;

    __strong UIImageView *imageView = self.weakImageView;
    if (! imageView) return;

    UIImage *image = [UIImage imageWithData:imageData scale:UIScreen.mainScreen.scale];
    if (! image) return;
    
    [FCNetworkImageLoader.sharedInstance.imageCache setObject:image forKey:self.URL.absoluteString];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (! self.isCancelled) imageView.image = image;
    });
}
@end


@implementation FCNetworkImageLoader

+ (instancetype)sharedInstance
{
    static FCNetworkImageLoader *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (instancetype)init
{
    if ( (self = [super init]) ) {
        self.name = @"FCNetworkImageLoader";
        self.maxConcurrentOperationCount = 3;
        self.imageCache = [[NSCache alloc] init];
        self.imageToOperationMapTable = [NSMapTable weakToWeakObjectsMapTable];
    }
    return self;
}

+ (void)loadImageAtURL:(NSURL *)url intoImageView:(UIImageView *)imageView placeholderImage:(UIImage *)placeholder
{
    UIImage *cachedImage = [FCNetworkImageLoader.sharedInstance.imageCache objectForKey:url.absoluteString];
    if (cachedImage) {
        FCNetworkImageLoader_executeOnMainThread(^{ imageView.image = cachedImage; });
        return;
    }

    if (placeholder) FCNetworkImageLoader_executeOnMainThread(^{ imageView.image = placeholder; });


    FCNetworkImageLoadOperation *existingOperation = [FCNetworkImageLoader.sharedInstance.imageToOperationMapTable objectForKey:imageView];
    if (existingOperation) {
        if ([existingOperation.URL.absoluteString isEqualToString:url.absoluteString]) return;
        else [existingOperation cancel];
    }
    
    FCNetworkImageLoadOperation *operation = [[FCNetworkImageLoadOperation alloc] init];
    operation.URL = url;
    operation.weakImageView = imageView;
    [self.sharedInstance addOperation:operation];
    [FCNetworkImageLoader.sharedInstance.imageToOperationMapTable setObject:operation forKey:imageView];
}

+ (void)cancelLoadForImageView:(UIImageView *)imageView
{
    FCNetworkImageLoadOperation *loadOperationForImageView = [FCNetworkImageLoader.sharedInstance.imageToOperationMapTable objectForKey:imageView];
    if (loadOperationForImageView) [loadOperationForImageView cancel];
}

@end
