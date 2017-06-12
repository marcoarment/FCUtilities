//
//  NSURLSession+FCUtilities.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <Foundation/Foundation.h>

@interface NSURLSession (FCUtilities)

- (NSData * _Nullable)fc_sendSynchronousRequest:(NSURLRequest * _Nonnull)request returningResponse:(NSURLResponse * _Nullable __autoreleasing * _Nullable)response error:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end
