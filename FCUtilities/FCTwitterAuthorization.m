//
//  FCTwitterAuthorization.m
//  Created by Marco Arment on 7/11/17.
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCTwitterAuthorization.h"
#include <CommonCrypto/CommonHMAC.h>
@import SafariServices;

@interface FCTwitterCredentials ()
@property (nonatomic) NSString *token;
@property (nonatomic) NSString *secret;
@property (nonatomic) NSString *username;
@end

@implementation FCTwitterCredentials
+ (instancetype)credentialsWithToken:(NSString *)token secret:(NSString *)secret username:(NSString *)username
{
    FCTwitterCredentials *creds = [FCTwitterCredentials new];
    creds.token = token ?: @"";
    creds.secret = secret ?: @"";
    creds.username = username ?: @"";
    return creds.token.length && creds.secret.length ? creds : nil;
}
@end

@interface FCBasicOAuthConsumer : NSObject
@property (nonatomic) NSString *consumerKey;
@property (nonatomic) NSString *consumerSecret;
@property (nonatomic) NSString *token;
@property (nonatomic) NSString *tokenSecret;
@property (nonatomic) NSString *reportedUsername;
@property (nonatomic) NSString *verifier;
- (void)signRequest:(NSMutableURLRequest *)request withOAuthCallbackURL:(NSURL *)callbackURL;
- (void)addAuthorizationResponse:(NSData *)responseData;
- (void)addAuthorizedResponseCallbackURL:(NSURL *)url;
+ (void)setPOSTParameters:(NSDictionary<NSString *, NSString *> *)dictionary forRequest:(NSMutableURLRequest *)request;
@end

@interface FCTwitterAuthorization ()
@property (nonatomic, copy) void (^completion)(FCTwitterCredentials *credentials);
@property (nonatomic, copy) NSString *consumerKey;
@property (nonatomic, copy) NSString *consumerSecret;
@property (nonatomic, copy) NSString *callbackURLScheme;
@property (nonatomic) SFAuthenticationSession *authenticationSession;
@property (nonatomic) NSURLSession *urlSession;
@end

static FCTwitterAuthorization *g_currentInstance = NULL;

@implementation FCTwitterAuthorization

+ (void)authorizeWithConsumerKey:(NSString *)key consumerSecret:(NSString *)secret callbackURLScheme:(NSString *)scheme completion:(void (^)(FCTwitterCredentials *credentials))completion
{
    [self cancel];
    if ( (g_currentInstance = [[self alloc] initWithConsumerKey:key consumerSecret:secret callbackURLScheme:scheme completion:completion]) ) {
        [g_currentInstance authorize];
    } else {
        if (completion) completion(nil);
    }
}

+ (void)cancel
{
    if (g_currentInstance) {
        [g_currentInstance finishWithCredentials:nil];
        g_currentInstance = nil;
    }
}

- (instancetype)initWithConsumerKey:(NSString *)key consumerSecret:(NSString *)secret callbackURLScheme:(NSString *)scheme completion:(void (^)(FCTwitterCredentials *credentials))completion
{
    if ( (self = [super init]) ) {
        self.consumerKey = key;
        self.consumerSecret = secret;
        self.completion = completion;
        self.callbackURLScheme = scheme;
    }
    return self;
}

+ (void)callbackURLReceived:(NSURL *)url { if (g_currentInstance) [g_currentInstance callbackURLReceived:url]; }
- (void)callbackURLReceived:(NSURL *)url
{
    NSString *queryString = url.host;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (NSString *pair in [queryString componentsSeparatedByString:@"&"]) {
        NSArray<NSString *> *parts = [pair componentsSeparatedByString:@"="];
        if (parts.count < 1 || parts[0].length < 1) continue;
        params[parts[0].stringByRemovingPercentEncoding] = parts.lastObject;
    }
    
    [self finishWithCredentials:[FCTwitterCredentials credentialsWithToken:params[@"token"] secret:params[@"secret"] username:params[@"username"]]];
}

- (void)authorize
{
    NSURL *appAuthURL = [NSURL URLWithString:[NSString stringWithFormat:
         @"twitterauth://authorize?consumer_key=%@&consumer_secret=%@&oauth_callback=%@",
         self.consumerKey, self.consumerSecret, self.callbackURLScheme
    ]];
    
    if ([UIApplication.sharedApplication canOpenURL:appAuthURL]) {
        [UIApplication.sharedApplication openURL:appAuthURL options:@{} completionHandler:^(BOOL success) {
            if (! success) [self startOAuthFlow];
        }];
    } else {
        [self startOAuthFlow];
    }
}

- (void)finishWithCredentials:(FCTwitterCredentials *)creds
{
    if (self.urlSession) [self.urlSession invalidateAndCancel];
    void (^completion)(FCTwitterCredentials *credentials) = self.completion;
    if (completion) completion(creds);
    self.completion = nil;
    g_currentInstance = nil;
}

#pragma mark - OAuth

- (void)startOAuthFlow
{
    FCBasicOAuthConsumer *oauth = [FCBasicOAuthConsumer new];
    oauth.consumerKey = self.consumerKey;
    oauth.consumerSecret = self.consumerSecret;

    // Request token
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"]];
    req.HTTPMethod = @"POST";
    [oauth signRequest:req withOAuthCallbackURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@:///", self.callbackURLScheme]]];

    self.urlSession = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration];
    [[self.urlSession dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [oauth addAuthorizationResponse:data];
        if (error || ((NSHTTPURLResponse *)response).statusCode != 200 || ! oauth.token.length || ! oauth.tokenSecret.length) {
            [self finishWithCredentials:nil];
            return;
        }
        
        NSURL *authURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/oauth/authenticate?oauth_token=%@", oauth.token]];
        self.authenticationSession = [[SFAuthenticationSession alloc] initWithURL:authURL callbackURLScheme:self.callbackURLScheme completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable e) {
			if (! callbackURL || e || [callbackURL.absoluteString containsString:@"?denied="]) {
                [self finishWithCredentials:nil];
                return;
            }

            [self authorizeOAuthConsumer:oauth withCallbackURL:callbackURL];
        }];
        [self.authenticationSession start];
    }] resume];
}

- (void)authorizeOAuthConsumer:(FCBasicOAuthConsumer *)oauth withCallbackURL:(NSURL *)callbackURL
{
    [oauth addAuthorizedResponseCallbackURL:callbackURL];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"]];
    [FCBasicOAuthConsumer setPOSTParameters:@{ @"oauth_verifier" : oauth.verifier } forRequest:req];
    [oauth signRequest:req withOAuthCallbackURL:nil];
    
    [[self.urlSession dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [oauth addAuthorizationResponse:data];
        if (error || ((NSHTTPURLResponse *)response).statusCode != 200 || ! oauth.token.length || ! oauth.tokenSecret.length) {
            [self finishWithCredentials:nil];
        } else {
            [self finishWithCredentials:[FCTwitterCredentials credentialsWithToken:oauth.token secret:oauth.tokenSecret username:oauth.reportedUsername]];
        }
    }] resume];
}

@end


@implementation FCBasicOAuthConsumer

+ (void)setPOSTParameters:(NSDictionary<NSString *, NSString *> *)dictionary forRequest:(NSMutableURLRequest *)request
{
    NSMutableArray *encodedFields = [NSMutableArray array];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [encodedFields addObject:[NSString stringWithFormat:@"%@=%@", [self rawURLEncodedString:key], [self rawURLEncodedString:value]]];
    }];

    request.HTTPMethod = @"POST";
    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [[encodedFields componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)rawURLEncodedString:(NSString *)str
{
    NSMutableCharacterSet *urlEncodingAllowedCharacters = [NSCharacterSet.URLQueryAllowedCharacterSet mutableCopy];
    [urlEncodingAllowedCharacters removeCharactersInString:@"?=&+:;@/$!'()\",*"];
    return [str stringByAddingPercentEncodingWithAllowedCharacters:urlEncodingAllowedCharacters];
}

- (NSString *)signatureForRequest:(NSURLRequest *)request authorizationParameters:(NSDictionary *)authorizationParameters
{
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
    NSMutableDictionary *allParams = [authorizationParameters mutableCopy];
    for (NSURLQueryItem *item in urlComponents.queryItems) { if (item.name.length) allParams[item.name] = item.value ?: @""; } // GET params
    if ([request.HTTPMethod isEqualToString:@"POST"] && request.HTTPBody.length > 0) {
        urlComponents.query = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        for (NSURLQueryItem *item in urlComponents.queryItems) { if (item.name.length) allParams[item.name] = item.value ?: @""; } // POST params
    }
    [allParams removeObjectForKey:@"oauth_signature"];
    urlComponents.queryItems = nil;
    NSURL *urlWithoutQueryParameters = urlComponents.URL;

    NSMutableArray<NSString *> *sortedQueryComponents = [NSMutableArray array];
    for (NSString *paramName in [allParams.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
        [sortedQueryComponents addObject:[NSString stringWithFormat:@"%@=%@", [self.class rawURLEncodedString:paramName], [self.class rawURLEncodedString:allParams[paramName]]]];
    }

    NSString *signatureBaseString = [@[
        request.HTTPMethod,
        [self.class rawURLEncodedString:urlWithoutQueryParameters.absoluteString],
        [self.class rawURLEncodedString:[sortedQueryComponents componentsJoinedByString:@"&"]],
    ] componentsJoinedByString:@"&"];
    
    const char *hmacKey = [[NSString stringWithFormat:@"%@&%@", self.consumerSecret, self.tokenSecret ?: @""] cStringUsingEncoding:NSASCIIStringEncoding];
    const char *hmacData = [signatureBaseString cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char hmacOut[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, hmacKey, strlen(hmacKey), hmacData, strlen(hmacData), hmacOut);
    return [[[NSData alloc] initWithBytes:hmacOut length:sizeof(hmacOut)] base64EncodedStringWithOptions:0];
}

- (NSDictionary *)authorizationParametersForRequest:(NSURLRequest *)request callbackURL:(NSURL *)callbackURL
{
    NSMutableDictionary *authorizationParams = [@{
        @"oauth_consumer_key" : self.consumerKey,
        @"oauth_signature_method" : @"HMAC-SHA1",
        @"oauth_timestamp" : [NSString stringWithFormat:@"%lld", (long long) time(NULL)],
        @"oauth_nonce" : NSUUID.UUID.UUIDString,
        @"oauth_version" : @"1.0",
    } mutableCopy];
    if (self.token) authorizationParams[@"oauth_token"] = self.token;
    if (callbackURL) authorizationParams[@"oauth_callback"] = callbackURL.absoluteString;

    authorizationParams[@"oauth_signature"] = [self signatureForRequest:request authorizationParameters:authorizationParams];
    return authorizationParams;
}

- (void)signRequest:(NSMutableURLRequest *)request withOAuthCallbackURL:(NSURL *)callbackURL
{
    NSDictionary *authorizationParams = [self authorizationParametersForRequest:request callbackURL:callbackURL];

    NSMutableArray *encodedParamPairs = [NSMutableArray array];
    [authorizationParams enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSString *value, BOOL *stop) {
        [encodedParamPairs addObject:[NSString stringWithFormat:@"%@=\"%@\"", [self.class rawURLEncodedString:name], [self.class rawURLEncodedString:value]]];
    }];
    [request setValue:[NSString stringWithFormat:@"OAuth %@", [encodedParamPairs componentsJoinedByString:@", "]] forHTTPHeaderField:@"Authorization"];
}

- (void)addAuthorizationResponse:(NSData *)responseData
{
    for (NSString *queryPair in [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"&"]) {
        NSArray<NSString *> *pair = [queryPair componentsSeparatedByString:@"="];
        NSString *name = pair.firstObject;
        if (pair.count != 2 || ! name.length) continue;
        
        if ([name isEqualToString:@"oauth_token"]) self.token = pair[1];
        else if ([name isEqualToString:@"oauth_token_secret"]) self.tokenSecret = pair[1];
        else if ([name isEqualToString:@"username"] || [name isEqualToString:@"screen_name"]) self.reportedUsername = pair[1];
    }
}

- (void)addAuthorizedResponseCallbackURL:(NSURL *)url
{
    for (NSURLQueryItem *queryItem in [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:nil].queryItems) {
        if ([queryItem.name isEqualToString:@"oauth_token"]) self.token = queryItem.value;
        else if ([queryItem.name isEqualToString:@"oauth_verifier"]) self.verifier = queryItem.value;
    }
}

@end



