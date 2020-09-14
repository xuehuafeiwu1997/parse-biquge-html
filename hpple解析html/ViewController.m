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
#import "Book.h"

@interface ViewController ()

@property(nonatomic, strong) NSMutableArray *chapterArr;
@property(nonatomic, copy) NSString *path;
@property(nonatomic, strong) Book *book;
@property(nonatomic, strong) UIButton *saveButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.saveButton.center = self.view.center;
    [self.view addSubview:self.saveButton];
    
    self.chapterArr = [NSMutableArray array];
    self.path = [FCFileManager pathForLibraryDirectoryWithPath:@"Novel"];
    self.book = [[Book alloc] init];
    
    [self parseNovelCatalog];
}

//解析小说的章节目录
- (void)parseNovelCatalog {
    NSURL *url = [NSURL URLWithString:@"http://www.xbiquge.la/19/885"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    self.book.url = url;
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:data];
    TFHppleElement *hppleElement = [hpple peekAtSearchWithXPathQuery:@"//h1"];
    self.book.bookName = hppleElement.text;
    NSLog(@"当前小说的名称为:%@",hppleElement.text);
    [self createNovelNameDictionaryIfNotExist:hppleElement.text];
    
    NSArray *elements = [hpple searchWithXPathQuery:@"//dd"];
    for (int i = 0; i < elements.count; i++) {
        TFHppleElement *element = [elements objectAtIndex:i];
        NSLog(@"%@",[element objectForKey:@"href"]);
        NSArray *childrenElements = [element childrenWithTagName:@"a"];
        NSLog(@"%@",childrenElements);
        for (TFHppleElement *e in childrenElements) {
            NSDictionary *dict = e.attributes;
            Chapter *chapter = [[Chapter alloc] init];
            chapter.chapterId = i + 1;
            if (dict[@"title"]) {
                chapter.chapterName = dict[@"title"];
            }
            if (dict[@"href"]) {
                chapter.chapterUrlString = dict[@"href"];
            }
            [self.chapterArr addObject:chapter];
        }
    }
    NSLog(@"所有的章节为:%@",self.chapterArr);
}

- (void)saveNovel {
    if ([self.chapterArr count] == 0) {
        NSLog(@"章节目录解析失败");
        return;
    }
    for (int i = 0; i < 100; i++) {
        Chapter *chapter = [self.chapterArr objectAtIndex:i];
        @synchronized (chapter) {
            [self getCorrespondedDataByChapter:chapter];
        }
    }
}

- (void)parseHtmlByUrl:(NSURL *)url {
    NSData *data = [NSData dataWithContentsOfURL:url];
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:data];
    TFHppleElement *element = [hpple peekAtSearchWithXPathQuery:@"//h1"];
    NSLog(@"章节的名称为:%@",element.text);
    
    NSArray *elements = [hpple searchWithXPathQuery:@"//div"];
    NSLog(@"当前网页总的节点数:%ld",elements.count);
    for (int i = 0; i < elements.count; i++) {
        TFHppleElement *e = [elements objectAtIndex:i];
        if ([[[e attributes] objectForKey:@"id"] isEqualToString:@"content"]) {
            //这里进入的是笔趣阁的content字段
            NSString *content = [e.raw copy];
            content = [self filterSepcialSymbol:content];
            NSLog(@"过滤后的字符串的内容为:%@",content);
            [self writeToFileByContent:content WithTitle:element.text];
            NSLog(@"----------第14章的内容输出完毕---------");
        }
    }
}

- (void)getCorrespondedDataByChapter:(Chapter *)chapter {
    if (chapter == nil) {
        NSLog(@"解析html网页出现错误");
        return;
    }
    self.book.url = [NSURL URLWithString:@"http://www.xbiquge.la"];
    NSURL *url = [self.book.url URLByAppendingPathComponent:chapter.chapterUrlString];
    [[[self session] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *receiver = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSData *receiverData = [receiver dataUsingEncoding:NSUTF8StringEncoding];
        [self parseHtmlByChapter:chapter WithData:receiverData];
    }] resume];
}

- (void)parseHtmlByChapter:(Chapter *)chapter WithData:(NSData *)data {
//    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"我师兄实在是太稳健了" ofType:@"html"]];
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:data];
//    /*
//     这里也可以使用chapter中传进来的name,这里对每个传进来的网页都进行解析
//     */
    NSArray *array = [hpple searchWithXPathQuery:@"//h1"];//为了获取到title的标题
    for (TFHppleElement *hppleElement in array) {
        NSLog(@"标题为%@",hppleElement.text);
        chapter.chapterName = hppleElement.text;
//        [self createNovelNameDictionaryIfNotExist:hppleElement.text];
    }
    NSArray *elements = [hpple searchWithXPathQuery:@"//div"];
    NSLog(@"当前网页总的节点数:%ld",elements.count);
    if (elements.count == 0) {
        NSLog(@"当前无法解析的章节的标题名为：%@",chapter.chapterName);
        NSArray *elementNew = [hpple searchWithXPathQuery:@"//div"];
    }
    for (int i = 0; i < elements.count; i++) {
        TFHppleElement *e = [elements objectAtIndex:i];
        if ([[[e attributes] objectForKey:@"id"] isEqualToString:@"content"]) {
            //这里进入的是笔趣阁的content字段
            NSString *content = [e.raw copy];
            content = [self filterSepcialSymbol:content];
            NSLog(@"过滤后的字符串的内容为:%@",content);
            [self writeToFileByContent:content WithTitle:chapter.chapterName];
            NSLog(@"----------第%ld章的内容输出完毕---------",(long)chapter.chapterId);
        }
//        NSLog(@"1 : %@",[e text]);
//        NSLog(@"2 : %@",[e tagName]);
//        NSLog(@"3 : %@",[e attributes]);
//        NSLog(@"4 : %@",[e objectForKey:@"href"]);
//        NSLog(@"5 : %@",[e firstChildWithTagName:@"meta"]);
//        NSLog(@"------完成对一个文件的解析--------");
    }
}

- (NSURL *)handleSplitUrl:(NSURL *)url {
    return nil;
}

- (NSString *)filterSepcialSymbol:(NSString *)content {
    content = [content stringByReplacingOccurrencesOfString:@"<br /><br />" withString:@"\n"];
    return content;
}

- (void)createNovelNameDictionaryIfNotExist:(NSString *)bookName {
    if (!bookName || bookName.length == 0) {
        return;
    }
    NSString *destinationPath = [self.path stringByAppendingPathComponent:bookName];
    NSLog(@"当前的沙盒存储地址为:%@",destinationPath);
    if ([FCFileManager existsItemAtPath:destinationPath]) {
        return;
    }
    NSError *error = nil;
    if (![FCFileManager createDirectoriesForPath:destinationPath error:&error]) {
        NSLog(@"Error create directories %@ , %@",destinationPath, error);
    }
    self.path = destinationPath;
}

- (void)writeToFileByContent:(NSString *)content WithTitle:(NSString *)title{
    NSString *fileName = [title stringByAppendingPathExtension:@"txt"];
    NSString *destinationPath = [self.path stringByAppendingPathComponent:fileName];
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

- (UIButton *)saveButton {
    if (_saveButton) {
        return _saveButton;
    }
    _saveButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    [_saveButton setTitle:@"转存小说" forState:UIControlStateNormal];
    [_saveButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _saveButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [_saveButton addTarget:self action:@selector(saveNovel) forControlEvents:UIControlEventTouchUpInside];
    return _saveButton;
}

#pragma mark - URLSession
- (NSURLSession *)session {
    static NSURLSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    });
    return session;
}

@end
