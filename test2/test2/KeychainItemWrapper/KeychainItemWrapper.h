//
//  KeychainItemWrapper.h
//

#import <Foundation/Foundation.h>

// KeychainItemWrapper 类是对 iOS Keychain 通信的抽象层。
// 它提供了一个简单的封装，用于处理 Keychain 中 CF/NS 容器对象之间的转换。
@interface KeychainItemWrapper : NSObject

// 指定初始化方法
// @param identifier 用于标识钥匙串项的字符串标识符
// @param accessGroup 钥匙串访问组，用于在多个应用间共享钥匙串数据。传入 nil 表示不共享。
// @return 初始化后的 KeychainItemWrapper 实例
- (id)initWithIdentifier:(NSString *)identifier accessGroup:(NSString *)accessGroup;

// 设置钥匙串项的值
// @param inObject 要设置的值对象（不能为 nil）
// @param key 键名
- (void)setObject:(id)inObject forKey:(id)key;

// 获取钥匙串项的值
// @param key 键名
// @return 对应的值对象，如果不存在则返回 nil
- (id)objectForKey:(id)key;

// 重置钥匙串项，删除现有数据并初始化为默认值
- (void)resetKeychainItem;

@end
