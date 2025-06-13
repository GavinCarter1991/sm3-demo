//
//  ViewController.m
//  testDemo
//
//  Created by wt on 2025/6/12.
//

#import "ViewController.h"
#import "GMObjC.h"
//#import "GMObjC/GMObjC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *str = @"Abc@1234";
    NSString *digest = [GMSm3Utils hashWithText:str];
    NSLog(@"%@", digest);
}


@end
