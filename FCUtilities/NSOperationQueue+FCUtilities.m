//
//  NSOperationQueue+FCUtilities.m
//  Overcast
//
//  Created by Marco Arment on 10/6/18.
//  Copyright © 2018 Marco Arment. All rights reserved.
//

#import "NSOperationQueue+FCUtilities.h"

@interface FCBlockOperation ()
@property (nonatomic, copy) void (^block)(void);
@end

@implementation FCBlockOperation
+ (instancetype)operationWithBlock:(void (^)(void))block
{
    FCBlockOperation *op = [self new];
    op.block = block;
    return op;
}

- (void)main { if (self.block && ! self.isCancelled) self.block(); }
@end


@implementation NSOperationQueue (FCUtilities)

- (void)fc_addOperationWithBlock:(void (^)(void))block waitUntilFinished:(BOOL)wait
{
    [self addOperations:@[ [FCBlockOperation operationWithBlock:block] ] waitUntilFinished:wait];
}

@end
