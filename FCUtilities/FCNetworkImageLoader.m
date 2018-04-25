//
//  FCNetworkImageLoader.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCNetworkImageLoader.h"
#import "FCCache.h"

// If we're currently on the main thread, run block() sync, otherwise dispatch block() sync to main thread.
static inline __attribute__((always_inline)) void FCNetworkImageLoader_executeOnMainThread(void (^block)(void))
{
    if (block) {
        if ([NSThread isMainThread]) block(); else dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@interface FCNetworkImageLoader () <NSURLSessionDataDelegate>
@property (nonatomic) FCCache *imageCache;
@property (nonatomic) NSMapTable *imageToSessionTaskMapTable;
@property (nonatomic) NSURLSession *session;
@property (nonatomic, copy) BOOL (^cellularPolicyHandler)(void);
@property (nonatomic, copy) NSData *(^fetchedImageDataHandler)(NSData *imageData);
+ (instancetype)sharedInstance;
@end

@implementation FCNetworkImageLoader

+ (instancetype)sharedInstance
{
    static FCNetworkImageLoader *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

+ (void)setCellularPolicyHandler:(BOOL (^)(void))returnIsCellularAllowed
{
    FCNetworkImageLoader.sharedInstance.cellularPolicyHandler = returnIsCellularAllowed;
}

+ (void)setFetchedImageDataHandler:(NSData * (^)(NSData *imageData))block
{
    FCNetworkImageLoader.sharedInstance.fetchedImageDataHandler = block;
}

- (instancetype)init
{
    if ( (self = [super init]) ) {
        self.name = @"FCNetworkImageLoader";
        self.maxConcurrentOperationCount = 5;
        self.imageCache = [[FCCache alloc] init];
        self.imageToSessionTaskMapTable = [NSMapTable weakToWeakObjectsMapTable];
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self];
    }
    return self;
}

- (void)URLSession:(NSURLSession * _Nonnull)session dataTask:(NSURLSessionDataTask * _Nonnull)dataTask willCacheResponse:(NSCachedURLResponse * _Nonnull)proposedResponse completionHandler:(void (^ _Nonnull)(NSCachedURLResponse * _Nullable cachedResponse))completionHandler
{
    // Force all valid responses to be cacheable
    NSInteger httpStatus = ((NSHTTPURLResponse *)proposedResponse.response).statusCode;
    if (httpStatus >= 200 && httpStatus < 300) {
        proposedResponse = [[NSCachedURLResponse alloc] initWithResponse:proposedResponse.response data:proposedResponse.data userInfo:proposedResponse.userInfo storagePolicy:NSURLCacheStorageAllowed];
    }
    completionHandler(proposedResponse);
}

+ (void)setCachedImageLimit:(NSUInteger)imageCount
{
    ((FCNetworkImageLoader *) [self sharedInstance]).imageCache.itemLimit = imageCount;
}

+ (void)loadImageAtURL:(NSURL *)url intoImageView:(UIImageView *)imageView placeholderImage:(UIImage *)placeholder
{
    [self loadImageAtURL:url intoImageView:imageView placeholderImage:placeholder cachePolicy:NSURLRequestUseProtocolCachePolicy];
}

+ (void)loadImageAtURL:(NSURL *)url intoImageView:(UIImageView *)imageView placeholderImage:(UIImage *)placeholder cachePolicy:(NSURLRequestCachePolicy)cachePolicy
{
    UIImage *cachedImage = [FCNetworkImageLoader.sharedInstance.imageCache objectForKey:url.absoluteString];
    if (cachedImage) {
        FCNetworkImageLoader_executeOnMainThread(^{ imageView.image = cachedImage; });
        return;
    }

    if (placeholder) FCNetworkImageLoader_executeOnMainThread(^{ imageView.image = placeholder; });

    NSURLSessionTask *existingTask = [FCNetworkImageLoader.sharedInstance.imageToSessionTaskMapTable objectForKey:imageView];
    if (existingTask) {
        if ([existingTask.originalRequest.URL.absoluteString isEqualToString:url.absoluteString]) return;
        else [existingTask cancel];
    }

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:cachePolicy timeoutInterval:30];
    BOOL (^cellularHandler)(void) = FCNetworkImageLoader.sharedInstance.cellularPolicyHandler;
    if (cellularHandler) req.allowsCellularAccess = cellularHandler();

    __weak UIImageView *weakImageView = imageView;
    NSURLSessionDataTask *task = [FCNetworkImageLoader.sharedInstance.session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong UIImageView *strongImageView = weakImageView;

        NSData *(^imageDataHandler)(NSData *image) = FCNetworkImageLoader.sharedInstance.fetchedImageDataHandler;
        if (imageDataHandler) data = imageDataHandler(data);

        UIImage *image = nil;
        if (! strongImageView || ! data || ! response || error || ! (image = [UIImage imageWithData:data scale:UIScreen.mainScreen.scale]) ) return;

        [FCNetworkImageLoader.sharedInstance.imageCache setObject:image forKey:url.absoluteString];

        FCNetworkImageLoader_executeOnMainThread(^{
            __strong UIImageView *strongInnerImageView = weakImageView;
            if (strongInnerImageView) strongInnerImageView.image = image;
        });
    }];
    [FCNetworkImageLoader.sharedInstance.imageToSessionTaskMapTable setObject:task forKey:imageView];
    [task resume];
}

+ (void)cancelLoadForImageView:(UIImageView *)imageView
{
    NSURLSessionTask *existingTask = [FCNetworkImageLoader.sharedInstance.imageToSessionTaskMapTable objectForKey:imageView];
    if (existingTask) [existingTask cancel];
}

@end
