//
//  KeychainHelper.m
//  YaoBangMang
//
//  Created by ZB on 2025/11/10.
//  Copyright © 2025 XiaoYaoYao.Ltd. All rights reserved.
//


// KeychainHelper.m
#import "KeychainHelper.h"
#import <Security/Security.h>
#import <UIKit/UIKit.h>

// deviceID 的存储 key
static NSString * const kDeviceIDKey = @"deviceID";
static NSString * const kGroupKey = nil;//@"5Z2477437E.com.YaoBangMang";//2UV86B857L
#define kServiceKey [[NSBundle mainBundle] bundleIdentifier]

// deviceID 的内存缓存，避免频繁读取 Keychain
static NSString *_cachedDeviceID = nil;

@implementation KeychainHelper

// 获取设备ID（优化版本）
// 优先从内存缓存读取，其次从 Keychain 读取，如果都不存在则生成新的并保存
// @return 设备ID字符串，优先使用 IDFV，如果不可用则使用 UUID
+ (NSString *)deviceID {
    // 1. 先从内存缓存读取
    if (_cachedDeviceID) {
        return _cachedDeviceID;
    }
    
    // 2. 从 Keychain 读取
    NSString *deviceID = [self readValueForKey:kDeviceIDKey accessGroup:kGroupKey];
    
    // 3. 如果 Keychain 中不存在，生成新的并保存
    if (!deviceID || deviceID.length == 0) {
        // 优先使用 IDFV（同一厂商的 App 在同一设备上相同）
        if ([UIDevice currentDevice]) {
            deviceID = [[UIDevice currentDevice].identifierForVendor UUIDString];
        } else {
            // 降级方案：使用 UUID
            deviceID = [[NSUUID UUID] UUIDString];
        }
        
        // 保存到 Keychain
        if (deviceID && deviceID.length > 0) {
            [self saveValue:deviceID forKey:kDeviceIDKey accessGroup:kGroupKey];
        }
    }
    
    // 4. 更新内存缓存
    if (deviceID && deviceID.length > 0) {
        _cachedDeviceID = deviceID;
    }
    
    return deviceID;
}

#pragma mark - keychin
// 从 Keychain 中读取指定 key 的值（内部方法）
+ (NSString *)readValueForKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
    if (!key) {
        return nil;
    }
    
    NSString *serviceName = service ?: kServiceKey;
    
    // 构建查询字典，直接获取数据
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrService] = serviceName;
    query[(__bridge id)kSecAttrAccount] = key;
    [self setAccessGroup:accessGroup toDictionary:query];
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    query[(__bridge id)kSecReturnData] = @YES;
    
    // 执行查询
    CFDataRef resultData = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&resultData);
    
    if (status == errSecSuccess && resultData) {
        NSData *data = (__bridge_transfer NSData *)resultData;
        NSString *valueStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Keychain 读取成功: key=%@, service=%@", key, serviceName);
        return valueStr;
    } else {
        NSLog(@"Keychain 读取失败: key=%@, service=%@, status=%d", key, serviceName, (int)status);
    }
    
    return nil;
}

// 从 Keychain 中读取指定 key 的值
+ (NSString *)readValueForKey:(NSString *)key accessGroup:(NSString *)accessGroup {
    return [self readValueForKey:key service:nil accessGroup:accessGroup];
}

// 保存值到 Keychain（内部方法）
+ (BOOL)saveValue:(NSString *)value forKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
    if (!value || !key) return NO;
    
    NSData *valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSString *serviceName = service ?: kServiceKey;
    
    // 构建查询字典（用于更新）
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrService] = serviceName;
    query[(__bridge id)kSecAttrAccount] = key;
    [self setAccessGroup:accessGroup toDictionary:query];
    
    // 构建更新数据
    NSMutableDictionary *updateData = [NSMutableDictionary dictionary];
    updateData[(__bridge id)kSecValueData] = valueData;
    
    // 直接尝试更新（大多数情况下项已存在）
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)updateData);
    
    if (status == errSecSuccess) {
        NSLog(@"Keychain 更新成功: key=%@, service=%@", key, serviceName);
        return YES;
    } else if (status == errSecItemNotFound) {
        // 项不存在，执行添加
        NSMutableDictionary *itemToAdd = [NSMutableDictionary dictionaryWithDictionary:query];
        itemToAdd[(__bridge id)kSecValueData] = valueData;
        // 在模拟器上移除 accessGroup（真机上保留）
        [self removeAccessGroupFromDictionary:itemToAdd];
        
        status = SecItemAdd((__bridge CFDictionaryRef)itemToAdd, NULL);
        if (status == errSecSuccess) {
            NSLog(@"Keychain 添加成功: key=%@, service=%@", key, serviceName);
            return YES;
        } else {
            NSLog(@"Keychain 添加失败: key=%@, service=%@, status=%d", key, serviceName, (int)status);
            return NO;
        }
    } else {
        NSLog(@"Keychain 更新失败: key=%@, service=%@, status=%d", key, serviceName, (int)status);
        return NO;
    }
}

// 保存值到 Keychain
+ (BOOL)saveValue:(NSString *)value forKey:(NSString *)key accessGroup:(NSString *)accessGroup {
    return [self saveValue:value forKey:key service:nil accessGroup:accessGroup];
}

// 从 Keychain 中删除指定 key 的值（内部方法）
+ (BOOL)deleteValueForKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
    if (!key) {
        return NO;
    }
    
    NSString *serviceName = service ?: kServiceKey;
    
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    query[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    query[(__bridge id)kSecAttrService] = serviceName;
    query[(__bridge id)kSecAttrAccount] = key;
    [self setAccessGroup:accessGroup toDictionary:query];
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    if (status == errSecSuccess || status == errSecItemNotFound) {
        NSLog(@"Keychain 删除成功: key=%@, service=%@", key, serviceName);
        return YES;
    } else {
        NSLog(@"Keychain 删除失败: key=%@, service=%@, status=%d", key, serviceName, (int)status);
        return NO;
    }
}

// 从 Keychain 中删除指定 key 的值
+ (BOOL)deleteValueForKey:(NSString *)key accessGroup:(NSString *)accessGroup {
    return [self deleteValueForKey:key service:nil accessGroup:accessGroup];
}

#pragma mark - Private Methods

// 设置 accessGroup 到字典中（模拟器上忽略）
+ (void)setAccessGroup:(NSString *)accessGroup toDictionary:(NSMutableDictionary *)dictionary {
    if (accessGroup == nil) {
        return;
    }
    
#if TARGET_IPHONE_SIMULATOR
    // 模拟器上忽略访问组
#else
    dictionary[(__bridge id)kSecAttrAccessGroup] = accessGroup;
#endif
}

// 从字典中移除 accessGroup（用于添加操作）
+ (void)removeAccessGroupFromDictionary:(NSMutableDictionary *)dictionary {
#if TARGET_IPHONE_SIMULATOR
    [dictionary removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
#endif
}

@end
