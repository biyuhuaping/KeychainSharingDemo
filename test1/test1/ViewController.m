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

@end

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
    
    // 方式2：跨 App 共享（需要在所有 App 的 entitlements 中配置相同的 keychain-access-groups）
    // 获取 Team ID（bundleSeedID）
    NSString *seedID = [self bundleSeedID];
    if (seedID) {
        // 构建 accessGroup：TeamID.groupIdentifier（与 entitlements 中的配置一致）
        NSString *accessGroup = [NSString stringWithFormat:@"%@.com.zhou.app", seedID];
        // 使用相同的 service 名称（所有 App 必须使用相同的 service）
        NSString *sharedService = @"com.zhou.shared.keychain";
        
        // 保存到共享 Keychain
        [KeychainHelper saveValue:username forKey:@"username" service:sharedService accessGroup:accessGroup];
        [KeychainHelper saveValue:password forKey:@"password" service:sharedService accessGroup:accessGroup];
        
        // 读取共享 Keychain
        NSString *sharedUsername = [KeychainHelper readValueForKey:@"username" service:sharedService accessGroup:accessGroup];
        NSString *sharedPassword = [KeychainHelper readValueForKey:@"password" service:sharedService accessGroup:accessGroup];
        NSLog(@"共享 Keychain - username: %@, password: %@", sharedUsername, sharedPassword);
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    NSString *deviceID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    NSLog(@"\ndeviceID: %@\nuuid：%@",[KeychainHelper deviceID], deviceID);
}

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

@end
