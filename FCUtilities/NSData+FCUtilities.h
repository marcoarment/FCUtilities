//
//  NSData+FCUtilities.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//


#import <Foundation/Foundation.h>
@import Security;
// Also requires libz to be linked, but "@import libz;" doesn't work, presumably because it's not a full-fledged framework

@interface NSData (FCUtilities)

+ (NSData *)fc_randomDataWithLength:(NSUInteger)length;
- (NSData *)fc_deflatedData;
- (NSData *)fc_inflatedDataWithHeader:(BOOL)headerPresent; // pass NO for raw deflate data without a gzip header, such as PHP's gzdeflate() output
- (NSData *)fc_MD5Digest;
- (NSString *)fc_stringValue;
- (NSString *)fc_hexString;

@end
