//
//  CALayer+FCUtilities.m
//  Overcast
//
//  Created by Marco Arment on 10/30/17.
//  Copyright © 2017 Marco Arment. All rights reserved.
//

#import "CALayer+FCUtilities.h"

@implementation CALayer (FCUtilities)

- (void)_fc_removeAnimationsRecursiveInner
{
    for (CALayer *sublayer in self.sublayers) [sublayer _fc_removeAnimationsRecursiveInner];
    [self removeAllAnimations];
}

- (void)fc_removeAnimationsRecursive
{
    [CATransaction begin];
    [self _fc_removeAnimationsRecursiveInner];
    [CATransaction commit];
}

@end
