//
//  ViewController.m
//  testDemo
//
//  Created by wt on 2025/6/12.
//

#import "ViewController.h"
#import "SM3Encryptor.h"
//#import "GMObjC.h"
#import "GMObjC/GMObjC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *str = @"Abc@1234";
//    NSString *pw = [SM3Encryptor sm3HashWithString:str];
//    NSLog(@"%@", pw);
//    
//    NSString *digest = [GMSm3Utils hashWithText:str];
//    NSLog(@"%@", digest);
    
    NSString *digest1 = [GMSm3Utils hashWithText:str];
    NSLog(@"%@", digest1);
}


@end
