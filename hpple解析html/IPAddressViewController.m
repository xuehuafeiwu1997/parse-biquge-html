//
//  IPAddressViewController.m
//  hpple解析html
//
//  Created by 许明洋 on 2020/12/8.
//  Copyright © 2020 许明洋. All rights reserved.
//

#import "IPAddressViewController.h"
#import "Masonry.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

@interface IPAddressViewController ()

@property (nonatomic, strong) UIButton *getIPButton;

@end

@implementation IPAddressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    self.title = @"尝试获取ip地址";
    
    [self.view addSubview:self.getIPButton];
    [self.getIPButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(self.view);
        make.width.greaterThanOrEqualTo(@0);
        make.height.greaterThanOrEqualTo(@0);
    }];
}

//只能获取wifi的ip地址，无法获取流量的ip地址
- (void)getIPAddress {
    NSLog(@"获取当前的ip地址");
    NSString *adress = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;//将结构体复制给副本temp_addr
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                if ([[NSString stringWithUTF8String:temp_addr ->ifa_name] isEqualToString:@"en0"]) {
                    adress = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr -> ifa_next;
        }
    }
    //free memory
    freeifaddrs(interfaces);
    NSLog(@"当前的ip地址为:%@",adress);
}

- (UIButton *)getIPButton {
    if (_getIPButton) {
        return _getIPButton;
    }
    _getIPButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
    [_getIPButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_getIPButton setTitle:@"获取当前的ip地址" forState:UIControlStateNormal];
    [_getIPButton addTarget:self action:@selector(getIPAddress) forControlEvents:UIControlEventTouchUpInside];
    return _getIPButton;
}

@end
