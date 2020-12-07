//
//  TestViewController.m
//  hpple解析html
//
//  Created by 许明洋 on 2020/12/7.
//  Copyright © 2020 许明洋. All rights reserved.
//

#import "TestViewController.h"
#import "TFHpple.h"

@interface TestViewController ()


@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    self.title = @"测试返回出错的解析";
    
    [self beginParseHtml];
}


- (void)beginParseHtml {
    NSLog(@"开始解析html数据");
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"]];
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:data];
    TFHppleElement *hppleElement = [hpple peekAtSearchWithXPathQuery:@"//a"];
    NSLog(@"%@",[hppleElement objectForKey:@"href"]);
    NSString *parameter = [hppleElement objectForKey:@"href"];
    NSArray *arr = [parameter componentsSeparatedByString:@"/"];
    NSLog(@"分割后的字符串为%@",arr.lastObject);
}

@end
