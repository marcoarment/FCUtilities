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


@interface FCNetworkImageLoadOperation : NSOperation <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (nonatomic) BOOL didStart;
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, weak) UIImageView *weakImageView;
@property (nonatomic) NSURLRequestCachePolicy cachePolicy;
@property (nonatomic) NSMutableData *responseData;
@property (nonatomic) NSURLConnection *connection;
@end

@implementation FCNetworkImageLoadOperation

+ (void)delegateThreadMain:(id)ignored
{
    // thanks to AFNetworking for this thread/runloop approach
    @autoreleasepool {
        NSThread.currentThread.name = @"FCNetworkImageLoader";
        NSRunLoop *runLoop = NSRunLoop.currentRunLoop;
        [runLoop addPort:NSMachPort.port forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)delegateThread
{
    static NSThread *thread;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        thread = [[NSThread alloc] initWithTarget:self selector:@selector(delegateThreadMain:) object:nil];
        [thread start];
    });
    return thread;
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    // Force all responses to be cacheable
    return [[NSCachedURLResponse alloc] initWithResponse:cachedResponse.response data:cachedResponse.data userInfo:cachedResponse.userInfo storagePolicy:NSURLCacheStorageAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response { self.responseData = [NSMutableData data]; }
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data { [self.responseData appendData:data]; }
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error { [self cleanup]; }

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (! self.responseData || self.isCancelled) { [self cleanup]; return; }

    __strong UIImageView *imageView = self.weakImageView;
    if (! imageView) { [self cleanup]; return; }

    UIImage *image = [UIImage imageWithData:self.responseData scale:UIScreen.mainScreen.scale];
    if (! image) { [self cleanup]; return; }
    
    [FCNetworkImageLoader.sharedInstance.imageCache setObject:image forKey:self.URL.absoluteString];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (! self.isCancelled) imageView.image = image;
    });

    [self cleanup];
}

- (void)cleanup
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    self.connection = nil;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isConcurrent { return YES; }
- (BOOL)isExecuting  { return _didStart && _connection; }
- (BOOL)isFinished   { return _didStart && ! _connection; }
- (void)cancel       { [self.connection cancel]; [self cleanup]; }

- (void)start
{
    NSThread *delegateThread = self.class.delegateThread;
    if (NSThread.currentThread != delegateThread) {
        [self performSelector:@selector(start) onThread:delegateThread withObject:nil waitUntilDone:NO];
        return;
    }

    if (self.isCancelled) {
        _didStart = YES;
        [self cleanup];
        return;
    }

    __strong UIImageView *imageViewStillExists = self.weakImageView;
    if (! imageViewStillExists || self.isCancelled) return;
    imageViewStillExists = nil;

    NSURLRequest *req = [NSURLRequest requestWithURL:self.URL cachePolicy:_cachePolicy timeoutInterval:30];

    [self willChangeValueForKey:@"isExecuting"];
    self.connection = [NSURLConnection connectionWithRequest:req delegate:self];
    self.didStart = YES;
    [self didChangeValueForKey:@"isExecuting"];

    [self.connection scheduleInRunLoop:NSRunLoop.currentRunLoop forMode:NSDefaultRunLoopMode];
    [self.connection start];
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

    FCNetworkImageLoadOperation *existingOperation = [FCNetworkImageLoader.sharedInstance.imageToOperationMapTable objectForKey:imageView];
    if (existingOperation) {
        if ([existingOperation.URL.absoluteString isEqualToString:url.absoluteString]) return;
        else [existingOperation cancel];
    }
    
    FCNetworkImageLoadOperation *operation = [[FCNetworkImageLoadOperation alloc] init];
    operation.URL = url;
    operation.cachePolicy = cachePolicy;
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
