//
//  ViewController.m
//  hpple解析html
//
//  Created by 许明洋 on 2020/8/20.
//  Copyright © 2020 许明洋. All rights reserved.
//

#import "ViewController.h"
#import "TFHpple.h"
#import "FCFileManager.h"
#import "Chapter.h"

@interface ViewController ()

@property(nonatomic, strong) NSMutableArray *chapterArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor yellowColor];
    self.chapterArr = [NSMutableArray array];
    [self parseHtml];
}

- (void)parseHtml {
//    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"我师兄实在是太稳健了目录" ofType:@"html"]];
    NSURL *url = [NSURL URLWithString:@"http://www.biquge.info/74_74132/14482860.html"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:data];
    NSArray *array = [hpple searchWithXPathQuery:@"//title"];//为了获取到title的标题
    for (TFHppleElement *hppleElement in array) {
        NSLog(@"标题为%@",hppleElement.text);
    }
    
    NSArray *elements = [hpple searchWithXPathQuery:@"//div"];
    NSLog(@"当前网页总的节点数:%ld",elements.count);
    for (int i = 0; i < elements.count; i++) {
        TFHppleElement *e = [elements objectAtIndex:i];
        if ([[[e attributes] objectForKey:@"id"] isEqualToString:@"content"]) {
            //这里进入的是笔趣阁的content字段
            NSString *content = [e.raw copy];
            content = [self filterSepcialSymbol:content];
            NSLog(@"过滤后的字符串的内容为:%@",content);
            [self writeToFileByContent:content];
            NSLog(@"第一章的内容输出完毕");
        }
//        NSLog(@"1 : %@",[e text]);
//        NSLog(@"2 : %@",[e tagName]);
//        NSLog(@"3 : %@",[e attributes]);
//        NSLog(@"4 : %@",[e objectForKey:@"href"]);
//        NSLog(@"5 : %@",[e firstChildWithTagName:@"meta"]);
//        NSLog(@"------完成对一个文件的解析--------");
    }
}

- (NSString *)filterSepcialSymbol:(NSString *)content {
    content = [content stringByReplacingOccurrencesOfString:@"<br /><br />" withString:@"\n"];
    return content;
}

- (void)writeToFileByContent:(NSString *)content {
    NSString *path = [[NSString stringWithFormat:@"/Users/xumingyang/Desktop/"] stringByAppendingPathComponent:@"Novel"];
    
//    NSError *error1 = nil;
//    [FCFileManager createDirectoriesForPath:path error:&error1];
//    if (error1) {
//        NSLog(@"创建文件夹失败的原因是:%@",error1);
//    }
    NSString *destinationPath = [path stringByAppendingPathComponent:@"novel.txt"];
    if (![FCFileManager existsItemAtPath:destinationPath]) {
        NSError *err = nil;
        [FCFileManager createFileAtPath:destinationPath error:&err];
        if (err) {
            NSLog(@"创建小说txt失败的原因是:%@",err);
        } else {
            NSLog(@"小说文件创建成功");
        }
    }
    NSError *error = nil;
    [content writeToFile:destinationPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"写入文件失败的原因是%@",error);
    }
}

@end
