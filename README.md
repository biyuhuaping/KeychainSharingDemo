在 iOS 中，所有应用的 Keychain 数据都存储在系统统一的数据库 /private/var/Keychains/keychain-2.db 中。每个 App 默认只能访问自己创建的 Keychain 条目（即“私有”数据），不同应用之间互相隔离。若希望多个 App 共享同一份 Keychain 数据，可通过启用 Keychain Access Group（钥匙串共享）来实现。

那么怎么启用 Keychain Access Group呢？下面以Xcode 26为例说明：
# 一、使用 Keychain Sharing 钥匙串共享（推荐）
多个 App 共享一个设备标识（例如 UUID）最可靠的方法。
前提条件：

 - 所有 App 必须使用同一个开发者账号签名。
 - 在 Xcode → “Signing & Capabilities” → 打开 “Keychain Sharing”。
 - 添加相同的 Access Group，例如：

```
com.company.shared
```

## APP1:
### 1、打开项目，Capabilities 添加 KeyChain Sharing
![添加 KeyChain Sharing](https://i-blog.csdnimg.cn/direct/c66b5c92c39d4c47825829a0dcbbc3a9.png)


输入Keychain Groups后点击回车，项目中会自动生成以项目名命名的entitlements文件:
![在这里插入图片描述](https://i-blog.csdnimg.cn/direct/81601666f6304c5090a6b6539a14566e.png)

### 2、Apple官方已经封装好了一个类[KeychinaItemWrapper](https://developer.apple.com/library/archive/samplecode/GenericKeychain/Introduction/Intro.html)。这个类提供了几个接口：
![在这里插入图片描述](https://i-blog.csdnimg.cn/direct/a4de6eabe5104603b66f4ac4156e4478.png)
添加KeyChain Sharing后，app如果用的同一个账号下的证书，就可以共享钥匙串，所以方法- (id)initWithIdentifier:(NSString *)identifier accessGroup:(NSString *)accessGroup，accessGroup传nil或 TeamID.com.zhou.app 都可以共享。
但如果传错了accessGroup，就会报错：-34018 （无法添加钥匙串项）


## APP2:
按照上面一样的方法即可。
![在这里插入图片描述](https://i-blog.csdnimg.cn/direct/5349d765938a4cd7be7fd9ee7fac98a9.png)

![在这里插入图片描述](https://i-blog.csdnimg.cn/direct/47ec57f9a52a44209505a3c18bd65bae.png)


<br>

我另外封装了一个类 KeychainHelper，也在demo中，欢迎一起交流学习：[KeychainSharingDemo](https://github.com/biyuhuaping/KeychainSharingDemo.git)


demo中，还实现了通过App Groups 共享数据，只需要在 Capabilities添加App Groups
# 2、App Group + UserDefaults / File
Keychain 不方便时的第二选择。

步骤：
 - 在 Apple Developer 后台为多个 App 添加相同的 App Group ID：`group.com.company.shared`
- 在 Xcode 打开 “App Groups” capability。
- 使用 UserDefaults(suiteName:) 或共享文件夹路径 /Library/Group Containers/

这样即使卸载单个 App，其他 App 仍然能保留相同的 ID。
<br><br><br>
本文demo：[KeychainSharingDemo](https://github.com/biyuhuaping/KeychainSharingDemo.git) 欢迎一起交流学习，如有疏漏或错误，请不吝指正。

参考：https://blog.csdn.net/skylin19840101/article/details/48264685
