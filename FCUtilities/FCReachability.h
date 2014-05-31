//
//  FCReachability.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <Foundation/Foundation.h>

extern NSString * const FCReachabilityStatusChangedNotification;
extern NSString * const FCReachabilityOfflineNotification;
extern NSString * const FCReachabilityOnlineNotification;
extern NSString * const FCReachabilityCellularPolicyChangedNotification;

typedef NS_ENUM(NSInteger, FCReachabilityStatus) {
    FCReachabilityStatusOffline = 0,
    FCReachabilityStatusOnlineViaCellular,
    FCReachabilityStatusOnlineViaWiFi
};

@interface FCReachability : NSObject

- (instancetype)initWithHostname:(NSString *)hostname allowCellular:(BOOL)allowCellular;
- (BOOL)internetConnectionIsOfflineForError:(NSError *)error;

@property (nonatomic) BOOL allowCellular;
@property (nonatomic, readonly) BOOL isOnline;
@property (nonatomic, readonly) BOOL isOnlineViaWiFi;
@property (nonatomic, readonly) FCReachabilityStatus status;

@end
