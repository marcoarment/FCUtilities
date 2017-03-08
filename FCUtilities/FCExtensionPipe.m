//
//  FCExtensionPipe.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCExtensionPipe.h"
#include <notify.h>

static void notificationCenterCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    FCExtensionPipe *instance = (__bridge FCExtensionPipe *) observer;
    if (instance && [instance isKindOfClass:FCExtensionPipe.class]) {
        __strong id target = instance.target;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [target performSelector:instance.action withObject:instance.lastMessage];
#pragma clang diagnostic pop
    }
}


@interface FCExtensionPipe ()
@property (nonatomic) NSString *filename;
@end

@implementation FCExtensionPipe

- (instancetype)initWithAppGroupIdentifier:(NSString *)appGroupID remotePipeIdentifier:(NSString *)remotePipeID target:(__weak id)target action:(SEL)actionTakingNSDictionary
{
    if ( (self = [super init]) ) {
        self.target = target;
        self.action = actionTakingNSDictionary;
        self.filename = [self.class filenameForAppGroupIdentifier:appGroupID sourceIdentifier:remotePipeID];
        
        CFStringRef cfStrID = (__bridge CFStringRef) [NSString stringWithFormat:@"%@.%@", appGroupID, remotePipeID];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *) self, notificationCenterCallback, cfStrID, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    }
    return self;
}

- (void)dealloc
{
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *) self);
}

- (NSDictionary *)lastMessage { return [NSDictionary dictionaryWithContentsOfFile:self.filename]; }

+ (NSString *)filenameForAppGroupIdentifier:(NSString *)appGroupID sourceIdentifier:(NSString *)s
{
    return [[NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:appGroupID].path stringByAppendingPathComponent:[NSString stringWithFormat:@"FCExtensionPipe-%@", s]];
}

+ (void)sendMessageToAppGroupIdentifier:(NSString *)appGroupID pipeIdentifier:(NSString *)pipeID userInfo:(NSDictionary *)userInfo
{
    NSError *error;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:userInfo format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    if (! data) {
        [[[NSException alloc] initWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"FCExtensionPipe data error: %@", error.localizedDescription] userInfo:nil] raise];
    }

    if (! [data writeToFile:[self filenameForAppGroupIdentifier:appGroupID sourceIdentifier:pipeID] atomically:YES]) {
        [[[NSException alloc] initWithName:NSInvalidArgumentException reason:@"FCExtensionPipe write error" userInfo:nil] raise];
    }

    CFStringRef cfStrID = (__bridge CFStringRef) [NSString stringWithFormat:@"%@.%@", appGroupID, pipeID];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), cfStrID, NULL, NULL, YES);
}

@end

