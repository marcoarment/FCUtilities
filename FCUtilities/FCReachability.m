//
//  FCReachability.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCBasics.h"
#import "FCReachability.h"
@import SystemConfiguration;

NSString * const FCReachabilityStatusChangedNotification = @"FCReachabilityStatusChangedNotification";
NSString * const FCReachabilityOnlineNotification = @"FCReachabilityStatusOnlineNotification";
NSString * const FCReachabilityOfflineNotification = @"FCReachabilityStatusOfflineNotification";
NSString * const FCReachabilityCellularPolicyChangedNotification = @"FCReachabilityStatusCellularPolicyChangedNotification";

@interface FCReachability () {
    BOOL isOnline;
    BOOL requireWiFi;
    SCNetworkReachabilityRef reachability;
}

- (void)update;

@property (nonatomic) SCNetworkReachabilityFlags reachabilityFlags;
@property (nonatomic) FCReachabilityStatus status;
@end


static void FCReachabilityChanged(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    FCReachability *fcr = (__bridge FCReachability *) info;
    fcr.status =
        (flags & kSCNetworkReachabilityFlagsReachable) ?
        (flags & kSCNetworkReachabilityFlagsIsWWAN ? FCReachabilityStatusOnlineViaCellular : FCReachabilityStatusOnlineViaWiFi) :
        FCReachabilityStatusOffline
    ;
    [fcr update];
}


@implementation FCReachability

- (instancetype)initWithHostname:(NSString *)hostname allowCellular:(BOOL)allowCellular;
{
    if ( (self = [super init]) ) {
        isOnline = YES;
        requireWiFi = ! allowCellular;
        [self setReachabilityHostname:hostname];
    }
    return self;
}

- (BOOL)isOnline { return isOnline; }

- (BOOL)allowCellular { return ! requireWiFi; }
- (void)setAllowCellular:(BOOL)allowCellular
{
    if (requireWiFi == allowCellular) {
        requireWiFi = ! allowCellular;
        fc_executeOnMainThread(^{
            [NSNotificationCenter.defaultCenter postNotificationName:FCReachabilityCellularPolicyChangedNotification object:self];
        });
        [self update];
    }
}

- (void)update
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL nowOnline = self.status == FCReachabilityStatusOnlineViaWiFi || (! requireWiFi && self.status == FCReachabilityStatusOnlineViaCellular);
        
        if (nowOnline && ! isOnline) {
            isOnline = YES;
            [NSNotificationCenter.defaultCenter postNotificationName:FCReachabilityOnlineNotification object:self];
        } else if (! nowOnline && isOnline) {
            isOnline = NO;
            [NSNotificationCenter.defaultCenter postNotificationName:FCReachabilityOfflineNotification object:self];
        }
        
        [NSNotificationCenter.defaultCenter postNotificationName:FCReachabilityStatusChangedNotification object:self];
    });
}

- (BOOL)internetConnectionIsOfflineForError:(NSError *)error
{
    if (error && (error.code == kCFURLErrorNotConnectedToInternet || error.code == kCFURLErrorNetworkConnectionLost)) {
        [self update];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Reachability support

- (void)setReachabilityHostname:(NSString *)hostname
{
    if (reachability) {
        SCNetworkReachabilitySetCallback(reachability, NULL, NULL);
        CFRelease(reachability);
        reachability = NULL;
    }
    
    if (hostname) {
        reachability = SCNetworkReachabilityCreateWithName(NULL, [hostname UTF8String]);
        if (! reachability) return;
        SCNetworkReachabilityContext context = { 0, (__bridge void *) self, NULL, NULL, NULL };
        SCNetworkReachabilitySetCallback(reachability, FCReachabilityChanged, &context);
        SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    }
}

- (void)dealloc
{
    if (reachability) {
        SCNetworkReachabilitySetCallback(reachability, NULL, NULL);
        SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
        CFRelease(reachability);
        reachability = NULL;
    }
}

@end
