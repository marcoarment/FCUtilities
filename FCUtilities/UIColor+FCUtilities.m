//
//  UIColor+FCUtilities.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "UIColor+FCUtilities.h"
#import <objc/runtime.h>

static void *UIColorFCUtilitiesIdentifierKey = &UIColorFCUtilitiesIdentifierKey;

@implementation UIColor (FCUtilities)

- (UIColor * _Nonnull)fc_withSystemName:(NSString * _Nullable)string
{
    objc_setAssociatedObject(self, UIColorFCUtilitiesIdentifierKey, string, OBJC_ASSOCIATION_COPY);
    return self;
}

- (NSString * _Nullable)fc_colorIdentifier
{
    NSMutableDictionary<NSNumber *, UIColor *> *colorsToRepresentAsRGBA = [NSMutableDictionary dictionary];

    NSString *systemName = (NSString *) objc_getAssociatedObject(self, UIColorFCUtilitiesIdentifierKey);
    if (systemName) {
        NSArray<NSNumber *> *validThemeValues = @[
            @(FCUserInterfaceStyleLight),
            @(FCUserInterfaceStyleDark),
        ];
        
        for (NSNumber *themeNum in validThemeValues) {
            UIColor *c = [self.class fc_systemColorWithName:systemName theme:themeNum.integerValue];
            if (c) colorsToRepresentAsRGBA[themeNum] = c;
        }
    }
    if (! colorsToRepresentAsRGBA.count) colorsToRepresentAsRGBA[@(FCUserInterfaceStyleLight)] = self;

    __block BOOL hasAnyComponents = NO;
    NSMutableString *idStr = (systemName ?: @"").mutableCopy;
    [colorsToRepresentAsRGBA enumerateKeysAndObjectsUsingBlock:^(NSNumber *themeNum, UIColor *color, BOOL *stop) {
        CGFloat r, g, b, a;
        if (! [color fc_getRed:&r green:&g blue:&b alpha:&a]) return;
        hasAnyComponents = YES;
        [idStr appendFormat:@"#%d:%g,%g,%g,%g", themeNum.intValue, r, g, b, a];
    }];

    return hasAnyComponents ? idStr : nil;
}

+ (UIColor * _Nullable)fc_colorFromIdentifier:(NSString * _Nullable)string theme:(FCUserInterfaceStyle)theme
{
    if (! string) return nil;
    
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@",:"];
    NSString *systemName = NULL;

    if ([scanner scanCharactersFromSet:NSCharacterSet.alphanumericCharacterSet intoString:&systemName] && systemName.length > 0) {
        UIColor *systemColor = [self fc_systemColorWithName:systemName theme:theme];
        if (systemColor) return systemColor;
    }
    
    // If it's not a recognized system color, fall back to RGBA values
    NSMutableDictionary<NSNumber *, UIColor *> *colorsByTheme = [NSMutableDictionary dictionary];
    while ([scanner scanString:@"#" intoString:NULL]) {
        NSInteger themeID;
        float r = 0, g = 0, b = 0, a = 0;
        if ([scanner scanInteger:&themeID] && [scanner scanFloat:&r] && [scanner scanFloat:&g] && [scanner scanFloat:&b] && [scanner scanFloat:&a]) {
            colorsByTheme[@(themeID)] = [UIColor colorWithRed:r green:g blue:b alpha:a];
        }
    }
    
    UIColor *colorInTheme = colorsByTheme[@(theme)];
    if (! colorInTheme) colorInTheme = colorsByTheme[@(FCUserInterfaceStyleLight)]; // Fall back to light if color exact theme isn't present
    if (! colorInTheme) colorInTheme = colorsByTheme.allValues.firstObject; // If exact theme AND light theme aren't set, fall back to any theme present
    return colorInTheme ? [colorInTheme fc_withSystemName:systemName] : nil;
}

- (BOOL)fc_getRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha {
    if ([self getRed:red green:green blue:blue alpha:alpha]) return YES;
    if ([self getWhite:red alpha:alpha]) {
        if (green) *green = *red;
        if (blue) *blue = *red;
        return YES;
    }
    return NO;
}

- (UIColor *)fc_colorByModifyingRGBA:(void (^)(CGFloat *red, CGFloat *green, CGFloat *blue, CGFloat *alpha))modifyingBlock
{
    CGFloat red, green, blue, alpha;
    
    if (! [self fc_getRed:&red green:&green blue:&blue alpha:&alpha]) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Color is not in a decomposable format" userInfo:nil] raise];
    }

    modifyingBlock(&red, &green, &blue, &alpha);
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (UIColor *)fc_colorByModifyingHSBA:(void (^)(CGFloat *hue, CGFloat *saturation, CGFloat *brightness, CGFloat *alpha))modifyingBlock
{
    CGFloat hue, saturation, brightness, alpha;
    
    if (! [self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        if ([self getWhite:&brightness alpha:&alpha]) {
            hue = 0;
            saturation = 0;
        } else {
            [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Color is not in a decomposable format" userInfo:nil] raise];
        }
    }

    modifyingBlock(&hue, &saturation, &brightness, &alpha);
    hue = MAX(0.0f, MIN(1.0f, hue));
    saturation = MAX(0.0f, MIN(1.0f, saturation));
    brightness = MAX(0.0f, MIN(1.0f, brightness));
    alpha = MAX(0.0f, MIN(1.0f, alpha));
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
}

- (CGFloat)fc_apcaLuminance /* "Y" from https://github.com/Myndex/SAPC-APCA/ and https://www.w3.org/WAI/GL/task-forces/silver/wiki/Visual_Contrast_of_Text_Subgroup/APCA_model */
{
    CGFloat r, g, b, a;
    [self fc_getRed:&r green:&g blue:&b alpha:&a];
    return powf(r / 1.0f, 2.4f) * 0.2126729f + powf(g / 1.0f, 2.4f) * 0.7151522f + powf(b / 1.0f, 2.4f) * 0.0721750f;
}

- (CGFloat)fc_apcaContrastAgainstBackgroundColor:(UIColor *)backgroundColor
{
    UIColor *textColor = [self fc_opaqueColorByBlendingWithBackgroundColor:backgroundColor];
    CGFloat textY = textColor.fc_apcaLuminance;
    CGFloat backgroundY = backgroundColor.fc_apcaLuminance;

    // adapted from https://github.com/Myndex/SAPC-APCA/blob/master/src/JS/SAPC_0_98G_4g_minimal.js

    const CGFloat clampThreshold = 0.22f;
    if (textY <= clampThreshold)       { textY += powf(clampThreshold - textY,       1.414f); }
    if (backgroundY <= clampThreshold) { textY += powf(clampThreshold - backgroundY, 1.414f); }

    if (ABS(backgroundY - textY) < 0.0005f) return 0;
    
    CGFloat sapc = backgroundY > textY ? powf(backgroundY, 0.56f) - powf(textY, 0.57f) : powf(backgroundY, 0.65f) - powf(textY, 0.62f);

    if (sapc < 0.001f)    return 0;
    if (sapc < 0.035991f) return sapc - sapc * 27.7847239587675f * 0.027f;
    return sapc - 0.027f;
}

- (UIColor * _Nonnull)fc_colorWithMinimumAPCAContrast:(CGFloat)minContrast againstBackgroundColor:(UIColor *)backgroundColor changed:(out BOOL *)outColorDidChange
{
    if (outColorDidChange) *outColorDidChange = NO;
    BOOL adjustmentDirectionDarken = (backgroundColor.fc_apcaLuminance > self.fc_apcaLuminance);
    UIColor *color = self;
    CGFloat lastContrast = 0.0f;
    CGFloat contrast;
    while ( (contrast = [color fc_apcaContrastAgainstBackgroundColor:backgroundColor]) < minContrast) {
        if (contrast == lastContrast) { /* not improving anymore; bail out */ return color; }
        color = [color fc_colorByModifyingHSBA:^(CGFloat * _Nonnull hue, CGFloat * _Nonnull saturation, CGFloat * _Nonnull brightness, CGFloat * _Nonnull alpha) {
            if (adjustmentDirectionDarken) {
                *brightness *= 0.975f;
                *saturation *= 1.1f;
            } else {
                *brightness *= 1.05f;
                *saturation *= 0.9f;
            }
        }];
        if (outColorDidChange) *outColorDidChange = YES;
        lastContrast = contrast;
    }
    return color;
}

- (NSString *)fc_CSSColor
{
    CGFloat r, g, b, a;
    if ([self fc_getRed:&r green:&g blue:&b alpha:&a]) {
        return [NSString stringWithFormat:@"rgba(%d, %d, %d, %g)", (int) (r * 255.0f), (int) (g * 255.0f), (int) (b * 255.0f), a];
    } else {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"Cannot convert this color space to CSS color" userInfo:nil] raise];
        return nil;
    }
}

+ (UIColor *)fc_colorWithHexString:(NSString *)hexString
{
	unsigned hexNum;
	if (! [[NSScanner scannerWithString:hexString] scanHexInt:&hexNum]) return nil;
	return fc_UIColorFromHexInt(hexNum);
}

- (UIColor *)fc_opaqueColorByBlendingWithBackgroundColor:(UIColor *)backgroundColor
{
    return [backgroundColor fc_colorByBlendingWithColor:self];
}

// adaptation of https://stackoverflow.com/a/18903483/30480
- (UIColor *)fc_colorByBlendingWithColor:(UIColor *)color2
{
    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;

    if (! [self fc_getRed:&r1 green:&g1 blue:&b1 alpha:&a1]) return nil;
    if (! [color2 fc_getRed:&r2 green:&g2 blue:&b2 alpha:&a2]) return nil;

    CGFloat beta = 1.0f - a2;
    
    CGFloat r = r1 * beta + r2 * a2;
    CGFloat g = g1 * beta + g2 * a2;
    CGFloat b = b1 * beta + b2 * a2;
    //CGFloat a = a1 * beta + a2 * a2;
    return [UIColor colorWithRed:r green:g blue:b alpha:a1];
}

#ifdef SUPPORT_DUMPING_COLOR_VALUES
#if TARGET_OS_IOS
+ (void)fc_dumpSystemColorValues
{
    NSMutableString *hFile = @"+ (UIColor * _Nullable)fc_systemColorWithName:(NSString * _Nonnull)name theme:(FCUserInterfaceStyle)theme;\n".mutableCopy;
    NSMutableString *cFile = @"".mutableCopy;

    NSMutableArray *systemColorMethodNames = [NSMutableArray array];
    int unsigned numMethods;
    Method *methods = class_copyMethodList(objc_getMetaClass("UIColor"), &numMethods);
    for (int i = 0; i < numMethods; i++) {
        NSString *methodName = NSStringFromSelector(method_getName(methods[i]));
        if (
            ! [methodName hasPrefix:@"_"] &&
            ! [methodName hasPrefix:@"fc_"] &&
            [methodName hasSuffix:@"Color"] &&
            (
                [methodName hasPrefix:@"system"] || [methodName containsString:@"System"] ||
                [methodName hasPrefix:@"label"] || [methodName containsString:@"Label"] ||
                [methodName isEqualToString:@"separatorColor"] || [methodName isEqualToString:@"opaqueSeparatorColor"] ||
                [methodName isEqualToString:@"linkColor"] || [methodName isEqualToString:@"placeholderTextColor"]
            ) &&
            ! [methodName hasPrefix:@"external"] && ! [methodName hasPrefix:@"mail"] && // private APIs
            ! [methodName containsString:@"Tint"] && // private APIs
            ! [methodName containsString:@"systemLight"] && ! [methodName containsString:@"systemDark"] && // private APIs
            ! [methodName containsString:@"systemWhite"] && ! [methodName containsString:@"systemBlack"] &&
            ! [methodName containsString:@"systemMid"] && ! [methodName containsString:@"systemExtraLightGray"] // private APIs
        ) {
            [systemColorMethodNames addObject:methodName];
        }
    }
    free(methods);
    
    NSMutableString *byNameMethodBody = @"".mutableCopy;

    for (NSString *name in systemColorMethodNames) {
        UIColor *color = [UIColor performSelector:NSSelectorFromString(name)];
        if (! [color isKindOfClass:UIColor.class]) continue;

        [hFile appendFormat:@"+ (UIColor * _Nonnull)fc_%@WithTheme:(FCUserInterfaceStyle)theme;\n", name];

        CGFloat darkR, darkG, darkB, darkA, lightR, lightG, lightB, lightA;
        UIColor *darkColor = [color resolvedColorWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]];
        UIColor *lightColor = [color resolvedColorWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
        if (! [darkColor fc_getRed:&darkR green:&darkG blue:&darkB alpha:&darkA] || ! [lightColor fc_getRed:&lightR green:&lightG blue:&lightB alpha:&lightA]) continue;

        [cFile appendFormat:@"+ (UIColor * _Nonnull)fc_%@WithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:%0.6ff green:%0.6ff blue:%0.6ff alpha:%0.6ff] : [UIColor colorWithRed:%0.6ff green:%0.6ff blue:%0.6ff alpha:%0.6ff]) fc_withSystemName:@\"%@\"]; }\n", name, darkR, darkG, darkB, darkA, lightR, lightG, lightB, lightA, name];
        
        [byNameMethodBody appendFormat:@"    if ([name isEqualToString:@\"%@\"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:%0.6ff green:%0.6ff blue:%0.6ff alpha:%0.6ff] : [UIColor colorWithRed:%0.6ff green:%0.6ff blue:%0.6ff alpha:%0.6ff]) fc_withSystemName:@\"%@\"]; }\n", name, darkR, darkG, darkB, darkA, lightR, lightG, lightB, lightA, name];
    }
    
    [cFile appendFormat:@"\n+ (UIColor * _Nullable)fc_systemColorWithName:(NSString * _Nonnull)name theme:(FCUserInterfaceStyle)theme {\n%@\n    return nil;\n}\n", byNameMethodBody];
    
    NSError *error = NULL;
    [hFile writeToFile:@"/tmp/UIColor+FCUtilities+SystemColors.h" atomically:NO encoding:NSUTF8StringEncoding error:&error];
    if (error) [[NSException exceptionWithName:@"ColorDumpFailed" reason:error.localizedDescription userInfo:nil] raise];

    [cFile writeToFile:@"/tmp/UIColor+FCUtilities+SystemColors.c" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
    if (error) [[NSException exceptionWithName:@"ColorDumpFailed" reason:error.localizedDescription userInfo:nil] raise];
}
#endif
#endif

// Generated by SUPPORT_DUMPING_COLOR_VALUES
+ (UIColor * _Nonnull)fc_systemRedColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:1.000000f green:0.270588f blue:0.227451f alpha:1.000000f] : [UIColor colorWithRed:1.000000f green:0.231373f blue:0.188235f alpha:1.000000f]) fc_withSystemName:@"systemRedColor"]; }
+ (UIColor * _Nonnull)fc_systemGreenColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.188235f green:0.819608f blue:0.345098f alpha:1.000000f] : [UIColor colorWithRed:0.203922f green:0.780392f blue:0.349020f alpha:1.000000f]) fc_withSystemName:@"systemGreenColor"]; }
+ (UIColor * _Nonnull)fc_systemBlueColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.039216f green:0.517647f blue:1.000000f alpha:1.000000f] : [UIColor colorWithRed:0.000000f green:0.478431f blue:1.000000f alpha:1.000000f]) fc_withSystemName:@"systemBlueColor"]; }
+ (UIColor * _Nonnull)fc_labelColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:1.000000f green:1.000000f blue:1.000000f alpha:1.000000f] : [UIColor colorWithRed:0.000000f green:0.000000f blue:0.000000f alpha:1.000000f]) fc_withSystemName:@"labelColor"]; }
+ (UIColor * _Nonnull)fc_systemGrayColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.556863f green:0.556863f blue:0.576471f alpha:1.000000f] : [UIColor colorWithRed:0.556863f green:0.556863f blue:0.576471f alpha:1.000000f]) fc_withSystemName:@"systemGrayColor"]; }
+ (UIColor * _Nonnull)fc_systemBackgroundColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.000000f green:0.000000f blue:0.000000f alpha:1.000000f] : [UIColor colorWithRed:1.000000f green:1.000000f blue:1.000000f alpha:1.000000f]) fc_withSystemName:@"systemBackgroundColor"]; }
+ (UIColor * _Nonnull)fc_secondarySystemGroupedBackgroundColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.109804f green:0.109804f blue:0.117647f alpha:1.000000f] : [UIColor colorWithRed:1.000000f green:1.000000f blue:1.000000f alpha:1.000000f]) fc_withSystemName:@"secondarySystemGroupedBackgroundColor"]; }
+ (UIColor * _Nonnull)fc_secondaryLabelColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.921569f green:0.921569f blue:0.960784f alpha:0.600000f] : [UIColor colorWithRed:0.235294f green:0.235294f blue:0.262745f alpha:0.600000f]) fc_withSystemName:@"secondaryLabelColor"]; }
+ (UIColor * _Nonnull)fc_separatorColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.329412f green:0.329412f blue:0.345098f alpha:0.600000f] : [UIColor colorWithRed:0.235294f green:0.235294f blue:0.262745f alpha:0.290000f]) fc_withSystemName:@"separatorColor"]; }
+ (UIColor * _Nonnull)fc_linkColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.035294f green:0.517647f blue:1.000000f alpha:1.000000f] : [UIColor colorWithRed:0.000000f green:0.478431f blue:1.000000f alpha:1.000000f]) fc_withSystemName:@"linkColor"]; }
+ (UIColor * _Nonnull)fc_tertiarySystemFillColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.462745f green:0.462745f blue:0.501961f alpha:0.240000f] : [UIColor colorWithRed:0.462745f green:0.462745f blue:0.501961f alpha:0.120000f]) fc_withSystemName:@"tertiarySystemFillColor"]; }
+ (UIColor * _Nonnull)fc_systemFillColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.470588f green:0.470588f blue:0.501961f alpha:0.360000f] : [UIColor colorWithRed:0.470588f green:0.470588f blue:0.501961f alpha:0.200000f]) fc_withSystemName:@"systemFillColor"]; }
+ (UIColor * _Nonnull)fc_secondarySystemFillColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.470588f green:0.470588f blue:0.501961f alpha:0.320000f] : [UIColor colorWithRed:0.470588f green:0.470588f blue:0.501961f alpha:0.160000f]) fc_withSystemName:@"secondarySystemFillColor"]; }
+ (UIColor * _Nonnull)fc_secondarySystemBackgroundColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.109804f green:0.109804f blue:0.117647f alpha:1.000000f] : [UIColor colorWithRed:0.949020f green:0.949020f blue:0.968627f alpha:1.000000f]) fc_withSystemName:@"secondarySystemBackgroundColor"]; }
+ (UIColor * _Nonnull)fc_tertiarySystemBackgroundColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.172549f green:0.172549f blue:0.180392f alpha:1.000000f] : [UIColor colorWithRed:1.000000f green:1.000000f blue:1.000000f alpha:1.000000f]) fc_withSystemName:@"tertiarySystemBackgroundColor"]; }
+ (UIColor * _Nonnull)fc_systemGroupedBackgroundColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.000000f green:0.000000f blue:0.000000f alpha:1.000000f] : [UIColor colorWithRed:0.949020f green:0.949020f blue:0.968627f alpha:1.000000f]) fc_withSystemName:@"systemGroupedBackgroundColor"]; }
+ (UIColor * _Nonnull)fc_tertiarySystemGroupedBackgroundColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.172549f green:0.172549f blue:0.180392f alpha:1.000000f] : [UIColor colorWithRed:0.949020f green:0.949020f blue:0.968627f alpha:1.000000f]) fc_withSystemName:@"tertiarySystemGroupedBackgroundColor"]; }
+ (UIColor * _Nonnull)fc_systemOrangeColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:1.000000f green:0.623529f blue:0.039216f alpha:1.000000f] : [UIColor colorWithRed:1.000000f green:0.584314f blue:0.000000f alpha:1.000000f]) fc_withSystemName:@"systemOrangeColor"]; }
+ (UIColor * _Nonnull)fc_tertiaryLabelColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.921569f green:0.921569f blue:0.960784f alpha:0.300000f] : [UIColor colorWithRed:0.235294f green:0.235294f blue:0.262745f alpha:0.300000f]) fc_withSystemName:@"tertiaryLabelColor"]; }
+ (UIColor * _Nonnull)fc_systemYellowColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:1.000000f green:0.839216f blue:0.039216f alpha:1.000000f] : [UIColor colorWithRed:1.000000f green:0.800000f blue:0.000000f alpha:1.000000f]) fc_withSystemName:@"systemYellowColor"]; }
+ (UIColor * _Nonnull)fc_systemPinkColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:1.000000f green:0.215686f blue:0.372549f alpha:1.000000f] : [UIColor colorWithRed:1.000000f green:0.176471f blue:0.333333f alpha:1.000000f]) fc_withSystemName:@"systemPinkColor"]; }
+ (UIColor * _Nonnull)fc_systemMintColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.388235f green:0.901961f blue:0.886275f alpha:1.000000f] : [UIColor colorWithRed:0.000000f green:0.780392f blue:0.745098f alpha:1.000000f]) fc_withSystemName:@"systemMintColor"]; }
+ (UIColor * _Nonnull)fc_systemCyanColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.392157f green:0.823529f blue:1.000000f alpha:1.000000f] : [UIColor colorWithRed:0.196078f green:0.678431f blue:0.901961f alpha:1.000000f]) fc_withSystemName:@"systemCyanColor"]; }
+ (UIColor * _Nonnull)fc_systemTealColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.250980f green:0.784314f blue:0.878431f alpha:1.000000f] : [UIColor colorWithRed:0.188235f green:0.690196f blue:0.780392f alpha:1.000000f]) fc_withSystemName:@"systemTealColor"]; }
+ (UIColor * _Nonnull)fc_systemPurpleColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.749020f green:0.352941f blue:0.949020f alpha:1.000000f] : [UIColor colorWithRed:0.686275f green:0.321569f blue:0.870588f alpha:1.000000f]) fc_withSystemName:@"systemPurpleColor"]; }
+ (UIColor * _Nonnull)fc_systemIndigoColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.368627f green:0.360784f blue:0.901961f alpha:1.000000f] : [UIColor colorWithRed:0.345098f green:0.337255f blue:0.839216f alpha:1.000000f]) fc_withSystemName:@"systemIndigoColor"]; }
+ (UIColor * _Nonnull)fc_systemBrownColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.674510f green:0.556863f blue:0.407843f alpha:1.000000f] : [UIColor colorWithRed:0.635294f green:0.517647f blue:0.368627f alpha:1.000000f]) fc_withSystemName:@"systemBrownColor"]; }
+ (UIColor * _Nonnull)fc_quaternaryLabelColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.921569f green:0.921569f blue:0.960784f alpha:0.160000f] : [UIColor colorWithRed:0.235294f green:0.235294f blue:0.262745f alpha:0.180000f]) fc_withSystemName:@"quaternaryLabelColor"]; }
+ (UIColor * _Nonnull)fc_placeholderTextColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.921569f green:0.921569f blue:0.960784f alpha:0.300000f] : [UIColor colorWithRed:0.235294f green:0.235294f blue:0.262745f alpha:0.300000f]) fc_withSystemName:@"placeholderTextColor"]; }
+ (UIColor * _Nonnull)fc_opaqueSeparatorColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.219608f green:0.219608f blue:0.227451f alpha:1.000000f] : [UIColor colorWithRed:0.776471f green:0.776471f blue:0.784314f alpha:1.000000f]) fc_withSystemName:@"opaqueSeparatorColor"]; }
+ (UIColor * _Nonnull)fc_quaternarySystemFillColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.462745f green:0.462745f blue:0.501961f alpha:0.180000f] : [UIColor colorWithRed:0.454902f green:0.454902f blue:0.501961f alpha:0.080000f]) fc_withSystemName:@"quaternarySystemFillColor"]; }
+ (UIColor * _Nonnull)fc_systemGray2ColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.388235f green:0.388235f blue:0.400000f alpha:1.000000f] : [UIColor colorWithRed:0.682353f green:0.682353f blue:0.698039f alpha:1.000000f]) fc_withSystemName:@"systemGray2Color"]; }
+ (UIColor * _Nonnull)fc_systemGray3ColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.282353f green:0.282353f blue:0.290196f alpha:1.000000f] : [UIColor colorWithRed:0.780392f green:0.780392f blue:0.800000f alpha:1.000000f]) fc_withSystemName:@"systemGray3Color"]; }
+ (UIColor * _Nonnull)fc_systemGray4ColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.227451f green:0.227451f blue:0.235294f alpha:1.000000f] : [UIColor colorWithRed:0.819608f green:0.819608f blue:0.839216f alpha:1.000000f]) fc_withSystemName:@"systemGray4Color"]; }
+ (UIColor * _Nonnull)fc_systemGray5ColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.172549f green:0.172549f blue:0.180392f alpha:1.000000f] : [UIColor colorWithRed:0.898039f green:0.898039f blue:0.917647f alpha:1.000000f]) fc_withSystemName:@"systemGray5Color"]; }
+ (UIColor * _Nonnull)fc_systemGray6ColorWithTheme:(FCUserInterfaceStyle)theme { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.109804f green:0.109804f blue:0.117647f alpha:1.000000f] : [UIColor colorWithRed:0.949020f green:0.949020f blue:0.968627f alpha:1.000000f]) fc_withSystemName:@"systemGray6Color"]; }

+ (UIColor * _Nullable)fc_systemColorWithName:(NSString * _Nonnull)name theme:(FCUserInterfaceStyle)theme {
    if ([name isEqualToString:@"systemRedColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:1.000000f green:0.270588f blue:0.227451f alpha:1.000000f] : [UIColor colorWithRed:1.000000f green:0.231373f blue:0.188235f alpha:1.000000f]) fc_withSystemName:@"systemRedColor"]; }
    if ([name isEqualToString:@"systemGreenColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.188235f green:0.819608f blue:0.345098f alpha:1.000000f] : [UIColor colorWithRed:0.203922f green:0.780392f blue:0.349020f alpha:1.000000f]) fc_withSystemName:@"systemGreenColor"]; }
    if ([name isEqualToString:@"systemBlueColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.039216f green:0.517647f blue:1.000000f alpha:1.000000f] : [UIColor colorWithRed:0.000000f green:0.478431f blue:1.000000f alpha:1.000000f]) fc_withSystemName:@"systemBlueColor"]; }
    if ([name isEqualToString:@"labelColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:1.000000f green:1.000000f blue:1.000000f alpha:1.000000f] : [UIColor colorWithRed:0.000000f green:0.000000f blue:0.000000f alpha:1.000000f]) fc_withSystemName:@"labelColor"]; }
    if ([name isEqualToString:@"systemGrayColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.556863f green:0.556863f blue:0.576471f alpha:1.000000f] : [UIColor colorWithRed:0.556863f green:0.556863f blue:0.576471f alpha:1.000000f]) fc_withSystemName:@"systemGrayColor"]; }
    if ([name isEqualToString:@"systemBackgroundColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.000000f green:0.000000f blue:0.000000f alpha:1.000000f] : [UIColor colorWithRed:1.000000f green:1.000000f blue:1.000000f alpha:1.000000f]) fc_withSystemName:@"systemBackgroundColor"]; }
    if ([name isEqualToString:@"secondarySystemGroupedBackgroundColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.109804f green:0.109804f blue:0.117647f alpha:1.000000f] : [UIColor colorWithRed:1.000000f green:1.000000f blue:1.000000f alpha:1.000000f]) fc_withSystemName:@"secondarySystemGroupedBackgroundColor"]; }
    if ([name isEqualToString:@"secondaryLabelColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.921569f green:0.921569f blue:0.960784f alpha:0.600000f] : [UIColor colorWithRed:0.235294f green:0.235294f blue:0.262745f alpha:0.600000f]) fc_withSystemName:@"secondaryLabelColor"]; }
    if ([name isEqualToString:@"separatorColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.329412f green:0.329412f blue:0.345098f alpha:0.600000f] : [UIColor colorWithRed:0.235294f green:0.235294f blue:0.262745f alpha:0.290000f]) fc_withSystemName:@"separatorColor"]; }
    if ([name isEqualToString:@"linkColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.035294f green:0.517647f blue:1.000000f alpha:1.000000f] : [UIColor colorWithRed:0.000000f green:0.478431f blue:1.000000f alpha:1.000000f]) fc_withSystemName:@"linkColor"]; }
    if ([name isEqualToString:@"tertiarySystemFillColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.462745f green:0.462745f blue:0.501961f alpha:0.240000f] : [UIColor colorWithRed:0.462745f green:0.462745f blue:0.501961f alpha:0.120000f]) fc_withSystemName:@"tertiarySystemFillColor"]; }
    if ([name isEqualToString:@"systemFillColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.470588f green:0.470588f blue:0.501961f alpha:0.360000f] : [UIColor colorWithRed:0.470588f green:0.470588f blue:0.501961f alpha:0.200000f]) fc_withSystemName:@"systemFillColor"]; }
    if ([name isEqualToString:@"secondarySystemFillColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.470588f green:0.470588f blue:0.501961f alpha:0.320000f] : [UIColor colorWithRed:0.470588f green:0.470588f blue:0.501961f alpha:0.160000f]) fc_withSystemName:@"secondarySystemFillColor"]; }
    if ([name isEqualToString:@"secondarySystemBackgroundColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.109804f green:0.109804f blue:0.117647f alpha:1.000000f] : [UIColor colorWithRed:0.949020f green:0.949020f blue:0.968627f alpha:1.000000f]) fc_withSystemName:@"secondarySystemBackgroundColor"]; }
    if ([name isEqualToString:@"tertiarySystemBackgroundColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.172549f green:0.172549f blue:0.180392f alpha:1.000000f] : [UIColor colorWithRed:1.000000f green:1.000000f blue:1.000000f alpha:1.000000f]) fc_withSystemName:@"tertiarySystemBackgroundColor"]; }
    if ([name isEqualToString:@"systemGroupedBackgroundColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.000000f green:0.000000f blue:0.000000f alpha:1.000000f] : [UIColor colorWithRed:0.949020f green:0.949020f blue:0.968627f alpha:1.000000f]) fc_withSystemName:@"systemGroupedBackgroundColor"]; }
    if ([name isEqualToString:@"tertiarySystemGroupedBackgroundColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.172549f green:0.172549f blue:0.180392f alpha:1.000000f] : [UIColor colorWithRed:0.949020f green:0.949020f blue:0.968627f alpha:1.000000f]) fc_withSystemName:@"tertiarySystemGroupedBackgroundColor"]; }
    if ([name isEqualToString:@"systemOrangeColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:1.000000f green:0.623529f blue:0.039216f alpha:1.000000f] : [UIColor colorWithRed:1.000000f green:0.584314f blue:0.000000f alpha:1.000000f]) fc_withSystemName:@"systemOrangeColor"]; }
    if ([name isEqualToString:@"tertiaryLabelColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.921569f green:0.921569f blue:0.960784f alpha:0.300000f] : [UIColor colorWithRed:0.235294f green:0.235294f blue:0.262745f alpha:0.300000f]) fc_withSystemName:@"tertiaryLabelColor"]; }
    if ([name isEqualToString:@"systemYellowColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:1.000000f green:0.839216f blue:0.039216f alpha:1.000000f] : [UIColor colorWithRed:1.000000f green:0.800000f blue:0.000000f alpha:1.000000f]) fc_withSystemName:@"systemYellowColor"]; }
    if ([name isEqualToString:@"systemPinkColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:1.000000f green:0.215686f blue:0.372549f alpha:1.000000f] : [UIColor colorWithRed:1.000000f green:0.176471f blue:0.333333f alpha:1.000000f]) fc_withSystemName:@"systemPinkColor"]; }
    if ([name isEqualToString:@"systemMintColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.388235f green:0.901961f blue:0.886275f alpha:1.000000f] : [UIColor colorWithRed:0.000000f green:0.780392f blue:0.745098f alpha:1.000000f]) fc_withSystemName:@"systemMintColor"]; }
    if ([name isEqualToString:@"systemCyanColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.392157f green:0.823529f blue:1.000000f alpha:1.000000f] : [UIColor colorWithRed:0.196078f green:0.678431f blue:0.901961f alpha:1.000000f]) fc_withSystemName:@"systemCyanColor"]; }
    if ([name isEqualToString:@"systemTealColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.250980f green:0.784314f blue:0.878431f alpha:1.000000f] : [UIColor colorWithRed:0.188235f green:0.690196f blue:0.780392f alpha:1.000000f]) fc_withSystemName:@"systemTealColor"]; }
    if ([name isEqualToString:@"systemPurpleColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.749020f green:0.352941f blue:0.949020f alpha:1.000000f] : [UIColor colorWithRed:0.686275f green:0.321569f blue:0.870588f alpha:1.000000f]) fc_withSystemName:@"systemPurpleColor"]; }
    if ([name isEqualToString:@"systemIndigoColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.368627f green:0.360784f blue:0.901961f alpha:1.000000f] : [UIColor colorWithRed:0.345098f green:0.337255f blue:0.839216f alpha:1.000000f]) fc_withSystemName:@"systemIndigoColor"]; }
    if ([name isEqualToString:@"systemBrownColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.674510f green:0.556863f blue:0.407843f alpha:1.000000f] : [UIColor colorWithRed:0.635294f green:0.517647f blue:0.368627f alpha:1.000000f]) fc_withSystemName:@"systemBrownColor"]; }
    if ([name isEqualToString:@"quaternaryLabelColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.921569f green:0.921569f blue:0.960784f alpha:0.160000f] : [UIColor colorWithRed:0.235294f green:0.235294f blue:0.262745f alpha:0.180000f]) fc_withSystemName:@"quaternaryLabelColor"]; }
    if ([name isEqualToString:@"placeholderTextColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.921569f green:0.921569f blue:0.960784f alpha:0.300000f] : [UIColor colorWithRed:0.235294f green:0.235294f blue:0.262745f alpha:0.300000f]) fc_withSystemName:@"placeholderTextColor"]; }
    if ([name isEqualToString:@"opaqueSeparatorColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.219608f green:0.219608f blue:0.227451f alpha:1.000000f] : [UIColor colorWithRed:0.776471f green:0.776471f blue:0.784314f alpha:1.000000f]) fc_withSystemName:@"opaqueSeparatorColor"]; }
    if ([name isEqualToString:@"quaternarySystemFillColor"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.462745f green:0.462745f blue:0.501961f alpha:0.180000f] : [UIColor colorWithRed:0.454902f green:0.454902f blue:0.501961f alpha:0.080000f]) fc_withSystemName:@"quaternarySystemFillColor"]; }
    if ([name isEqualToString:@"systemGray2Color"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.388235f green:0.388235f blue:0.400000f alpha:1.000000f] : [UIColor colorWithRed:0.682353f green:0.682353f blue:0.698039f alpha:1.000000f]) fc_withSystemName:@"systemGray2Color"]; }
    if ([name isEqualToString:@"systemGray3Color"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.282353f green:0.282353f blue:0.290196f alpha:1.000000f] : [UIColor colorWithRed:0.780392f green:0.780392f blue:0.800000f alpha:1.000000f]) fc_withSystemName:@"systemGray3Color"]; }
    if ([name isEqualToString:@"systemGray4Color"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.227451f green:0.227451f blue:0.235294f alpha:1.000000f] : [UIColor colorWithRed:0.819608f green:0.819608f blue:0.839216f alpha:1.000000f]) fc_withSystemName:@"systemGray4Color"]; }
    if ([name isEqualToString:@"systemGray5Color"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.172549f green:0.172549f blue:0.180392f alpha:1.000000f] : [UIColor colorWithRed:0.898039f green:0.898039f blue:0.917647f alpha:1.000000f]) fc_withSystemName:@"systemGray5Color"]; }
    if ([name isEqualToString:@"systemGray6Color"]) { return [(theme == FCUserInterfaceStyleDark ? [UIColor colorWithRed:0.109804f green:0.109804f blue:0.117647f alpha:1.000000f] : [UIColor colorWithRed:0.949020f green:0.949020f blue:0.968627f alpha:1.000000f]) fc_withSystemName:@"systemGray6Color"]; }

    return nil;
}

@end
