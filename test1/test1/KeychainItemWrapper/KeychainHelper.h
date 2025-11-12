//
//  KeychainHelper.h
//  YaoBangMang
//
//  Created by ZB on 2025/11/10.
//  Copyright © 2025 XiaoYaoYao.Ltd. All rights reserved.
//  Keychain 工具类，用于安全地存储、读取和删除 Keychain 中的数据


#import <Foundation/Foundation.h>

@interface KeychainHelper : NSObject

// 获取设备ID（优化版本）
// 优先从内存缓存读取，其次从 Keychain 读取，如果都不存在则生成新的并保存
// @return 设备ID字符串，优先使用 IDFV，如果不可用则使用 UUID
+ (NSString *)deviceID;

// 从 Keychain 中读取指定 key 的值
// @param key 要读取的 key，例如@"userToken"、@"password" 等
// @param accessGroup 访问组标识符，用于 App 组间共享数据，格式：TeamID.groupIdentifier，可为 nil
// @return 读取到的字符串值，如果不存在或读取失败则返回 nil
+ (NSString *)readValueForKey:(NSString *)key accessGroup:(NSString *)accessGroup;

// 从 Keychain 中读取指定 key 的值（支持跨 App 共享）
// @param key 要读取的 key，例如@"userToken"、@"password" 等
// @param service 服务名称，用于跨 App 共享时使用相同的 service，可为 nil（默认使用 bundle identifier）
// @param accessGroup 访问组标识符，用于 App 组间共享数据，格式：TeamID.groupIdentifier，可为 nil
// @return 读取到的字符串值，如果不存在或读取失败则返回 nil
+ (NSString *)readValueForKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup;

// 保存值到 Keychain
// @param value 要保存的字符串值
// @param key 存储的 key，例如@"userToken"、@"password" 等
// @param accessGroup 访问组标识符，用于 App 组间共享数据，格式：TeamID.groupIdentifier，可为 nil
// @return 保存成功返回 YES，失败返回 NO
+ (BOOL)saveValue:(NSString *)value forKey:(NSString *)key accessGroup:(NSString *)accessGroup;

// 保存值到 Keychain（支持跨 App 共享）
// @param value 要保存的字符串值
// @param key 存储的 key，例如@"userToken"、@"password" 等
// @param service 服务名称，用于跨 App 共享时使用相同的 service，可为 nil（默认使用 bundle identifier）
// @param accessGroup 访问组标识符，用于 App 组间共享数据，格式：TeamID.groupIdentifier，可为 nil
// @return 保存成功返回 YES，失败返回 NO
+ (BOOL)saveValue:(NSString *)value forKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup;

// 从 Keychain 中删除指定 key 的值
// @param key 要删除的 key，例如@"userToken"、@"password" 等
// @param accessGroup 访问组标识符，用于 App 组间共享数据，格式：TeamID.groupIdentifier，可为 nil
// @return 删除成功返回 YES，失败返回 NO（如果 key 不存在也会返回 NO）
+ (BOOL)deleteValueForKey:(NSString *)key accessGroup:(NSString *)accessGroup;

// 从 Keychain 中删除指定 key 的值（支持跨 App 共享）
// @param key 要删除的 key，例如@"userToken"、@"password" 等
// @param service 服务名称，用于跨 App 共享时使用相同的 service，可为 nil（默认使用 bundle identifier）
// @param accessGroup 访问组标识符，用于 App 组间共享数据，格式：TeamID.groupIdentifier，可为 nil
// @return 删除成功返回 YES，失败返回 NO（如果 key 不存在也会返回 NO）
+ (BOOL)deleteValueForKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup;

@end
