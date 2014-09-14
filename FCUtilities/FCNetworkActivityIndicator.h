//
//  FCNetworkActivityIndicator.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <Foundation/Foundation.h>

@interface FCNetworkActivityIndicator : NSObject

+ (void)incrementActivityCount;
+ (void)decrementActivityCount;

@end
