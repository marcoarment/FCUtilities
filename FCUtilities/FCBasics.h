//
//  FCBasics.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

@import UIKit;

#define user_defaults_get_bool(key)   [[NSUserDefaults standardUserDefaults] boolForKey:key]
#define user_defaults_get_int(key)    ((int) [[NSUserDefaults standardUserDefaults] integerForKey:key])
#define user_defaults_get_double(key) [[NSUserDefaults standardUserDefaults] doubleForKey:key]
#define user_defaults_get_string(key) fc_safeString([[NSUserDefaults standardUserDefaults] stringForKey:key])
#define user_defaults_get_array(key)  [[NSUserDefaults standardUserDefaults] arrayForKey:key]
#define user_defaults_get_object(key) [[NSUserDefaults standardUserDefaults] objectForKey:key]

#define user_defaults_set_bool(key, b)   { [[NSUserDefaults standardUserDefaults] setBool:b    forKey:key]; [[NSUserDefaults standardUserDefaults] synchronize]; }
#define user_defaults_set_int(key, i)    { [[NSUserDefaults standardUserDefaults] setInteger:i forKey:key]; [[NSUserDefaults standardUserDefaults] synchronize]; }
#define user_defaults_set_double(key, d) { [[NSUserDefaults standardUserDefaults] setDouble:d  forKey:key]; [[NSUserDefaults standardUserDefaults] synchronize]; }
#define user_defaults_set_string(key, s) { [[NSUserDefaults standardUserDefaults] setObject:s  forKey:key]; [[NSUserDefaults standardUserDefaults] synchronize]; }
#define user_defaults_set_array(key, a)  { [[NSUserDefaults standardUserDefaults] setObject:a  forKey:key]; [[NSUserDefaults standardUserDefaults] synchronize]; }
#define user_defaults_set_object(key, o) { [[NSUserDefaults standardUserDefaults] setObject:o  forKey:key]; [[NSUserDefaults standardUserDefaults] synchronize]; }

#define APP_DISPLAY_NAME    [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"]
#define APP_VERSION     	[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]
#define APP_BUILD_NUMBER    [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"]

inline __attribute__((always_inline)) NSString *fc_safeString(NSString *str)
{
    return str && [str isKindOfClass:NSString.class] ? str : @"";
}

inline __attribute__((always_inline)) NSString *fc_safeStringCopy(NSString *str)
{
    return str && [str isKindOfClass:NSString.class] ? [NSString stringWithFormat:@"%@", str] : @"";
}

inline __attribute__((always_inline)) NSString *fc_dictionaryValueToString(NSObject *cfObj)
{
    if ([cfObj isKindOfClass:[NSString class]]) return (NSString *)cfObj;
    else return [(NSNumber *)cfObj stringValue];
}

// If we're currently on the main thread, run block() sync, otherwise dispatch block() async to main thread.
void fc_executeOnMainThread(void (^block)(void));

inline __attribute((always_inline)) uint64_t fc_random_int64(void)
{
    uint64_t urandom;
    if (0 != SecRandomCopyBytes(kSecRandomDefault, sizeof(uint64_t), (uint8_t *) (&urandom))) {
        arc4random_stir();
        urandom = ( ((uint64_t) arc4random()) << 32) | (uint64_t) arc4random();
    }
    return urandom;
}

inline __attribute((always_inline)) uint32_t fc_random_int32(void)
{
    uint32_t urandom;
    if (0 != SecRandomCopyBytes(kSecRandomDefault, sizeof(uint32_t), (uint8_t *) (&urandom))) {
        arc4random_stir();
        urandom = (uint32_t) arc4random();
    }
    return urandom;
}

inline __attribute__((always_inline)) CGRect fc_safeCGRectInset(CGRect rect, CGFloat dx, CGFloat dy)
{
    CGFloat dx2 = 2.0f * dx, dy2 = 2.0f * dy;
    if (rect.size.width < dx2) {
        rect.origin.x = rect.size.width / 2.0f;
        rect.size.width = 0;
    } else {
        rect.origin.x += dx;
        rect.size.width -= dx2;
    }
    
    if (rect.size.height < dy2) {
        rect.origin.y = rect.size.height / 2.0f;
        rect.size.height = 0;
    } else {
        rect.origin.y += dy;
        rect.size.height -= dy2;
    }
    
    return rect;
}

inline __attribute__((always_inline)) CGRect fc_aspectFitRect(CGRect outerRect, CGSize innerSize) {

    // the width and height ratios of the rects
    CGFloat wRatio = outerRect.size.width/innerSize.width;
    CGFloat hRatio = outerRect.size.height/innerSize.height;

    // calculate scaling ratio based on the smallest ratio.
    CGFloat ratio = (wRatio < hRatio)? wRatio:hRatio;

    // The x-offset of the inner rect as it gets centered
    CGFloat xOffset = (outerRect.size.width-(innerSize.width*ratio))*0.5;

    // The y-offset of the inner rect as it gets centered
    CGFloat yOffset = (outerRect.size.height-(innerSize.height*ratio))*0.5;

    // aspect fitted origin and size
    CGPoint innerRectOrigin = {xOffset+outerRect.origin.x, yOffset+outerRect.origin.y};
    innerSize = (CGSize) {innerSize.width*ratio, innerSize.height*ratio};

    return (CGRect){innerRectOrigin, innerSize};
}

