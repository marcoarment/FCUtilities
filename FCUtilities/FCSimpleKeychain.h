//
//  FCSimpleKeychain.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#ifndef FCSimpleKeychain_h
#define FCSimpleKeychain_h

@import Security;

static __inline__ __attribute__((always_inline)) NSString *fc_keychainStringForKey(NSString *key, BOOL *outKeychainError)
{
    CFDataRef data = nil;
    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef) @{
        (__bridge id) kSecClass : (__bridge id) kSecClassGenericPassword,
        (__bridge id) kSecAttrService : [[NSBundle.mainBundle.infoDictionary objectForKey:(NSString *)kCFBundleIdentifierKey] stringByAppendingFormat:@".%@", key],
        (__bridge id) kSecReturnData : (__bridge id) kCFBooleanTrue
    }, (CFTypeRef *) &data);
    
    if (err != errSecSuccess && err != errSecItemNotFound) {
        NSLog(@"Keychain error: SecItemCopyMatching failed for key %@: %d", key, (int) err);
        if (outKeychainError) *outKeychainError = YES;
        return nil;
    }
    
    if (outKeychainError) *outKeychainError = NO;
    if (! data) return nil;
    return [[NSString alloc] initWithData:(__bridge_transfer NSData *)data encoding:NSUTF8StringEncoding];
}

static __inline__ __attribute__((always_inline)) BOOL fc_deleteKeychainStringForKey(NSString *key)
{
    return errSecSuccess == SecItemDelete((__bridge CFDictionaryRef) @{
        (__bridge id) kSecClass : (__bridge id) kSecClassGenericPassword,
        (__bridge id) kSecAttrService : [[NSBundle.mainBundle.infoDictionary objectForKey:(NSString *)kCFBundleIdentifierKey] stringByAppendingFormat:@".%@", key],
    });
}

static __inline__ __attribute__((always_inline)) BOOL fc_setKeychainStringForKeyWithAccessibility(NSString *key, NSString *value, CFTypeRef accessibility)
{
    if (! value) return fc_deleteKeychainStringForKey(key);

    NSDictionary *query = @{
        (__bridge id) kSecClass : (__bridge id) kSecClassGenericPassword,
        (__bridge id) kSecAttrService : [[NSBundle.mainBundle.infoDictionary objectForKey:(NSString *)kCFBundleIdentifierKey] stringByAppendingFormat:@".%@", key],
        (__bridge id) kSecAttrAccessible : (__bridge id) accessibility,
        (__bridge id) kSecValueData : [value dataUsingEncoding:NSUTF8StringEncoding]
    };

    OSStatus err = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
    if (err == errSecDuplicateItem && fc_deleteKeychainStringForKey(key)) err = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
    if (err != errSecSuccess) NSLog(@"Keychain error: SecItemAdd failed for key %@: %d", key, (int) err);
    return err == errSecSuccess;
}

static __inline__ __attribute__((always_inline)) BOOL fc_setKeychainStringForKey(NSString *key, NSString *value) { return fc_setKeychainStringForKeyWithAccessibility(key, value, kSecAttrAccessibleAlways); }

#endif
