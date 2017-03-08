//
//  FCExtensionPipe.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//
// A basic way for members of a shared iOS App Group container to pass messages to each other.
//
// Any given pipe identifier should be one-way within a process, and each pipe should only have one writer, e.g.:
//
//  - the master app can write to a pipe named e.g. "fromApp" but should not read from it, while extensions can read it
//  - an extension could write to a pipe named e.g. "fromWatchKit" that the master app reads from but doesn't write
//
#import <Foundation/Foundation.h>

@interface FCExtensionPipe : NSObject

// Receive messages by retaining one of these. remotePipeIdentifier must be filename-safe.
- (instancetype)initWithAppGroupIdentifier:(NSString *)appGroupID remotePipeIdentifier:(NSString *)remotePipeID target:(__weak id)target action:(SEL)actionTakingNSDictionary;

// Send messages statically. pipeIdentifier must be filename-safe.
+ (void)sendMessageToAppGroupIdentifier:(NSString *)appGroupIdentifier pipeIdentifier:(NSString *)pipeIdentifier userInfo:(NSDictionary *)userInfo;


@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;

@property (nonatomic, readonly) NSDictionary *lastMessage; // For optional conveniences only. Retention not guaranteed.

@end
