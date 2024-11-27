//
//  CALayer+FCUtilities.h
//  Overcast
//
//  Created by Marco Arment on 10/30/17.
//  Copyright © 2017 Marco Arment. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>


@interface CALayer (FCUtilities)

- (void)fc_removeAnimationsRecursive;

@end
