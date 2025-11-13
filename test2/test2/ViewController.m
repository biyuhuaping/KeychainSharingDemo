//
//  ViewController.m
//  test2
//
//  Created by ZB on 2025/11/12.
//

#import "ViewController.h"
#import "KeychainItemWrapper.h"
#import "KeychainHelper.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *userLab;
@property (weak, nonatomic) IBOutlet UILabel *passwordLab;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *str = [self bundleSeedID];
    NSLog(@"-----%@", str);
}

- (IBAction)getFromUserDefaults:(id)sender {
    NSUserDefaults *groupDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.zhou.app"];
    self.label.text = [groupDefaults objectForKey:@"userId"];
}

- (IBAction)getFromKeychain:(id)sender {
//    NSString *seedID = [self bundleSeedID];
//    NSString *accessGroup = nil;//[NSString stringWithFormat:@"%@.com.zhou.app", seedID];
//    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"Identifier" accessGroup:accessGroup];
//    
//    NSString *username = [wrapper objectForKey:(id)kSecAttrAccount];
//    NSString *password = [wrapper objectForKey:(id)kSecValueData];
    
    
    // 读取不共享 Keychain
    NSString *name = [KeychainHelper readValueForKey:@"username" accessGroup:nil];
    NSString *pwd = [KeychainHelper readValueForKey:@"password" accessGroup:nil];
    NSLog(@"不共享 Keychain : %@, %@", name, pwd);
    
    
    NSString *seedID = [self bundleSeedID];
    // 构建 accessGroup：TeamID.groupIdentifier（与 entitlements 中的配置一致，其实同一个账号下的app开启了Keychain Sharing，就不用传也能共享）
    NSString *accessGroup = nil;//[NSString stringWithFormat:@"%@.com.zhou.app", seedID];
    // 使用相同的 service 名称（所有 App 必须使用相同的 service）
    NSString *sharedService = @"com.zhou.shared.keychain";
    
    // 读取共享 Keychain
    NSString *username = [KeychainHelper readValueForKey:@"username" service:sharedService accessGroup:accessGroup];
    NSString *password = [KeychainHelper readValueForKey:@"password" service:sharedService accessGroup:accessGroup];
    NSLog(@"共享 Keychain %@, %@", username, password);
    self.userLab.text = username;
    self.passwordLab.text = password;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    NSString *deviceID = [[UIDevice currentDevice].identifierForVendor UUIDString];
    NSLog(@"\ndeviceID: %@\nuuid：%@",[KeychainHelper deviceID], deviceID);
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

@end
