//
//  SM3Encryptor.m
//  testDemo
//
//  Created by wt on 2025/6/12.
//

#import "SM3Encryptor.h"

// SM3 常量定义
#define SM3_BLOCK_SIZE 64
#define SM3_DIGEST_SIZE 32
#define SM3_HMAC_SIZE 32

// 循环左移
static inline uint32_t LEFT_ROTATE(uint32_t x, uint32_t n) {
    return (x << n) | (x >> (32 - n));
}

// 布尔函数
static inline uint32_t FF(uint32_t x, uint32_t y, uint32_t z, uint32_t j) {
    if (j < 16) {
        return x ^ y ^ z;
    } else {
        return (x & y) | (x & z) | (y & z);
    }
}

static inline uint32_t GG(uint32_t x, uint32_t y, uint32_t z, uint32_t j) {
    if (j < 16) {
        return x ^ y ^ z;
    } else {
        return (x & y) | ((~x) & z);
    }
}

// 置换函数
static inline uint32_t P0(uint32_t x) {
    return x ^ LEFT_ROTATE(x, 9) ^ LEFT_ROTATE(x, 17);
}

static inline uint32_t P1(uint32_t x) {
    return x ^ LEFT_ROTATE(x, 15) ^ LEFT_ROTATE(x, 23);
}

@implementation SM3Encryptor {
    uint32_t _state[8];   // 哈希状态
    uint64_t _count;      // 消息长度（位）
    uint8_t _buffer[64];  // 消息缓冲区
}

+ (instancetype)encryptor {
    return [[SM3Encryptor alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self reset];
    }
    return self;
}

- (void)reset {
    // 初始值 IV
    _state[0] = 0x7380166F;
    _state[1] = 0x4914B2B9;
    _state[2] = 0x172442D7;
    _state[3] = 0xDA8A0600;
    _state[4] = 0xA96F30BC;
    _state[5] = 0x163138AA;
    _state[6] = 0xE38DEE4D;
    _state[7] = 0xB0FB0E4E;
    
    _count = 0;
    memset(_buffer, 0, SM3_BLOCK_SIZE);
}

- (void)updateWithData:(NSData *)data {
    const uint8_t *bytes = (const uint8_t *)data.bytes;
    NSUInteger length = data.length;
    
    // 更新消息长度
    _count += length * 8;
    
    // 处理缓冲区中的剩余数据
    NSUInteger index = 0;
    NSUInteger bufferSize = _count % SM3_BLOCK_SIZE;
    
    if (bufferSize > 0) {
        NSUInteger freeSpace = SM3_BLOCK_SIZE - bufferSize;
        NSUInteger copyLength = MIN(length, freeSpace);
        
        memcpy(_buffer + bufferSize, bytes, copyLength);
        index += copyLength;
        
        if (bufferSize + copyLength == SM3_BLOCK_SIZE) {
            [self processBlock:_buffer];
        }
    }
    
    // 处理完整的消息块
    while (index + SM3_BLOCK_SIZE <= length) {
        [self processBlock:bytes + index];
        index += SM3_BLOCK_SIZE;
    }
    
    // 保存剩余数据到缓冲区
    if (index < length) {
        memcpy(_buffer, bytes + index, length - index);
    }
}

- (void)processBlock:(const uint8_t *)block {
    // 消息扩展
    uint32_t w[68];
    uint32_t ww[64];
    
    for (int i = 0; i < 16; i++) {
        w[i] = CFSwapInt32BigToHost(*(uint32_t *)(block + i * 4));
    }
    
    for (int j = 16; j < 68; j++) {
        w[j] = P1(w[j-16] ^ w[j-9] ^ LEFT_ROTATE(w[j-3], 15))
                ^ LEFT_ROTATE(w[j-13], 7)
                ^ w[j-6];
    }
    
    for (int j = 0; j < 64; j++) {
        ww[j] = w[j] ^ w[j+4];
    }
    
    // 压缩函数
    uint32_t A = _state[0];
    uint32_t B = _state[1];
    uint32_t C = _state[2];
    uint32_t D = _state[3];
    uint32_t E = _state[4];
    uint32_t F = _state[5];
    uint32_t G = _state[6];
    uint32_t H = _state[7];
    
    for (int j = 0; j < 64; j++) {
        uint32_t SS1 = LEFT_ROTATE((LEFT_ROTATE(A, 12) + E + LEFT_ROTATE(0x79CC4519, j)), 7);
        uint32_t SS2 = SS1 ^ LEFT_ROTATE(A, 12);
        uint32_t TT1 = FF(A, B, C, j) + D + SS2 + ww[j];
        uint32_t TT2 = GG(E, F, G, j) + H + SS1 + w[j];
        
        D = C;
        C = LEFT_ROTATE(B, 9);
        B = A;
        A = TT1;
        H = G;
        G = LEFT_ROTATE(F, 19);
        F = E;
        E = P0(TT2);
    }
    
    // 更新状态
    _state[0] ^= A;
    _state[1] ^= B;
    _state[2] ^= C;
    _state[3] ^= D;
    _state[4] ^= E;
    _state[5] ^= F;
    _state[6] ^= G;
    _state[7] ^= H;
}

- (NSData *)computeHash {
    // 计算填充
    uint64_t bitLength = _count;
    uint64_t index = bitLength % SM3_BLOCK_SIZE;
    
    // 添加填充: 1 bit + 0 bits + 64-bit length
    uint8_t padding[64] = {0x80};
    NSInteger paddingLength = (index < 56) ? (56 - index) : (120 - index);
    
    // 添加长度
    uint64_t lengthBits[2] = {0, CFSwapInt64HostToBig(bitLength)};
    padding[paddingLength] = (lengthBits[1] >> 56) & 0xFF;
    padding[paddingLength+1] = (lengthBits[1] >> 48) & 0xFF;
    padding[paddingLength+2] = (lengthBits[1] >> 40) & 0xFF;
    padding[paddingLength+3] = (lengthBits[1] >> 32) & 0xFF;
    padding[paddingLength+4] = (lengthBits[1] >> 24) & 0xFF;
    padding[paddingLength+5] = (lengthBits[1] >> 16) & 0xFF;
    padding[paddingLength+6] = (lengthBits[1] >> 8) & 0xFF;
    padding[paddingLength+7] = (lengthBits[1]) & 0xFF;
    
    // 处理填充
    [self updateWithData:[NSData dataWithBytes:padding length:paddingLength + 8]];
    
    // 获取最终哈希值
    NSMutableData *digest = [NSMutableData dataWithLength:SM3_DIGEST_SIZE];
    uint32_t *digestBytes = (uint32_t *)digest.mutableBytes;
    
    for (int i = 0; i < 8; i++) {
        digestBytes[i] = CFSwapInt32HostToBig(_state[i]);
    }
    
    // 重置状态
    [self reset];
    
    return digest;
}

+ (NSString *)sm3HashWithString:(NSString *)input {
    NSData *inputData = [input dataUsingEncoding:NSUTF8StringEncoding];
    return [self sm3HashWithData:inputData];
}

+ (NSString *)sm3HashWithData:(NSData *)data {
    SM3Encryptor *sm3 = [SM3Encryptor encryptor];
    [sm3 updateWithData:data];
    NSData *digest = [sm3 computeHash];
    
    // 转换为十六进制字符串
    const unsigned char *bytes = (const unsigned char *)digest.bytes;
    NSMutableString *hexString = [NSMutableString stringWithCapacity:digest.length * 2];
    
    for (NSInteger i = 0; i < digest.length; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    
    return [hexString copy];
}

@end
