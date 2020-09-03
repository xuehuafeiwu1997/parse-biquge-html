//
//  Chapter.h
//  hpple解析html
//
//  Created by 许明洋 on 2020/9/3.
//  Copyright © 2020 许明洋. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Chapter : NSObject

@property (nonatomic, assign) NSInteger chapterId;
@property (nonatomic, copy) NSString *chapterName;
@property (nonatomic, strong) NSURL *chapterUrl;

@end

NS_ASSUME_NONNULL_END
