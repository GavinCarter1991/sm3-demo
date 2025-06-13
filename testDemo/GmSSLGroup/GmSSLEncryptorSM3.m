//
//  GmSSLEncryptorSM3.m
//  testDemo
//
//  Created by wt on 2025/6/12.
//

#import "GmSSLEncryptorSM3.h"
#import "sm3.h"

@implementation GmSSLEncryptorSM3

+ (instancetype)encryptor {
    return [[GmSSLEncryptorSM3 alloc] init];
}

+ (NSData *)sm3HashWithData:(NSData *)data {
    // 初始化 SM3 上下文
    SM3_CTX ctx;
    sm3_init(&ctx);
    // 添加数据到哈希计算
    sm3_update(&ctx, data.bytes, data.length);
    // 准备存储结果的缓冲区 (SM3 输出为 32 字节)
    uint8_t dgst[SM3_DIGEST_SIZE];
    // 完成哈希计算
    sm3_finish(&ctx, dgst);
    // 转换为 NSData
    return [NSData dataWithBytes:dgst length:SM3_DIGEST_SIZE];
}

+ (NSString *)sm3HashWithString:(NSString *)input {
    NSData *inputData = [input dataUsingEncoding:NSUTF8StringEncoding];
    // 计算 SM3 哈希
    NSData *hashData = [GmSSLEncryptorSM3 sm3HashWithData:inputData];
    // 转换为十六进制字符串显示
    NSMutableString *hexString = [NSMutableString string];
    const uint8_t *bytes = (const uint8_t *)hashData.bytes;
    for (NSUInteger i = 0; i < hashData.length; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    return hexString;
}


@end
