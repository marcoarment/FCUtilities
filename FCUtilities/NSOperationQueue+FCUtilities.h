//
//  NSOperationQueue+FCUtilities.h
//  Overcast
//
//  Created by Marco Arment on 10/6/18.
//  Copyright © 2018 Marco Arment. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FCBlockOperation : NSOperation

+ (instancetype)operationWithBlock:(void (^)(void))block;
@property (nonatomic, readonly) void (^block)(void);

@end


@interface NSOperationQueue (FCUtilities)

- (void)fc_addOperationWithBlock:(void (^)(void))block waitUntilFinished:(BOOL)wait;

@end
