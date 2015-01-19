//
//  FCCache.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <Foundation/Foundation.h>

@interface FCCache : NSObject

- (id)objectForKey:(id)key;
- (void)setObject:(id)obj forKey:(id)key;
- (void)removeObjectForKey:(id)key;
- (void)removeAllObjects;

@property (nonatomic) NSUInteger itemLimit;

@end
