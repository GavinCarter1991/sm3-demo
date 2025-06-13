//
//  ViewController.m
//  testDemo
//
//  Created by wt on 2025/6/12.
//

#import "ViewController.h"
#import "SM3Encryptor.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *hashStr = [SM3Encryptor hexStringWithInput:@"Abc@1234"];
    NSLog(@"%@", hashStr);
}

@end
