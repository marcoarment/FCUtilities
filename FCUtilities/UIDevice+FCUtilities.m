//
//  UIDevice+FCUtilities.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "UIDevice+FCUtilities.h"
#import <unistd.h>
#include <sys/types.h>
#include <sys/sysctl.h>

static NSString *fcModelHumanIdentifier = NULL;
static FCDeviceCPUClass fcCPUClass;
static FCDeviceRadioType fcRadioType;

@implementation UIDevice (FCUtilities)

- (BOOL)fc_systemVersionIsAtLeast:(NSString *)versionString
{
    return [[UIDevice currentDevice].systemVersion compare:versionString options:NSNumericSearch] != NSOrderedAscending;
}

- (NSString *)fc_modelIdentifier
{
	size_t size;
	sysctlbyname("hw.machine", NULL, &size, NULL, 0); 
	char *name = malloc(size);
	sysctlbyname("hw.machine", name, &size, NULL, 0);
	NSString *machine = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
	free(name);
	return machine;
}

- (FCDeviceCPUClass)fc_CPUClass
{
    if (! fcModelHumanIdentifier) [self fc_modelHumanIdentifier];
    return fcCPUClass;
}

- (FCDeviceRadioType)fc_radioType
{
    if (! fcModelHumanIdentifier) [self fc_modelHumanIdentifier];
    return fcRadioType;
}

- (NSString *)fc_modelHumanIdentifier
{
    if (fcModelHumanIdentifier) return fcModelHumanIdentifier;
    
    NSString *mid = self.fc_modelIdentifier;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if ([mid isEqualToString:@"iPad2,1"]) { fcCPUClass = FCDeviceCPUClassA5; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPad 2"); }
        if ([mid isEqualToString:@"iPad2,2"]) { fcCPUClass = FCDeviceCPUClassA5; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad 2"); }
        if ([mid isEqualToString:@"iPad2,3"]) { fcCPUClass = FCDeviceCPUClassA5; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad 2"); }
        if ([mid isEqualToString:@"iPad2,4"]) { fcCPUClass = FCDeviceCPUClassA5; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPad 2"); }

        if ([mid isEqualToString:@"iPad3,1"]) { fcCPUClass = FCDeviceCPUClassA5; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPad 3"); }
        if ([mid isEqualToString:@"iPad3,2"]) { fcCPUClass = FCDeviceCPUClassA5; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad 3"); }
        if ([mid isEqualToString:@"iPad3,3"]) { fcCPUClass = FCDeviceCPUClassA5; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad 3"); }

        if ([mid isEqualToString:@"iPad3,4"]) { fcCPUClass = FCDeviceCPUClassA6; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPad 4"); }
        if ([mid isEqualToString:@"iPad3,5"]) { fcCPUClass = FCDeviceCPUClassA6; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad 4"); }
        if ([mid isEqualToString:@"iPad3,6"]) { fcCPUClass = FCDeviceCPUClassA6; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad 4"); }

        if ([mid isEqualToString:@"iPad2,5"]) { fcCPUClass = FCDeviceCPUClassA5; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPad Mini"); }
        if ([mid isEqualToString:@"iPad2,6"]) { fcCPUClass = FCDeviceCPUClassA5; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad Mini"); }
        if ([mid isEqualToString:@"iPad2,7"]) { fcCPUClass = FCDeviceCPUClassA5; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad Mini"); }

        if ([mid isEqualToString:@"iPad4,1"]) { fcCPUClass = FCDeviceCPUClassA7; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPad Air"); }
        if ([mid isEqualToString:@"iPad4,2"]) { fcCPUClass = FCDeviceCPUClassA7; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad Air"); }

        if ([mid isEqualToString:@"iPad4,4"]) { fcCPUClass = FCDeviceCPUClassA7; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"Retina iPad Mini"); }
        if ([mid isEqualToString:@"iPad4,5"]) { fcCPUClass = FCDeviceCPUClassA7; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"Retina iPad Mini"); }
        
        fcCPUClass = FCDeviceCPUClassUnknown;
        fcRadioType = FCDeviceRadioTypeUnknown;
        return (fcModelHumanIdentifier = @"iPad");
    } else {
        if ([mid isEqualToString:@"iPhone3,1"])  { fcCPUClass = FCDeviceCPUClassA4; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 4"); }
        if ([mid isEqualToString:@"iPhone3,2"])  { fcCPUClass = FCDeviceCPUClassA4; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 4"); }
        if ([mid isEqualToString:@"iPhone3,3"])  { fcCPUClass = FCDeviceCPUClassA4; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 4"); }

        if ([mid isEqualToString:@"iPhone4,1"])  { fcCPUClass = FCDeviceCPUClassA5; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 4S"); }
        if ([mid isEqualToString:@"iPhone4,1*"]) { fcCPUClass = FCDeviceCPUClassA5; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 4S"); }
        
        if ([mid isEqualToString:@"iPhone5,1"])  { fcCPUClass = FCDeviceCPUClassA6; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 5"); }
        if ([mid isEqualToString:@"iPhone5,2"])  { fcCPUClass = FCDeviceCPUClassA6; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 5"); }

        if ([mid isEqualToString:@"iPhone5,3"])  { fcCPUClass = FCDeviceCPUClassA6; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 5c"); }
        if ([mid isEqualToString:@"iPhone5,4"])  { fcCPUClass = FCDeviceCPUClassA6; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 5c"); }
        
        if ([mid isEqualToString:@"iPhone6,1"])  { fcCPUClass = FCDeviceCPUClassA7; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 5s"); }
        if ([mid isEqualToString:@"iPhone6,2"])  { fcCPUClass = FCDeviceCPUClassA7; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 5s"); }

        if ([mid isEqualToString:@"iPod5,1"])    { fcCPUClass = FCDeviceCPUClassA5; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPod 5G"); }
        
        fcCPUClass = FCDeviceCPUClassUnknown;
        fcRadioType = FCDeviceRadioTypeUnknown;
        return (fcModelHumanIdentifier = @"iPhone");
    }
}

- (long long)fc_freeDiskSpaceInBytes
{
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] error:NULL];
    NSNumber *freeSpace;
    return attributes && (freeSpace = attributes[NSFileSystemFreeSize]) ? freeSpace.longLongValue : -1;
}

@end
