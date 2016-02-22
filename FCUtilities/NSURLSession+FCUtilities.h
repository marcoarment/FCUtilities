//
//  NSURLSession+FCUtilities.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <Foundation/Foundation.h>

@interface NSURLSession (FCUtilities)

- (NSData * _Nullable)fc_sendSynchronousRequest:(NSURLRequest * _Nonnull)request returningResponse:(NSURLResponse * _Nullable * _Nullable)response error:(NSError * _Nullable * _Nullable)error;

@end
