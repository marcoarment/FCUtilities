//
//  FCCache.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCCache.h"

@interface FCCache () {
    NSUInteger limit;
}
@property (nonatomic) NSMutableDictionary *backingStore;
@end

@implementation FCCache

- (instancetype)init
{
    if ( (self = [super init]) ) {
        self.backingStore = [NSMutableDictionary dictionary];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }

- (NSUInteger)itemLimit { return limit; }

- (void)setItemLimit:(NSUInteger)itemLimit { limit = itemLimit; [self enforceLimit]; }

- (void)enforceLimit { if (self.backingStore.count > limit) [self.backingStore removeAllObjects]; }

- (id)objectForKey:(id)key { return key ? self.backingStore[key] : nil; }

- (void)setObject:(id)obj forKey:(id)key
{
    if (! obj || ! key) return;
    self.backingStore[obj] = key;
    [self enforceLimit];
}

- (void)removeObjectForKey:(id)key { if (key) [self.backingStore removeObjectForKey:key]; }

- (void)removeAllObjects { [self.backingStore removeAllObjects]; }


@end
