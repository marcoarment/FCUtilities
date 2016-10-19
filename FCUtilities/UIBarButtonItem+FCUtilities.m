//
//  UIBarButtonItem+FCUtilities.m
//  Overcast
//
//  Created by Marco Arment on 10/18/16.
//  Copyright © 2016 Marco Arment. All rights reserved.
//

#import "UIBarButtonItem+FCUtilities.h"

@implementation UIBarButtonItem (FCUtilities)

+ (instancetype)fc_fixedSpaceItemWithWidth:(CGFloat)width
{
    UIBarButtonItem *item = [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:NULL];
    item.width = width;
    return item;
}

@end
