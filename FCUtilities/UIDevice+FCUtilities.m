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
        if ([mid isEqualToString:@"iPad4,3"]) { fcCPUClass = FCDeviceCPUClassA7; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad Air"); } // China

        if ([mid isEqualToString:@"iPad4,4"]) { fcCPUClass = FCDeviceCPUClassA7; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPad Mini 2"); }
        if ([mid isEqualToString:@"iPad4,5"]) { fcCPUClass = FCDeviceCPUClassA7; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad Mini 2"); }
        if ([mid isEqualToString:@"iPad4,6"]) { fcCPUClass = FCDeviceCPUClassA7; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad Mini 2"); } // China

        if ([mid isEqualToString:@"iPad4,7"]) { fcCPUClass = FCDeviceCPUClassA7; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPad Mini 3"); }
        if ([mid isEqualToString:@"iPad4,8"]) { fcCPUClass = FCDeviceCPUClassA7; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad Mini 3"); }
        if ([mid isEqualToString:@"iPad4,9"]) { fcCPUClass = FCDeviceCPUClassA7; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad Mini 3"); } // China
        
        if ([mid isEqualToString:@"iPad5,1"]) { fcCPUClass = FCDeviceCPUClassA8; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPad Mini 4"); }
        if ([mid isEqualToString:@"iPad5,2"]) { fcCPUClass = FCDeviceCPUClassA8; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad Mini 4"); }

        if ([mid isEqualToString:@"iPad5,3"]) { fcCPUClass = FCDeviceCPUClassA8; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPad Air 2"); }
        if ([mid isEqualToString:@"iPad5,4"]) { fcCPUClass = FCDeviceCPUClassA8; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad Air 2"); }
        
        if ([mid isEqualToString:@"iPad6,7"]) { fcCPUClass = FCDeviceCPUClassA9; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPad Pro 12.9-inch"); }
        if ([mid isEqualToString:@"iPad6,8"]) { fcCPUClass = FCDeviceCPUClassA9; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad Pro 12.9-inch"); }
        
        if ([mid isEqualToString:@"iPad6,3"]) { fcCPUClass = FCDeviceCPUClassA9; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPad Pro 9.7-inch"); }
        if ([mid isEqualToString:@"iPad6,4"]) { fcCPUClass = FCDeviceCPUClassA9; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPad Pro 9.7-inch"); }
        
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

        if ([mid isEqualToString:@"iPhone7,1"])  { fcCPUClass = FCDeviceCPUClassA8; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 6 Plus"); }
        if ([mid isEqualToString:@"iPhone7,1*"]) { fcCPUClass = FCDeviceCPUClassA8; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 6 Plus"); } // China
        if ([mid isEqualToString:@"iPhone7,2"])  { fcCPUClass = FCDeviceCPUClassA8; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 6"); }
        if ([mid isEqualToString:@"iPhone7,2*"]) { fcCPUClass = FCDeviceCPUClassA8; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 6"); } // China
        
        if ([mid isEqualToString:@"iPhone8,1"]) { fcCPUClass = FCDeviceCPUClassA9; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 6s"); }
        if ([mid isEqualToString:@"iPhone8,2"]) { fcCPUClass = FCDeviceCPUClassA9; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone 6s Plus"); }
        
        if ([mid isEqualToString:@"iPhone8,4"]) { fcCPUClass = FCDeviceCPUClassA9; fcRadioType = FCDeviceRadioTypeCellular; return (fcModelHumanIdentifier = @"iPhone SE"); }

        if ([mid isEqualToString:@"iPod5,1"])    { fcCPUClass = FCDeviceCPUClassA5; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPod 5G"); }
        if ([mid isEqualToString:@"iPod7,1"])    { fcCPUClass = FCDeviceCPUClassA8; fcRadioType = FCDeviceRadioTypeWiFiOnly; return (fcModelHumanIdentifier = @"iPod 6G"); }
        
        fcCPUClass = FCDeviceCPUClassUnknown;
        fcRadioType = FCDeviceRadioTypeUnknown;
        return (fcModelHumanIdentifier = @"iPhone");
    }
}

@end
