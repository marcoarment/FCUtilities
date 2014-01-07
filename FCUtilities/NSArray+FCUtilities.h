//
//  NSArray+FCUtilities.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <Foundation/Foundation.h>

@interface NSArray (FCUtilities)

- (NSArray *)fc_filteredArrayUsingBlock:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))keepBlock;

@end


@interface NSMutableArray (FCUtilities)

- (void)fc_moveObjectAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end
