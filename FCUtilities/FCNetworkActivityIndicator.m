//
//  FCNetworkActivityIndicator.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCNetworkActivityIndicator.h"

#if TARGET_OS_TV

@implementation FCNetworkActivityIndicator
+ (void)incrementActivityCount { }
+ (void)decrementActivityCount { }
@end

#else

static int activityCount = 0;

@implementation FCNetworkActivityIndicator

+ (void)incrementActivityCount
{
    dispatch_async(dispatch_get_main_queue(), ^{
        activityCount++;
        [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:YES];
    });
}

+ (void)decrementActivityCount
{
    dispatch_async(dispatch_get_main_queue(), ^{
        activityCount--;
        if (activityCount < 0) activityCount = 0;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIApplication.sharedApplication setNetworkActivityIndicatorVisible:(activityCount > 0)];
        });
    });
}

@end

#endif

