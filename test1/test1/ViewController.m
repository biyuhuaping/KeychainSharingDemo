//
//  ViewController.m
//  test1
//
//  Created by ZB on 2025/11/12.
//

#import "ViewController.h"
#import "KeychainItemWrapper.h"
#import "KeychainHelper.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITextField *userTF;
@property (weak, nonatomic) IBOutlet UITextField *passwordTF;

@property (nonatomic, copy) NSString *deviceID;

@end

static NSString * const kService = @"com.zhou.shared.keychain";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *str = [self bundleSeedID];
    NSLog(@"-----%@", str);
}

- (IBAction)saveToUserDefaults:(id)sender {
    NSUserDefaults *groupDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.zhou.app"];
    [groupDefaults setObject:self.textField.text forKey:@"userId"];
}

- (IBAction)saveToKeychain:(id)sender {
    NSString *username = self.userTF.text;
    NSString *password = self.passwordTF.text;

//    NSString *seedID = [self bundleSeedID];
//    NSString *accessGroup = nil;//[NSString stringWithFormat:@"%@.com.zhou.app", seedID];
//    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"Identifier" accessGroup:accessGroup];
//    [wrapper setObject:username forKey:(id)kSecAttrAccount];
//    [wrapper setObject:password forKey:(id)kSecValueData];
    
    
    // 方式1：单 App 使用（不共享）
    [KeychainHelper saveValue:username forKey:@"username" accessGroup:nil];
    [KeychainHelper saveValue:password forKey:@"password" accessGroup:nil];
    // 读取不共享 Keychain
    NSString *name = [KeychainHelper readValueForKey:@"username" accessGroup:nil];
    NSString *pwd = [KeychainHelper readValueForKey:@"password" accessGroup:nil];
    NSLog(@"不共享 Keychain : %@, %@", name, pwd);
    
    
    // 方式2：跨 App 共享（需要在所有 App 的 entitlements 中配置相同的 keychain-access-groups）
    // 获取 Team ID（bundleSeedID）
    NSString *seedID = [self bundleSeedID];
    // 构建 accessGroup：TeamID.groupIdentifier（与 entitlements 中的配置一致）其实同一个账号下的app开启了Keychain Sharing后，不传accessGroup也能共享，不同账号下的app，使用同样的accessGroup也无法共享
    NSString *accessGroup = nil;//[NSString stringWithFormat:@"%@.com.zhou.app", seedID];
    
    // 保存到共享 Keychain，（所有 App 必须使用相同的 service才能共享）
    [KeychainHelper saveValue:username forKey:@"username" service:kService accessGroup:accessGroup];
    [KeychainHelper saveValue:password forKey:@"password" service:kService accessGroup:accessGroup];
    
    // 读取共享 Keychain，（所有 App 必须使用相同的 service）
    NSString *sharedUsername = [KeychainHelper readValueForKey:@"username" service:kService accessGroup:accessGroup];
    NSString *sharedPassword = [KeychainHelper readValueForKey:@"password" service:kService accessGroup:accessGroup];
    NSLog(@"共享 Keychain %@, %@", sharedUsername, sharedPassword);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    NSString *deviceID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    NSLog(@"\ndeviceID: %@\nuuid：%@",[self deviceID], deviceID);
}

//自动获取 Team ID：从系统返回的 attributes 中提取 Team ID
- (NSString *)bundleSeedID {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrAccount: @"bundleSeedID",
        (__bridge id)kSecAttrService: @"",
        (__bridge id)kSecReturnAttributes: @YES
    };
    CFDictionaryRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status == errSecItemNotFound) {
        status = SecItemAdd((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    }
    if (status != errSecSuccess) {
        return nil;
    }
    NSString *accessGroup = [(__bridge NSDictionary *)result objectForKey:(__bridge id)kSecAttrAccessGroup];
    NSArray *components = [accessGroup componentsSeparatedByString:@"."];
    NSString *bundleSeedID = [components firstObject];
    CFRelease(result);
    return bundleSeedID;
}

// 获取设备ID（优化版本，支持跨 App 共享）
// 优先从内存缓存读取，其次从 Keychain 读取，如果都不存在则生成新的并保存
// @return 设备ID字符串，优先使用 IDFV，如果不可用则使用 UUID
// 注意：使用共享的 service 名称，确保所有 App 都能访问同一个 deviceID
- (NSString *)deviceID {
    // 1. 先从内存缓存读取
    if (!_deviceID) {
        static NSString * const kDeviceIDKey = @"deviceID";
        // 2. 从 Keychain 读取（使用共享的 service 名称）
        NSString *deviceID = [KeychainHelper readValueForKey:kDeviceIDKey service:kService accessGroup:nil];
        
        // 3. 如果 Keychain 中不存在，生成新的并保存
        if (!deviceID || deviceID.length == 0) {
            // 优先使用 IDFV（同一厂商的 App 在同一设备上相同）
            if ([UIDevice currentDevice]) {
                deviceID = [[UIDevice currentDevice].identifierForVendor UUIDString];
            } else {
                // 降级方案：使用 UUID
                deviceID = [[NSUUID UUID] UUIDString];
            }
            // 保存到 Keychain（使用共享的 service 名称）
            [KeychainHelper saveValue:deviceID forKey:kDeviceIDKey service:kService accessGroup:nil];
        }
        _deviceID = deviceID;
    }
    return _deviceID;
}

@end
