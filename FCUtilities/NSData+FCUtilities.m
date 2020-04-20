//
//  NSData+FCUtilities.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "NSData+FCUtilities.h"
#import <zlib.h>
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (FCUtilities)

+ (NSData *)fc_randomDataWithLength:(NSUInteger)length
{
    NSMutableData *data = [NSMutableData dataWithLength:length];
    if (0 != SecRandomCopyBytes(kSecRandomDefault, length, (uint8_t *) data.mutableBytes)) return nil;
    return [data copy];
}

- (NSString *)fc_stringValue
{
    return [[NSString alloc] initWithBytes:[self bytes] length:[self length] encoding:NSUTF8StringEncoding];
}

- (NSString *)fc_hexString
{
	NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:([self length] * 2)];	
    const unsigned char *dataBuffer = [self bytes];
    int i;
    for (i = 0; i < [self length]; ++i) {
        [stringBuffer appendFormat:@"%02lx", (unsigned long)dataBuffer[i]];
	}
    return [stringBuffer copy];
}

- (NSString *)fc_URLSafeBase64EncodedString
{
    NSString *str = [self base64EncodedStringWithOptions:0];
    str = [str stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    str = [str stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    str = [str stringByReplacingOccurrencesOfString:@"=" withString:@""];
    return str;
}

// Deflate functions adapted from:
// http://code.google.com/p/google-toolbox-for-mac/source/browse/trunk/Foundation/GTMNSData%2Bzlib.m?r=5

- (NSData *)fc_deflatedData
{
    z_stream strm;
    bzero(&strm, sizeof(z_stream));
    strm.avail_in = (unsigned int) self.length;
    strm.next_in = (unsigned char *) self.bytes;
    if (Z_OK != deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15, 8, Z_DEFAULT_STRATEGY)) return nil;

    NSMutableData *result = [NSMutableData dataWithCapacity:(self.length / 10)];
    unsigned char output[1024];
    int retCode;
    do {
        strm.avail_out = 1024;
        strm.next_out = output;
        retCode = deflate(&strm, Z_FINISH);
        if ( (retCode != Z_OK) && (retCode != Z_STREAM_END) ) {
            deflateEnd(&strm);
            return nil;
        }

        unsigned gotBack = 1024 - strm.avail_out;
        if (gotBack > 0) [result appendBytes:output length:gotBack];
    } while (retCode == Z_OK);

    deflateEnd(&strm);
    return result;
}

- (NSData *)fc_inflatedDataWithHeader:(BOOL)headerPresent
{
	z_stream strm;
	bzero(&strm, sizeof(z_stream));
	strm.avail_in = (int) self.length;
	strm.next_in = (unsigned char *) self.bytes;
	if (Z_OK != inflateInit2(&strm, (headerPresent ? 47 : -MAX_WBITS))) return nil;

	NSMutableData *result = [NSMutableData dataWithCapacity:(self.length * 2)];
	unsigned char output[1024];
	int retCode;
	do {
		strm.avail_out = 1024;
		strm.next_out = output;
		retCode = inflate(&strm, Z_NO_FLUSH);
		if ((retCode != Z_OK) && (retCode != Z_STREAM_END)) {
			inflateEnd(&strm);
			return nil;
		}

		unsigned gotBack = 1024 - strm.avail_out;
		if (gotBack > 0) [result appendBytes:output length:gotBack];
	} while (retCode == Z_OK);
    
	inflateEnd(&strm);
	return result;
}

@end
