//
//  NSDate+FCUtilities.h
//  Part of FCUtilities by Marco Arment (Added NSDate Luke Durrant). See included LICENSE file for BSD license.
//


#import <Foundation/Foundation.h>
// Also requires libz to be linked, but "@import libz;" doesn't work, presumably because it's not a full-fledged framework

@interface NSDate (FCUtilities)

+(NSDate *)fc_dateWithDotNetJSONString:(NSString *)string;
@end
