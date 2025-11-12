//
//  KeychainItemWrapper.m
//

#import "KeychainItemWrapper.h"
#import <Security/Security.h>

@interface KeychainItemWrapper () {
    // 标识符，用于构建查询字典
    NSString *_identifier;
    // 访问组，用于构建查询字典
    NSString *_accessGroup;
}
@end

@implementation KeychainItemWrapper

- (id)initWithIdentifier:(NSString *)identifier accessGroup:(NSString *)accessGroup {
    if (self = [super init]) {
        _identifier = identifier;
        _accessGroup = accessGroup;
    }
    return self;
}

- (void)setObject:(id)inObject forKey:(id)key {
    if (inObject == nil) {
        return;
    }
    
    NSMutableDictionary *keychainItemData = [self loadKeychainItemData];
    id currentObject = keychainItemData[key];
    if (![currentObject isEqual:inObject]) {
        keychainItemData[key] = inObject;
        [self writeToKeychain:keychainItemData];
    }
}

- (id)objectForKey:(id)key {
    NSMutableDictionary *keychainItemData = [self loadKeychainItemData];
    return keychainItemData[key];
}

- (void)resetKeychainItem {
    NSMutableDictionary *query = [self buildQueryDictionary];
    NSMutableDictionary *tempDictionary = [NSMutableDictionary dictionaryWithDictionary:query];
    tempDictionary[(__bridge id)kSecReturnAttributes] = @YES;
    
    NSMutableDictionary *keychainItemData = [self loadKeychainItemData];
    if (keychainItemData) {
        NSMutableDictionary *deleteDict = [self dictionaryToSecItemFormat:keychainItemData];
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)deleteDict);
        if (status != errSecSuccess && status != errSecItemNotFound) {
            NSLog(@"警告：删除钥匙串项时出错，错误代码：%d", (int)status);
        }
    }
    
    // 创建新的空数据字典
    NSMutableDictionary *newData = [NSMutableDictionary dictionary];
    newData[(__bridge id)kSecAttrGeneric] = _identifier;
    [self setAccessGroup:_accessGroup toDictionary:newData];
    newData[(__bridge id)kSecAttrAccount] = @"";
    newData[(__bridge id)kSecAttrLabel] = @"";
    newData[(__bridge id)kSecAttrDescription] = @"";
    newData[(__bridge id)kSecValueData] = @"";
    
    [self writeToKeychain:newData];
}

- (NSMutableDictionary *)dictionaryToSecItemFormat:(NSDictionary *)dictionaryToConvert {
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    returnDictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    
    NSString *passwordString = dictionaryToConvert[(__bridge id)kSecValueData];
    if (passwordString) {
        NSData *passwordData = [passwordString dataUsingEncoding:NSUTF8StringEncoding];
        returnDictionary[(__bridge id)kSecValueData] = passwordData;
    }
    
    return returnDictionary;
}

- (NSMutableDictionary *)secItemFormatToDictionary:(NSDictionary *)dictionaryToConvert {
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionaryToConvert];
    returnDictionary[(__bridge id)kSecReturnData] = @YES;
    returnDictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    
    CFDataRef passwordDataRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)returnDictionary, (CFTypeRef *)&passwordDataRef);
    
    if (status == errSecSuccess && passwordDataRef) {
        NSData *passwordData = (__bridge NSData *)passwordDataRef;
        [returnDictionary removeObjectForKey:(__bridge id)kSecReturnData];
        NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
        if (password) {
            returnDictionary[(__bridge id)kSecValueData] = password;
        }
    } else {
        NSLog(@"警告：无法从钥匙串中读取数据，错误代码：%d", (int)status);
        [returnDictionary removeObjectForKey:(__bridge id)kSecReturnData];
        returnDictionary[(__bridge id)kSecValueData] = @"";
    }
    
    return returnDictionary;
}

- (void)writeToKeychain:(NSMutableDictionary *)keychainItemData {
    NSMutableDictionary *query = [self buildQueryDictionary];
    CFDictionaryRef attributesRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&attributesRef);
    
    if (status == errSecSuccess) {
        NSDictionary *attributes = (__bridge NSDictionary *)attributesRef;
        NSMutableDictionary *updateItem = [NSMutableDictionary dictionaryWithDictionary:attributes];
        updateItem[(__bridge id)kSecClass] = query[(__bridge id)kSecClass];
        
        NSMutableDictionary *tempCheck = [self dictionaryToSecItemFormat:keychainItemData];
        [tempCheck removeObjectForKey:(__bridge id)kSecClass];
        [self removeAccessGroupFromDictionary:tempCheck];
        
        status = SecItemUpdate((__bridge CFDictionaryRef)updateItem, (__bridge CFDictionaryRef)tempCheck);
        if (status != errSecSuccess) {
            NSLog(@"错误：无法更新钥匙串项，错误代码：%d", (int)status);
        }
    } else {
        NSMutableDictionary *itemToAdd = [self dictionaryToSecItemFormat:keychainItemData];
        [self removeAccessGroupFromDictionary:itemToAdd];
        
        status = SecItemAdd((__bridge CFDictionaryRef)itemToAdd, NULL);
        if (status != errSecSuccess) {
            NSLog(@"错误：无法添加钥匙串项，错误代码：%d", (int)status);
        }
    }
}

#pragma mark - Private Methods

// 构建查询字典
- (NSMutableDictionary *)buildQueryDictionary {
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrGeneric] = _identifier;
    [self setAccessGroup:_accessGroup toDictionary:query];
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    query[(__bridge id)kSecReturnAttributes] = @YES;
    return query;
}

// 从钥匙串加载数据
- (NSMutableDictionary *)loadKeychainItemData {
    NSMutableDictionary *query = [self buildQueryDictionary];
    NSDictionary *tempQuery = [NSDictionary dictionaryWithDictionary:query];
//    NSMutableDictionary *outDictionary = nil;
    CFDictionaryRef outDictionary = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)tempQuery, (CFTypeRef *)&outDictionary);
    
    if (status == errSecSuccess) {
        return [self secItemFormatToDictionary:(__bridge NSDictionary *)(outDictionary)];
    } else {
        // 如果不存在，返回空字典
        NSMutableDictionary *emptyData = [NSMutableDictionary dictionary];
        emptyData[(__bridge id)kSecAttrGeneric] = _identifier;
        [self setAccessGroup:_accessGroup toDictionary:emptyData];
        emptyData[(__bridge id)kSecAttrAccount] = @"";
        emptyData[(__bridge id)kSecAttrLabel] = @"";
        emptyData[(__bridge id)kSecAttrDescription] = @"";
        emptyData[(__bridge id)kSecValueData] = @"";
        return emptyData;
    }
}

- (void)setAccessGroup:(NSString *)accessGroup toDictionary:(NSMutableDictionary *)dictionary {
    if (accessGroup == nil) {
        return;
    }
    
#if TARGET_IPHONE_SIMULATOR
    // 模拟器上忽略访问组
#else
    dictionary[(__bridge id)kSecAttrAccessGroup] = accessGroup;
#endif
}

- (void)removeAccessGroupFromDictionary:(NSMutableDictionary *)dictionary {
#if TARGET_IPHONE_SIMULATOR
    [dictionary removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
#endif
}

@end
