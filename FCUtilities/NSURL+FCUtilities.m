//
//  NSURL+FCUtilities.m
//  Pods
//
//  Created by Marco Arment on 5/9/14.
//
//

#import "NSURL+FCUtilities.h"

@implementation NSURL (FCUtilities)

- (NSDictionary *)fc_queryComponents
{
    NSString *query = self.query;
    if (! query || ! query.length) return @{ };
    
    NSMutableDictionary *decoded = [NSMutableDictionary dictionary];
    for (NSString *pair in [query componentsSeparatedByString:@"&"]) {
        NSArray *parts = [pair componentsSeparatedByString:@"="];
        if (! parts.count || ! [parts.firstObject length]) continue;
        
        if (parts.count == 1) {
            decoded[([parts[0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding])] = @"";
        } else if (parts.count == 2) {
            decoded[([parts[0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding])] = [parts[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }

    return decoded;
}

@end
