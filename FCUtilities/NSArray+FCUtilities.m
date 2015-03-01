//
//  NSArray+FCUtilities.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "NSArray+FCUtilities.h"

@implementation NSArray (FCUtilities)

- (NSArray *)fc_filteredArrayUsingBlock:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))keepBlock
{
    return [self objectsAtIndexes:[self indexesOfObjectsPassingTest:keepBlock]];
}

- (NSArray *)fc_arrayWithCorrespondingObjectsFromBlock:(id (^)(id obj))newObjectFromObjectBlock
{
    NSMutableArray *outArray = [NSMutableArray arrayWithCapacity:self.count];
    for (id obj in self) [outArray addObject:newObjectFromObjectBlock(obj)];
    return outArray;
}

@end


@implementation NSMutableArray (FCUtilities)

- (void)fc_moveObjectAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    id object = [self objectAtIndex:fromIndex];
    [self removeObjectAtIndex:fromIndex];
    [self insertObject:object atIndex:toIndex];
}

@end

