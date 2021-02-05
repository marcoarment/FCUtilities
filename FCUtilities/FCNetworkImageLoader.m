//
//  FCNetworkImageLoader.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCNetworkImageLoader.h"
#import "UIImage+FCUtilities.h"
#import "FCCache.h"
#import <os/lock.h>

@interface UIImageView (FCNetworkImageLoader)
@property (nonatomic, strong) NSURLSessionTask *fcNetworkImageLoader_downloadTask;
@end

#import <objc/runtime.h>
@implementation UIImageView (FCNetworkImageLoader)
@dynamic fcNetworkImageLoader_downloadTask;
- (NSURLSessionTask *)fcNetworkImageLoader_downloadTask { return objc_getAssociatedObject(self, @selector(fcNetworkImageLoader_downloadTask)); }
- (void)setFcNetworkImageLoader_downloadTask:(NSURLSessionTask *)downloadTask
{
    objc_setAssociatedObject(self, @selector(fcNetworkImageLoader_downloadTask), downloadTask, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

@interface FCNetworkImageLoader () <NSURLSessionDataDelegate> {
@public
    os_unfair_lock writeLock;
}
@property (nonatomic) FCCache *imageCache;
@property (nonatomic) NSURLSession *session;
@property (nonatomic) dispatch_queue_t decodeQueue;
@property (nonatomic, copy) BOOL (^cellularPolicyHandler)(void);
@property (nonatomic, copy) UIImage *(^fetchedImageDecoder)(NSData *imageData);
@property (nonatomic, copy) void (^dataTransferHandler)(int64_t totalBytesTransferred, int64_t cellularBytesTransferred);
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

+ (void)setFetchedImageDecoder:(UIImage * (^)(NSData *imageData))block
{
    FCNetworkImageLoader.sharedInstance.fetchedImageDecoder = block;
}

+ (void)setDataTransferHandler:(void (^)(int64_t totalBytesTransferred, int64_t cellularBytesTransferred))dataTransferHandler
{
    FCNetworkImageLoader.sharedInstance.dataTransferHandler = dataTransferHandler;
}

- (instancetype)init
{
    if ( (self = [super init]) ) {
        self.imageCache = [[FCCache alloc] init];
        writeLock = OS_UNFAIR_LOCK_INIT;
        self.decodeQueue = dispatch_queue_create("FCNetworkImageLoader-decode", DISPATCH_QUEUE_CONCURRENT);
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
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

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics
{
    int64_t bytesTransferred = 0;
    int64_t cellularBytesTransferred = 0;
    for (NSURLSessionTaskTransactionMetrics *tm in metrics.transactionMetrics) {
        int64_t total = tm.countOfRequestHeaderBytesSent + tm.countOfRequestBodyBytesSent + tm.countOfResponseHeaderBytesReceived + tm.countOfResponseBodyBytesReceived;
        bytesTransferred += total;
        if (tm.isCellular) cellularBytesTransferred += total;
    }

    if (self.dataTransferHandler) self.dataTransferHandler(bytesTransferred, cellularBytesTransferred);
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

    [FCNetworkImageLoader.sharedInstance _loadImageAtURL:url intoImageView:imageView placeholderImage:placeholder cachePolicy:cachePolicy];
}

- (void)_loadImageAtURL:(NSURL *)url intoImageView:(UIImageView *)imageView placeholderImage:(UIImage *)placeholder cachePolicy:(NSURLRequestCachePolicy)cachePolicy
{
    os_unfair_lock_lock((os_unfair_lock * _Nonnull) &(writeLock));
    
    UIImage *cachedImage = [self.imageCache objectForKey:url.absoluteString];
    NSURLSessionTask *alreadyDownloadingTask = imageView.fcNetworkImageLoader_downloadTask;
    BOOL alreadyDownloadingThisURL = alreadyDownloadingTask && [alreadyDownloadingTask.originalRequest.URL isEqual:url];
    
    if (alreadyDownloadingTask && ! alreadyDownloadingThisURL) {
        [alreadyDownloadingTask cancel];
        imageView.fcNetworkImageLoader_downloadTask = nil;
    }
    
    if (cachedImage) {
        dispatch_async(dispatch_get_main_queue(), ^{ imageView.image = cachedImage; });
        os_unfair_lock_unlock((os_unfair_lock * _Nonnull) &writeLock);
        return;
    }

    if (placeholder && ! alreadyDownloadingThisURL) dispatch_async(dispatch_get_main_queue(), ^{ imageView.image = placeholder; });

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:cachePolicy timeoutInterval:30];
    BOOL (^cellularHandler)(void) = FCNetworkImageLoader.sharedInstance.cellularPolicyHandler;
    if (cellularHandler) req.allowsCellularAccess = cellularHandler();

    __weak typeof(self) weakSelf = self;
    __weak UIImageView *weakImageView = imageView;
    NSURLSessionDataTask *task = [FCNetworkImageLoader.sharedInstance.session dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(self) strongSelf = weakSelf;
        __strong UIImageView *strongImageView = weakImageView;
        if (! strongSelf || ! strongImageView || ! data || ! response || error || ! [strongImageView.fcNetworkImageLoader_downloadTask.originalRequest.URL isEqual:url]) return;

        dispatch_async(strongSelf.decodeQueue, ^{
            UIImage *(^imageDecoder)(NSData *image) = FCNetworkImageLoader.sharedInstance.fetchedImageDecoder;
            UIImage *image = imageDecoder ? imageDecoder(data) : [UIImage fc_decodedImageFromData:data];
            if (! image) return;

            os_unfair_lock_lock((os_unfair_lock * _Nonnull) &writeLock);
            [FCNetworkImageLoader.sharedInstance.imageCache setObject:image forKey:url.absoluteString];
            BOOL current = [strongImageView.fcNetworkImageLoader_downloadTask.originalRequest.URL isEqual:url];
            os_unfair_lock_unlock((os_unfair_lock * _Nonnull) &writeLock);
            if (current) dispatch_async(dispatch_get_main_queue(), ^{ strongImageView.image = image; });
        });
    }];
    imageView.fcNetworkImageLoader_downloadTask = task;
    [task resume];
    os_unfair_lock_unlock((os_unfair_lock * _Nonnull) &writeLock);
}

+ (void)cancelLoadForImageView:(UIImageView *)imageView
{
    os_unfair_lock_lock((os_unfair_lock * _Nonnull) &(FCNetworkImageLoader.sharedInstance->writeLock));
    NSURLSessionTask *existingTask = imageView.fcNetworkImageLoader_downloadTask;
    if (existingTask) { [existingTask cancel]; imageView.fcNetworkImageLoader_downloadTask = nil; }
    os_unfair_lock_unlock((os_unfair_lock * _Nonnull) &(FCNetworkImageLoader.sharedInstance->writeLock));
}

@end
