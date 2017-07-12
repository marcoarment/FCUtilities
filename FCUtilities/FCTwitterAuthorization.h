//
//  FCTwitterAuthorization.h
//  Created by Marco Arment on 7/11/17.
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <Foundation/Foundation.h>

@interface FCTwitterCredentials : NSObject
@property (nonatomic, readonly) NSString *token;
@property (nonatomic, readonly) NSString *secret;
@property (nonatomic, readonly) NSString *username;
@end

/*  USAGE
    1. Add a unique URL scheme to Info.plist starting with "twitterkit-", e.g. "twitterkit-123notetaker"
    2. Pass that as callbackURLScheme when using authorizeWithConsumerKey:...
    3. In the app delegate's application:openURL:options:, if the URL scheme matches step 1's, pass it to [FCTwitterAuthorization callbackURLReceived:]
    4. Add the URL scheme "twitterauth" to LSApplicationQueriesSchemes in Info.plist
    5. Ensure your app's Settings on https://apps.twitter.com/ include a valid web Callback URL (which won't be used in this flow) and Callback Locking is OFF.
*/

@interface FCTwitterAuthorization : NSObject

+ (void)authorizeWithConsumerKey:(NSString *)key consumerSecret:(NSString *)secret callbackURLScheme:(NSString *)scheme completion:(void (^)(FCTwitterCredentials *credentials))completion;

+ (void)cancel;

+ (void)callbackURLReceived:(NSURL *)url;

@end

