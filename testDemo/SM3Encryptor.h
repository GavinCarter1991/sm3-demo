//
//  SM3Encryptor.h
//  testDemo
//
//  Created by wt on 2025/6/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SM3Encryptor : NSObject

+ (NSString *)sm3HashWithString:(NSString *)input;
+ (NSString *)sm3HashWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
