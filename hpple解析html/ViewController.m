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

NSString *const WriteChapterSuccessNotification = @"WriteChapterSuccessNotification";

@interface ViewController ()

@property(nonatomic, strong) NSMutableArray *chapterArr;
@property(nonatomic, copy) NSString *path;
@property(nonatomic, strong) Book *book;
@property(nonatomic, strong) UIButton *saveButton;
@property(nonatomic, copy) NSString *str;

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
    [self addObserve];
    
    self.str = @"http://www.biquge.info/74_74132/";
    NSURL *url = [NSURL URLWithString:self.str];
//    NSURL *url = [NSURL URLWithString:@"http://m.biquges.com/5_39148/"];
    [[[self session] dataTaskWithRequest:[self getRequestByUrl:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                NSLog(@"网络请求失败，失败的原因是%@",error);
                return;
            }
        NSString *receiver = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSData *receiverData = [receiver dataUsingEncoding:NSUTF8StringEncoding];
        
        //获得的是待验证的字符串，需要做的是将返回的href放入到原本的url中重新请求
        if (![self isNormalHtmlData:receiverData]) {
            [self hanleHtmlDataAndRequestAgain:receiverData];
            return;
        }
        
            [self parseNovelCatalogWithData:receiverData withUrl:url];
        }] resume];
//    [[[self session] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//            if (error) {
//                NSLog(@"网络请求失败，失败的原因是%@",error);
//                return;
//            }
//        NSString *receiver = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSData *receiverData = [receiver dataUsingEncoding:NSUTF8StringEncoding];
//            [self parseNovelCatalogWithData:receiverData withUrl:url];
//        }] resume];
    
//    [self parseHtmlByUrl:[NSURL URLWithString:@"http://www.biquge.info/74_74132/14482860.html?skvmdm=kfwye2&cijkry=k1yuj3"]];
}

- (void)hanleHtmlDataAndRequestAgain:(NSData *)data {
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:data];
    TFHppleElement *hppleElement = [hpple peekAtSearchWithXPathQuery:@"//a"];
    NSString *parameters = [hppleElement objectForKey:@"href"];
    if (parameters == nil) {
        NSLog(@"网页地址不是相应的带验证参数");
        return;
    }
    NSArray *arr = [parameters componentsSeparatedByString:@"/"];
    NSString *parameter = arr.lastObject;
    self.str = [self.str stringByAppendingFormat:@"%@", parameter];
    NSURL *url = [NSURL URLWithString:self.str];
    NSLog(@"当前的initStr为%@",self.str);
    [[[self session] dataTaskWithRequest:[self getRequestByUrl:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"当前的网络请求出错，出错的原因为%@",error);
            return;
        }
        NSString *receiver = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSData *receiverData = [receiver dataUsingEncoding:NSUTF8StringEncoding];
        if (![self isNormalHtmlData:receiverData]) {
            //如果获得的仍然是请求参数，继续请求，直到获得我们想要的网页的html地址为止
            [self hanleHtmlDataAndRequestAgain:receiverData];
            return;
        }
        [self parseNovelCatalogWithData:receiverData withUrl:url];
    }]resume] ;
}

- (BOOL)isNormalHtmlData:(NSData *)data {
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:data];
    TFHppleElement *hppleElement = [hpple peekAtSearchWithXPathQuery:@"//h1"];
    if (hppleElement.text == nil) {
        return NO;
    }
    return YES;
}

- (void)addObserve {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WriteFileBySignleThread:) name:WriteChapterSuccessNotification object:nil];
}

- (void)WriteFileBySignleThread:(NSNotification *)notification {
    NSInteger index = [notification.userInfo[@"chapterId"] integerValue];
    if (index >= self.chapterArr.count - 1) {
        return;
    }
    Chapter *chapter = [self.chapterArr objectAtIndex:index];
    [self getCorrespondedDataByChapter:chapter];
}

//解析小说的章节目录
- (void)parseNovelCatalogWithData:(NSData *)data withUrl:(NSURL *)url {
//    NSURL *url = [NSURL URLWithString:@"https://www.biquge11.com/0_825/"];//一念永恒
//    NSURL *url = [NSURL URLWithString:@"http://www.biquge.info/74_74132/?kkzqfa=kf0pk3&uirspm=k1sx03"];//我师兄实在是太稳健了
    //这里出错，主要是因为NSData在请求基于网络的url时会报错，这个方法只适用于小文件转换为NSData，大文件需要使用另外的方法，对于网络上的请求，我们需要使用dataTask
    
//    NSData *data = [NSData dataWithContentsOfURL:url];
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
    Chapter *chapter = [self.chapterArr objectAtIndex:0];
    [self getCorrespondedDataByChapter:chapter];
//    for (int i = 0; i < self.chapterArr.count; i++) {
//        Chapter *chapter = [self.chapterArr objectAtIndex:i];
//        [self getCorrespondedDataByChapter:chapter];
//    }
}

- (void)getCorrespondedDataByChapter:(Chapter *)chapter {
    if (chapter == nil) {
        NSLog(@"解析html网页出现错误");
        return;
    }
//    self.book.url = [NSURL URLWithString:@"http://www.xbiquge.la"];
    NSURL *url = [self.book.url URLByAppendingPathComponent:chapter.chapterUrlString];
    [[[self session] dataTaskWithRequest:[self getRequestByUrl:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                NSLog(@"网络请求失败的原因为%@",error);
            }
            NSString *receiver = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSData *receiverData = [receiver dataUsingEncoding:NSUTF8StringEncoding];
            [self parseHtmlByChapter:chapter WithData:receiverData];
            }] resume];
//    [[[self session] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        if (error) {
//            NSLog(@"网络请求失败的原因为%@",error);
//        }
//        NSString *receiver = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSData *receiverData = [receiver dataUsingEncoding:NSUTF8StringEncoding];
//        [self parseHtmlByChapter:chapter WithData:receiverData];
//    }] resume];
}

- (void)parseHtmlByChapter:(Chapter *)chapter WithData:(NSData *)data {
    TFHpple *hpple = [[TFHpple alloc] initWithHTMLData:data];
//    /*
//     这里也可以使用chapter中传进来的name,这里对每个传进来的网页都进行解析
//     */
    NSArray *array = [hpple searchWithXPathQuery:@"//h1"];//为了获取到title的标题
    for (TFHppleElement *hppleElement in array) {
        NSLog(@"标题为%@",hppleElement.text);
        chapter.chapterName = hppleElement.text;
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
            [self writeToFileByContent:content WithTitle:chapter.chapterName WithId:chapter.chapterId];
            NSLog(@"----------第%ld章的内容输出完毕---------",(long)chapter.chapterId);
            return;
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

- (void)createNovelNameDictionaryIfNotExist:(NSString *)bookName {
    if (!bookName || bookName.length == 0) {
        return;
    }
    NSString *destinationPath = [self.path stringByAppendingPathComponent:bookName];
    NSLog(@"当前的沙盒存储地址为:%@",destinationPath);
    if ([FCFileManager existsItemAtPath:destinationPath]) {
        self.path = destinationPath;
        return;
    }
    NSError *error = nil;
    if (![FCFileManager createDirectoriesForPath:destinationPath error:&error]) {
        NSLog(@"Error create directories %@ , %@",destinationPath, error);
    }
    self.path = destinationPath;
}

- (void)writeToFileByContent:(NSString *)content WithTitle:(NSString *)title WithId:(NSInteger)chapterId{
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
    [[NSNotificationCenter defaultCenter] postNotificationName:WriteChapterSuccessNotification object:nil userInfo:@{@"chapterId":@(chapterId)}];
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
- (NSMutableURLRequest *)getRequestByUrl:(NSURL *)url {
    //设置不使用本地缓存的策略
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPShouldHandleCookies:YES];
    [request addValue:@"BDUSS_BFESS=p1ZDQ0S1JBVmdiWU5rYTBsNWp-SHVNMnU1dWQ4Nnd3UmFuNGRFemFQU1NJdDVmRVFBQUFBJCQAAAAAAAAAAAEAAAD97j6BeHVlaHVhZmVpd3U5NwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKVtl-SlbZfSX; BAIDUID_BFESS=5CCFBFCB4D4E22DE15B993ABAA502328:SL=0:NR=10:FG=1" forHTTPHeaderField:@"Cookie"];
    [request addValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
    //添加host字段，网络请求会超时，目前还不知道为什么
//    [request addValue:@"www.biquge.info" forHTTPHeaderField:@"Host"];
    return request;
}

- (NSURLSession *)session {
    static NSURLSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        //手机端的user-agent
//        configuration.HTTPAdditionalHeaders = @{
//            @"User-Agent": @"Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/87.0.4280.77 Mobile/15E148 Safari/604.1"};
        //电脑端的user-agent
//        configuration.HTTPAdditionalHeaders = @{
//            @"User-Agent":@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36"
//        };
        session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    });
    return session;
}

//根据某一章节的网址解析（主要用于测试）
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
            [self writeToFileByContent:content WithTitle:element.text WithId:i];
            NSLog(@"----------第14章的内容输出完毕---------");
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
