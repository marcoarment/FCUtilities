//
//  FCReachability.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCReachability.h"
@import Network;

NSString * const FCReachabilityChangedNotification = @"FCReachabilityChangedNotification";
NSString * const FCReachabilityOnlineNotification = @"FCReachabilityOnlineNotification";

@interface FCReachability () {
    nw_path_monitor_t monitor;
    dispatch_queue_t queue;
    BOOL wasOnline;
    BOOL wasCellular;
    BOOL wasExpensive;
    BOOL wasConstrained;
    BOOL isSettingInitialState;
}
@property (nonatomic) BOOL isOnline;
@property (nonatomic) BOOL isCellular;
@property (nonatomic) BOOL isExpensive;
@property (nonatomic) BOOL isConstrained;
@property (nonatomic) BOOL isUnrestricted;
@end

@implementation FCReachability

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static FCReachability *g_inst = nil;
    dispatch_once(&onceToken, ^{
        g_inst = [[FCReachability alloc] init];
    });
    return g_inst;
}

- (instancetype)init
{
    if ( (self = [super init]) ) {
        dispatch_queue_attr_t attrs = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, DISPATCH_QUEUE_PRIORITY_DEFAULT);
        queue = dispatch_queue_create("FCReachability", attrs);

        // initial state: assume online, but don't assume Wi-Fi until we know
        self.isOnline = wasOnline = YES;
        self.isCellular = wasCellular = YES;
        self.isExpensive = wasExpensive = YES;
        self.isConstrained = wasConstrained = YES;
        self.isUnrestricted = NO;

        monitor = nw_path_monitor_create();
        nw_path_monitor_set_queue(monitor, queue);

        __weak typeof(self) weakSelf = self;
        nw_path_monitor_set_update_handler(monitor, ^(nw_path_t path) {
            __strong typeof(self) strongSelf = weakSelf;
            if (! strongSelf) return;
            
            BOOL isOnline = nw_path_get_status(path) == nw_path_status_satisfied;
            strongSelf.isOnline = isOnline;
            strongSelf.isCellular = strongSelf.isOnline && nw_path_uses_interface_type(path, nw_interface_type_cellular);
            strongSelf.isExpensive = strongSelf.isOnline && nw_path_is_expensive(path);
            strongSelf.isConstrained = strongSelf.isOnline && nw_path_is_constrained(path);
            
            strongSelf.isUnrestricted = isOnline && ! (strongSelf.isCellular || strongSelf.isExpensive || strongSelf.isConstrained);
            
            BOOL onlineChanged = (strongSelf->wasOnline != isOnline);
            BOOL statusChanged = onlineChanged || (strongSelf.isCellular != strongSelf->wasCellular) || (strongSelf.isExpensive != strongSelf->wasExpensive) || (strongSelf.isConstrained != strongSelf->wasConstrained);
            strongSelf->wasOnline = isOnline;
            strongSelf->wasCellular = strongSelf.isCellular;
            strongSelf->wasExpensive = strongSelf.isExpensive;
            strongSelf->wasConstrained = strongSelf.isConstrained;
                        
            if (statusChanged && ! strongSelf->isSettingInitialState) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSNotificationCenter.defaultCenter postNotificationName:FCReachabilityChangedNotification object:strongSelf userInfo:nil];
                    if (onlineChanged && isOnline) {
                        [NSNotificationCenter.defaultCenter postNotificationName:FCReachabilityOnlineNotification object:strongSelf userInfo:nil];
                    }
                });
            }
        });

        isSettingInitialState = YES;
        nw_path_monitor_start(monitor);
        dispatch_sync(queue, ^{ }); // wait for initial state if it's queued synchronously in nw_path_monitor_start, which seems true
        isSettingInitialState = NO;
    }
    return self;
}

- (BOOL)internetConnectionIsOfflineForError:(NSError *)error
{
    return (error && (error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorNetworkConnectionLost || error.code == NSURLErrorDataNotAllowed));
}

@end
