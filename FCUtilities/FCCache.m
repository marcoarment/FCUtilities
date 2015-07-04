//
//  FCCache.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCCache.h"
#ifdef TARGET_OS_IPHONE
@import UIKit;
#endif

@interface FCCache () {
    NSUInteger limit;
}
@property (nonatomic) NSMutableDictionary *backingStore;
@property (nonatomic) dispatch_queue_t queue;
@end

@implementation FCCache

- (instancetype)init
{
    if ( (self = [super init]) ) {
        self.backingStore = [NSMutableDictionary dictionary];
#ifdef TARGET_OS_IPHONE
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
        self.queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }

- (NSUInteger)itemLimit { return limit; }

- (void)setItemLimit:(NSUInteger)itemLimit
{
    limit = itemLimit;
    dispatch_barrier_async(_queue, ^{
        if (limit && _backingStore.count >= limit) [_backingStore removeAllObjects];
    });
}

- (id)objectForKey:(id)key
{
    if (! key) return nil;
    __block id value;
    dispatch_sync(_queue, ^{ value = [_backingStore objectForKey:key]; });
    return value;
}

- (void)setObject:(id)obj forKey:(id)key
{
    if (! obj || ! key) return;
    dispatch_barrier_async(_queue, ^{
        if (limit && _backingStore.count >= limit) [_backingStore removeAllObjects];
        [_backingStore setObject:obj forKey:key];
    });
}

- (void)removeObjectForKey:(id)key
{
    if (! key) return;
    dispatch_barrier_async(_queue, ^{ [_backingStore removeObjectForKey:key]; });
}

- (void)removeAllObjects
{
    dispatch_barrier_async(_queue, ^{ [_backingStore removeAllObjects]; });
}

@end
