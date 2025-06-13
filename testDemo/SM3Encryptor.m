//
//  SM3Encryptor.m
//  testDemo
//
//  Created by wt on 2025/6/12.
//

#import "SM3Encryptor.h"
#include <stdint.h>

// SM3 上下文结构
typedef struct {
    uint32_t state[8];   // 8个32位寄存器（A-H）
    uint64_t totalLength; // 总消息长度（位）
    uint8_t buffer[64];  // 当前数据块缓存
    uint32_t bufferLength; // 当前缓冲区长度
} SM3Context;

// 循环左移
static inline uint32_t ROTL(uint32_t x, uint8_t n) {
    return (x << n) | (x >> (32 - n));
}

// 布尔函数 FF0（0≤j≤15）
static inline uint32_t FF0(uint32_t x, uint32_t y, uint32_t z) {
    return x ^ y ^ z;
}

// 布尔函数 FF1（16≤j≤63）
static inline uint32_t FF1(uint32_t x, uint32_t y, uint32_t z) {
    return (x & y) | (x & z) | (y & z);
}

// 布尔函数 GG0（0≤j≤15）
static inline uint32_t GG0(uint32_t x, uint32_t y, uint32_t z) {
    return x ^ y ^ z;
}

// 布尔函数 GG1（16≤j≤63）
static inline uint32_t GG1(uint32_t x, uint32_t y, uint32_t z) {
    return (x & y) | ((~x) & z);
}

// 置换函数 P0
static inline uint32_t P0(uint32_t x) {
    return x ^ ROTL(x, 9) ^ ROTL(x, 17);
}

// 置换函数 P1
static inline uint32_t P1(uint32_t x) {
    return x ^ ROTL(x, 15) ^ ROTL(x, 23);
}

// 初始化SM3上下文
void SM3Init(SM3Context *context) {
    // SM3标准初始值
    context->state[0] = 0x7380166F;
    context->state[1] = 0x4914B2B9;
    context->state[2] = 0x172442D7;
    context->state[3] = 0xDA8A0600;
    context->state[4] = 0xA96F30BC;
    context->state[5] = 0x163138AA;
    context->state[6] = 0xE38DEE4D;
    context->state[7] = 0xB0FB0E4E;
    context->totalLength = 0;
    context->bufferLength = 0;
    memset(context->buffer, 0, 64);
}

// 处理单个64字节块（压缩函数核心）
void SM3Compress(SM3Context *context, const uint8_t block[64]) {
    // 1. 消息扩展：16字 → 68字（W） + 64字（W1）
    uint32_t W[68], W1[64];
    
    // 初始化前16字（大端序转换）
    for (int i = 0; i < 16; i++) {
        W[i] = (uint32_t)block[i*4] << 24 |
               (uint32_t)block[i*4+1] << 16 |
               (uint32_t)block[i*4+2] << 8 |
               (uint32_t)block[i*4+3];
    }
    
    // 计算W[16]-W[67]
    for (int j = 16; j < 68; j++) {
        uint32_t temp = W[j-16] ^ W[j-9] ^ ROTL(W[j-3], 15);
        W[j] = P1(temp) ^ ROTL(W[j-13], 7) ^ W[j-6];
    }
    
    // 计算W1[0]-W1[63]
    for (int j = 0; j < 64; j++) {
        W1[j] = W[j] ^ W[j+4];
    }
    
    // 2. 寄存器初始化（A-H）
    uint32_t A = context->state[0];
    uint32_t B = context->state[1];
    uint32_t C = context->state[2];
    uint32_t D = context->state[3];
    uint32_t E = context->state[4];
    uint32_t F = context->state[5];
    uint32_t G = context->state[6];
    uint32_t H = context->state[7];
    
    // 3. 64轮迭代（严格遵循标准）
    for (int j = 0; j < 64; j++) {
        uint32_t SS1, SS2, TT1, TT2;
        
        // 常量选择（关键修正）
        uint32_t TJ = (j < 16) ? 0x79CC4519 : 0x7A879D8A;
        
        // 计算SS1/SS2（修正了TJ参数）
        SS1 = ROTL(ROTL(A, 12) + E + ROTL(TJ, j % 32), 7);
        SS2 = SS1 ^ ROTL(A, 12);
        
        // 计算TT1/TT2（使用内联函数）
        if (j < 16) {
            TT1 = FF0(A, B, C) + D + SS2 + W1[j];
            TT2 = GG0(E, F, G) + H + SS1 + W[j];
        } else {
            TT1 = FF1(A, B, C) + D + SS2 + W1[j];
            TT2 = GG1(E, F, G) + H + SS1 + W[j];
        }
        
        // 更新寄存器（严格顺序）
        D = C;
        C = ROTL(B, 9);
        B = A;
        A = TT1;
        H = G;
        G = ROTL(F, 19);
        F = E;
        E = P0(TT2);
    }
    
    // 4. 更新最终状态（与初始IV异或）
    context->state[0] ^= A;
    context->state[1] ^= B;
    context->state[2] ^= C;
    context->state[3] ^= D;
    context->state[4] ^= E;
    context->state[5] ^= F;
    context->state[6] ^= G;
    context->state[7] ^= H;
}

// 更新数据（可分多次调用）
void SM3Update(SM3Context *context, const uint8_t *data, size_t length) {
    context->totalLength += length * 8; // 更新总位数（字节转位）
    
    // 处理缓冲区中的剩余空间
    if (context->bufferLength > 0) {
        size_t copySize = MIN(64 - context->bufferLength, length);
        memcpy(context->buffer + context->bufferLength, data, copySize);
        context->bufferLength += copySize;
        data += copySize;
        length -= copySize;
        
        if (context->bufferLength == 64) {
            SM3Compress(context, context->buffer);
            context->bufferLength = 0;
        }
    }
    
    // 处理完整块
    while (length >= 64) {
        SM3Compress(context, data);
        data += 64;
        length -= 64;
    }
    
    // 缓存剩余数据
    if (length > 0) {
        memcpy(context->buffer, data, length);
        context->bufferLength = length;
    }
}

// 完成哈希计算
void SM3Final(SM3Context *context, uint8_t output[32]) {
    // 计算填充长度（SM3标准：补位1 + k个0 + 64位长度）
    size_t totalBits = context->totalLength;
    size_t paddingBits = (context->bufferLength < 56) ?
                         (56 - context->bufferLength) :
                         (120 - context->bufferLength);
    
    // 构建填充数据
    uint8_t padding[128] = {0};
    padding[0] = 0x80; // 补位起始位（二进制10000000）
    
    // 添加填充
    SM3Update(context, padding, paddingBits);
    
    // 添加消息长度（大端序64位）
    uint64_t bitCount = CFSwapInt64HostToBig(totalBits);
    SM3Update(context, (uint8_t *)&bitCount, 8);
    
    // 确保最后一个块被处理
    if (context->bufferLength > 0) {
        memset(context->buffer + context->bufferLength, 0, 64 - context->bufferLength);
        SM3Compress(context, context->buffer);
    }
    
    // 输出最终哈希（256位，大端序）
    for (int i = 0; i < 8; i++) {
        output[i*4]     = (uint8_t)(context->state[i] >> 24);
        output[i*4 + 1] = (uint8_t)(context->state[i] >> 16);
        output[i*4 + 2] = (uint8_t)(context->state[i] >> 8);
        output[i*4 + 3] = (uint8_t)(context->state[i]);
    }
}

// Objective-C 封装接口
@implementation SM3Encryptor

+ (NSData *)hashWithData:(NSData *)inputData {
    SM3Context context;
    SM3Init(&context);
    
    // 处理输入数据
    SM3Update(&context, inputData.bytes, inputData.length);
    
    // 获取结果
    uint8_t output[32];
    SM3Final(&context, output);
    
    return [NSData dataWithBytes:output length:32];
}

+ (NSString *)hexStringWithData:(NSData *)inputData {
    NSData *hashData = [self hashWithData:inputData];
    const uint8_t *bytes = (const uint8_t *)hashData.bytes;
    NSMutableString *hex = [NSMutableString string];
    
    for (NSUInteger i = 0; i < hashData.length; i++) {
        [hex appendFormat:@"%02X", bytes[i]];
    }
    
    return [hex copy];
}

+ (NSString *)hexStringWithInput:(NSString *)inputStr {
    NSData *inputData = [inputStr dataUsingEncoding:NSUTF8StringEncoding];
    NSData *hashData = [self hashWithData:inputData];
    const uint8_t *bytes = (const uint8_t *)hashData.bytes;
    NSMutableString *hex = [NSMutableString string];
    
    for (NSUInteger i = 0; i < hashData.length; i++) {
        [hex appendFormat:@"%02X", bytes[i]];
    }
    
    return [hex copy];
}


@end

