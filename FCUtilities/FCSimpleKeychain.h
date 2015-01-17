//
//  FCSimpleKeychain.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#ifndef FCSimpleKeychain_h
#define FCSimpleKeychain_h


@import Security;

static __inline__ __attribute__((always_inline)) NSString *fc_groupKeychainStringForKey(NSString *key, BOOL *outKeychainError, NSString *accessGroup)
{
    CFDataRef data = nil;
    NSMutableDictionary *params = [@{
        (__bridge id) kSecClass : (__bridge id) kSecClassGenericPassword,
        (__bridge id) kSecAttrService : [[NSBundle.mainBundle.infoDictionary objectForKey:(NSString *)kCFBundleIdentifierKey] stringByAppendingFormat:@".%@", key],
        (__bridge id) kSecReturnData : (__bridge id) kCFBooleanTrue,
    } mutableCopy];
    if (accessGroup) params[(__bridge id) kSecAttrAccessGroup] = accessGroup;

    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef) params, (CFTypeRef *) &data);
    if (err != errSecSuccess && err != errSecItemNotFound) {
        NSLog(@"Keychain error: SecItemCopyMatching failed for key %@: %d", key, (int) err);
        if (outKeychainError) *outKeychainError = YES;
        return nil;
    }
    
    if (outKeychainError) *outKeychainError = NO;
    if (! data) return nil;
    return [[NSString alloc] initWithData:(__bridge_transfer NSData *)data encoding:NSUTF8StringEncoding];
}

static __inline__ __attribute__((always_inline)) BOOL fc_deleteGroupKeychainStringForKey(NSString *key, NSString *accessGroup)
{
    NSMutableDictionary *params = [@{
        (__bridge id) kSecClass : (__bridge id) kSecClassGenericPassword,
        (__bridge id) kSecAttrService : [[NSBundle.mainBundle.infoDictionary objectForKey:(NSString *)kCFBundleIdentifierKey] stringByAppendingFormat:@".%@", key],
    } mutableCopy];
    if (accessGroup) params[(__bridge id) kSecAttrAccessGroup] = accessGroup;
    return errSecSuccess == SecItemDelete((__bridge CFDictionaryRef) params);
}

static __inline__ __attribute__((always_inline)) BOOL fc_setGroupKeychainStringForKeyWithAccessibility(NSString *key, NSString *value, CFTypeRef accessibility, NSString *accessGroup)
{
    if (! value) return fc_deleteGroupKeychainStringForKey(key, accessGroup);

    NSMutableDictionary *query = [@{
        (__bridge id) kSecClass : (__bridge id) kSecClassGenericPassword,
        (__bridge id) kSecAttrService : [[NSBundle.mainBundle.infoDictionary objectForKey:(NSString *)kCFBundleIdentifierKey] stringByAppendingFormat:@".%@", key],
        (__bridge id) kSecAttrAccessible : (__bridge id) accessibility,
        (__bridge id) kSecValueData : [value dataUsingEncoding:NSUTF8StringEncoding]
    } mutableCopy];
    if (accessGroup) query[(__bridge id) kSecAttrAccessGroup] = accessGroup;

    OSStatus err = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
    if (err == errSecDuplicateItem && fc_deleteGroupKeychainStringForKey(key, accessGroup)) err = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
    if (err != errSecSuccess) NSLog(@"Keychain error: SecItemAdd failed for key %@: %d", key, (int) err);
    return err == errSecSuccess;
}

static __inline__ __attribute__((always_inline)) BOOL fc_setGroupKeychainStringForKey(NSString *key, NSString *value, NSString *accessGroup)
{
    return fc_setGroupKeychainStringForKeyWithAccessibility(key, value, kSecAttrAccessibleAlways, accessGroup);
}

static __inline__ __attribute__((always_inline)) NSString *fc_keychainStringForKey(NSString *key, BOOL *outKeychainError)
{
    return fc_groupKeychainStringForKey(key, outKeychainError, nil);
}

static __inline__ __attribute__((always_inline)) BOOL fc_deleteKeychainStringForKey(NSString *key)
{
    return fc_deleteGroupKeychainStringForKey(key, nil);
}

static __inline__ __attribute__((always_inline)) BOOL fc_setKeychainStringForKeyWithAccessibility(NSString *key, NSString *value, CFTypeRef accessibility)
{
    return fc_setGroupKeychainStringForKeyWithAccessibility(key, value, accessibility, nil);
}

static __inline__ __attribute__((always_inline)) BOOL fc_setKeychainStringForKey(NSString *key, NSString *value)
{
    return fc_setGroupKeychainStringForKeyWithAccessibility(key, value, kSecAttrAccessibleAlways, nil);
}

#endif
