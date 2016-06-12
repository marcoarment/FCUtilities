//
//  FCBasics.m
//  Overcast
//
//  Created by Marco Arment on 6/10/16.
//  Copyright © 2016 Marco Arment. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCBasics.h"

void fc_executeOnMainThread(void (^block)())
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_set_specific(dispatch_get_main_queue(), &onceToken, &onceToken, NULL);
    });

    if (dispatch_get_specific(&onceToken) == &onceToken) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

