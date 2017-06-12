//
//  NSURLSession+FCUtilities.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "NSURLSession+FCUtilities.h"

@implementation NSURLSession (FCUtilities)

- (NSData * _Nullable)fc_sendSynchronousRequest:(NSURLRequest * _Nonnull)request returningResponse:(NSURLResponse * _Nullable __autoreleasing * _Nullable)response error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    __block NSData *data = nil;
    
    BOOL captureResponse = (response != nil);
    BOOL captureError = (error != nil);
    
    [[self dataTaskWithRequest:request completionHandler:^(NSData * _Nullable gotData, NSURLResponse * _Nullable gotResponse, NSError * _Nullable gotError) {
        data = gotData;
        if (captureResponse) *response = gotResponse;
        if (captureError) *error = [gotError copy];
        dispatch_semaphore_signal(done);
    }] resume];

    dispatch_semaphore_wait(done, DISPATCH_TIME_FOREVER);
    return data;
}


@end
