//
//  FCTwitterAuthorization.m
//  Created by Marco Arment on 7/11/17.
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCTwitterAuthorization.h"

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

@interface FCTwitterAuthorization ()
@property (nonatomic, copy) void (^completion)(FCTwitterCredentials *credentials);
@property (nonatomic, copy) NSString *consumerKey;
@property (nonatomic, copy) NSString *consumerSecret;
@property (nonatomic, copy) NSString *callbackURLScheme;
@end

static FCTwitterAuthorization *g_currentInstance = NULL;

@implementation FCTwitterAuthorization

+ (BOOL)isTwitterAppInstalled { return [UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:@"twitterauth://authorize"]]; }

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
            if (! success) [self finishWithCredentials:nil];
        }];
    } else {
        [self finishWithCredentials:nil];
    }
}

- (void)finishWithCredentials:(FCTwitterCredentials *)creds
{
    void (^completion)(FCTwitterCredentials *credentials) = self.completion;
    if (completion) completion(creds);
    self.completion = nil;
    g_currentInstance = nil;
}

@end

