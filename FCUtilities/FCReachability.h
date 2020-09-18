//
//  FCReachability.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <Foundation/Foundation.h>

extern NSString * const FCReachabilityChangedNotification;
extern NSString * const FCReachabilityOnlineNotification;

@interface FCReachability : NSObject

+ (instancetype)sharedInstance;
- (BOOL)internetConnectionIsOfflineForError:(NSError *)error;

@property (nonatomic, readonly) BOOL isOnline;
@property (nonatomic, readonly) BOOL isUnrestricted; // Wi-Fi, Ethernet, etc. not marked by Low Data Mode or "expensive" (tethering, etc.)
@property (nonatomic, readonly) BOOL isCellular;     // consider using isExpensive instead, which is semantically usually more correct
@property (nonatomic, readonly) BOOL isExpensive;    // includes cellular and tethering
@property (nonatomic, readonly) BOOL isConstrained;  // Low Data Mode

@end
