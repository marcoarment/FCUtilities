//
//  FCExtensionPipe.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCExtensionPipe.h"

// thanks http://stackoverflow.com/questions/7017281/performselector-may-cause-a-leak-because-its-selector-is-unknown
#define SUPPRESS_PERFORM_SELECTOR_LEAK_WARNING(code)                        \
    _Pragma("clang diagnostic push")                                        \
    _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"")     \
    code;                                                                   \
    _Pragma("clang diagnostic pop")                                         \


@interface FCExtensionPipe () {
    dispatch_source_t source;
    dispatch_queue_t queue;
}
@end

@implementation FCExtensionPipe

- (instancetype)initWithAppGroupIdentifier:(NSString *)appGroupID remotePipeIdentifier:(NSString *)remotePipeID target:(__weak id)target action:(SEL)actionTakingNSDictionary
{
    if ( (self = [super init]) ) {
        NSString *filename = [self.class filenameForAppGroupIdentifier:appGroupID sourceIdentifier:remotePipeID];

        if (! [NSFileManager.defaultManager fileExistsAtPath:filename]) {
            if (! [NSFileManager.defaultManager createFileAtPath:filename contents:NSData.data attributes:nil]) {
                [[[NSException alloc] initWithName:NSGenericException reason:@"Cannot write initial file to App Group container" userInfo:nil] raise];
            }
        }
        
        queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
        const char *fsp = filename.fileSystemRepresentation;
        int fd = open(fsp, O_EVTONLY);
        source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_WRITE, queue);
        dispatch_source_set_cancel_handler(source, ^{ close(fd); });

        dispatch_source_set_event_handler(source, ^{
            __strong id strongTarget = target;
            NSDictionary *message = [NSDictionary dictionaryWithContentsOfFile:filename];
            
            if (strongTarget && message) dispatch_async(dispatch_get_main_queue(), ^{
                SUPPRESS_PERFORM_SELECTOR_LEAK_WARNING([strongTarget performSelector:actionTakingNSDictionary withObject:message]);
            });
        });

        dispatch_resume(source);
    }
    return self;
}

- (void)dealloc
{
    dispatch_source_cancel(source);
}

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

    if (! [data writeToFile:[self filenameForAppGroupIdentifier:appGroupID sourceIdentifier:pipeID] options:0 error:&error]) {
        [[[NSException alloc] initWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"FCExtensionPipe write error: %@", error.localizedDescription] userInfo:nil] raise];
    }
}

@end
