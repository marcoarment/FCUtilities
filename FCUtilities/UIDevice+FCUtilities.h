//
//  UIDevice+FCUtilities.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <UIKit/UIKit.h>

// Using CPU detection responsibly:
//
//  - Assume unknown CPUs are *better* than all known CPUs.
//  - Enable all features, effects, animations, etc. by default.
//  - Only reduce functionality/effects on specific CPUs you've tested and found to be too slow.
//
typedef NS_ENUM(NSInteger, FCDeviceCPUClass) {
    FCDeviceCPUClassA4 = 0,
    FCDeviceCPUClassA5,
    FCDeviceCPUClassA6,
    FCDeviceCPUClassA7,
    FCDeviceCPUClassUnknown
};

// Using radio detection responsibly:
//
// - Having a cellular radio doesn't mean that it's enabled, or that your app is allowed to use it.
// - Having a cellular radio doesn't mean that Wi-Fi is enabled.
// - Assume "Unknown" could have either, both, or none. (Enable all features, controls, etc.)

typedef NS_ENUM(NSInteger, FCDeviceRadioType) {
    FCDeviceRadioTypeWiFiOnly = 0,
    FCDeviceRadioTypeCellular,
    FCDeviceRadioTypeUnknown
};

@interface UIDevice (FCUtilities)

- (FCDeviceCPUClass)fc_CPUClass;
- (FCDeviceRadioType)fc_radioType;
- (BOOL)fc_systemVersionIsAtLeast:(NSString *)versionString; // e.g. "7.0" or "7.0.4"
- (NSString *)fc_modelIdentifier;      // e.g. "iPhone5,1"
- (NSString *)fc_modelHumanIdentifier; // e.g. "iPhone 4S"
- (long long)fc_freeDiskSpaceInBytes;

@end
