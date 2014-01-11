//
//  NSString+FCUtilities.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <Foundation/Foundation.h>

@interface NSString (FCUtilities)

- (NSString *)fc_URLEncodedString;
- (NSString *)fc_summarizeToLength:(int)length withEllipsis:(BOOL)ellipsis;

- (NSString *)fc_substringAfter:(NSString *)needle fromEnd:(BOOL)reverse;
- (NSString *)fc_substringBefore:(NSString *)needle fromEnd:(BOOL)reverse;
- (NSString *)fc_substringBetween:(NSString *)leftCap and:(NSString *)rightCap;

- (NSString *)fc_trimSubstringFromStart:(NSString *)needle;
- (NSString *)fc_trimSubstringFromEnd:(NSString *)needle;
- (NSString *)fc_trimSubstringFromBothEnds:(NSString *)needle;

- (BOOL)fc_contains:(NSString *)needle;

- (NSString *)fc_HTMLEncodedString;
- (NSString *)fc_hexString;
- (NSString *)fc_MD5Digest;

@end
