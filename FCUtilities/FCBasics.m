//
//  FCBasics.m
//  Overcast
//
//  Created by Marco Arment on 6/10/16.
//  Copyright © 2016 Marco Arment. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCBasics.h"

static dispatch_once_t fc_mainThreadOnceToken;
void fc_executeOnMainThread(void (^block)(void))
{
    dispatch_once(&fc_mainThreadOnceToken, ^{
        dispatch_queue_set_specific(dispatch_get_main_queue(), &fc_mainThreadOnceToken, &fc_mainThreadOnceToken, NULL);
    });

    if (dispatch_get_specific(&fc_mainThreadOnceToken) == &fc_mainThreadOnceToken) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

void fc_executeOnMainThreadSync(void (^block)(void))
{
    dispatch_once(&fc_mainThreadOnceToken, ^{
        dispatch_queue_set_specific(dispatch_get_main_queue(), &fc_mainThreadOnceToken, &fc_mainThreadOnceToken, NULL);
    });

    if (dispatch_get_specific(&fc_mainThreadOnceToken) == &fc_mainThreadOnceToken) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

