//
//  NSString+FCUtilities.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "NSString+FCUtilities.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (FCUtilities)

- (NSString *)fc_URLEncodedString
{
    NSMutableCharacterSet *allowedCharacters = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacters removeCharactersInString:@"?=&+:;@/$!'()\",*"];
    return [self stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
}

- (NSString *)fc_HTMLEncodedString
{
#if IS_MAC
	CFStringRef cs = CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (CFStringRef) self, NULL);
	NSString *str = [NSString stringWithString:(NSString *) cs];
	CFRelease(cs);
	return str;
#else
    NSString *h = [self stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    h = [h stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    h = [h stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    h = [h stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    return h;
#endif
}

- (NSString *)fc_stringWithNormalizedWhitespace
{
    NSCharacterSet *whitespaceSet = NSCharacterSet.whitespaceAndNewlineCharacterSet;
    NSMutableString *outputString = [NSMutableString string];
    NSScanner *scanner = [[NSScanner alloc] initWithString:self];
    while (! scanner.isAtEnd) {
        NSString *segment = NULL;
        [scanner scanUpToCharactersFromSet:whitespaceSet intoString:&segment];
        [scanner scanCharactersFromSet:whitespaceSet intoString:NULL];
        if (segment) { [outputString appendString:segment]; [outputString appendString:@" "]; }
    }
    
    return [outputString stringByTrimmingCharactersInSet:whitespaceSet];
}

- (NSString *)fc_summarizeToLength:(int)length withEllipsis:(BOOL)ellipsis
{
	NSString *str = self;
	if ([str length] > length) {
		str = [str substringToIndex:length];

		// Find last space, trim to it
		NSRange offset = [str rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] options:NSBackwardsSearch range:NSMakeRange(0, length)];
		if (offset.location == NSNotFound) offset.location = length;
		str = [NSString stringWithFormat:@"%@%@", [str substringToIndex:offset.location], ellipsis ? @"\xE2\x80\xA6" : @""];
	}
	return str;
}

- (NSString *)fc_substringAfter:(NSString *)needle fromEnd:(BOOL)reverse
{
	NSRange r = [self rangeOfString:needle options:(reverse ? NSBackwardsSearch : 0)];
	if (r.location == NSNotFound) return self;
	return [self substringFromIndex:(r.location + r.length)];
}

- (NSString *)fc_substringBefore:(NSString *)needle fromEnd:(BOOL)reverse
{
	NSRange r = [self rangeOfString:needle options:(reverse ? NSBackwardsSearch : 0)];
	if (r.location == NSNotFound) return self;
	return [self substringToIndex:r.location];
}

- (NSString *)fc_substringBetween:(NSString *)leftCap and:(NSString *)rightCap
{
	return [[self fc_substringAfter:leftCap fromEnd:NO] fc_substringBefore:rightCap fromEnd:NO];
}

- (BOOL)fc_contains:(NSString *)needle
{
	return ([self rangeOfString:needle].location != NSNotFound);
}

- (NSString *)fc_trimSubstringFromStart:(NSString *)needle
{
	NSInteger nlen = [needle length];
	NSString *ret = self;
	while ([ret hasPrefix:needle]) ret = [ret substringFromIndex:nlen];
	return ret;
}

- (NSString *)fc_trimSubstringFromEnd:(NSString *)needle
{
	NSInteger nlen = [needle length];
	NSString *ret = self;
	while ([ret hasSuffix:needle]) ret = [ret substringToIndex:([ret length] - nlen)];
	return ret;
}

- (NSString *)fc_trimSubstringFromBothEnds:(NSString *)needle
{
	return [[self fc_trimSubstringFromStart:needle] fc_trimSubstringFromEnd:needle];
}

- (NSString *)fc_hexString
{
    const char *utf8 = [self UTF8String];
    NSMutableString *hex = [NSMutableString string];
    while ( *utf8 ) [hex appendFormat:@"%02X" , *utf8++ & 0x00FF];
    return [NSString stringWithFormat:@"%@", hex];
}

- (NSString *)fc_URLSafeBase64EncodedString
{
    NSString *str = [[self dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    str = [str stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    str = [str stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    str = [str stringByReplacingOccurrencesOfString:@"=" withString:@""];
    return str;
}

- (NSString *)fc_stringByReplacingMatches:(NSRegularExpression *)regex usingBlock:(NSString *(^)(NSTextCheckingResult *match, NSArray<NSString *> *captureGroups))replacementBlock
{
    if (! replacementBlock) return self;
    
    NSUInteger numCaptureGroups = regex.numberOfCaptureGroups;
    NSMutableString *mutableString = [self mutableCopy];
    NSInteger offset = 0;
    for (NSTextCheckingResult *result in [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)]) {
        NSMutableArray<NSString *> *captureGroups = [NSMutableArray arrayWithCapacity:numCaptureGroups + 1];
        for (NSUInteger g = 0; g <= numCaptureGroups; g++) {
            NSRange captureRange = [result rangeAtIndex:g];
            captureGroups[g] = captureRange.location == NSNotFound ? @"" : [self substringWithRange:captureRange];
        }
        
        NSRange resultRange = result.range;
        resultRange.location += offset;
        NSString *replacement = replacementBlock(result, captureGroups);
        [mutableString replaceCharactersInRange:resultRange withString:replacement];
        offset += (replacement.length - resultRange.length);
    }
    return mutableString;
}

@end
