//
//  NSURLSession+FCUtilities.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "NSURLSession+FCUtilities.h"

@implementation NSURLSession (FCUtilities)

- (NSData * _Nullable)fc_sendSynchronousRequest:(NSURLRequest * _Nonnull)request returningResponse:(NSURLResponse * _Nullable * _Nullable)response error:(NSError * _Nullable * _Nullable)error
{
    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    __block NSData *data = nil;

    [[self dataTaskWithRequest:request completionHandler:^(NSData * _Nullable gotData, NSURLResponse * _Nullable gotResponse, NSError * _Nullable gotError) {
        data = gotData;
        if (response) *response = gotResponse;
        if (error) *error = gotError;
        dispatch_semaphore_signal(done);
    }] resume];

    dispatch_semaphore_wait(done, DISPATCH_TIME_FOREVER);
    return data;
}


@end
