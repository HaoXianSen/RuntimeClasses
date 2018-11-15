//
//  ImageLoader.h
//  HIFrameworkDemo
//
//  Created by menglingfeng on 2018/11/15.
//  Copyright © 2018 menglingfeng. All rights reserved.
//  库加载管理

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageLoader : NSObject

/**
 获取所有库的路径 app下

 @return app下库的路径
 */
+ (NSArray *)allImagePaths;


/**
  获取所有开发者创建的类的名称 过滤 /System/Library  /usr/lib 系统库

 @return 类的名称集合
 */
+ (NSSet *)customClassNames;


/**
 获取所有bundle下运行时的类集合
 
 @return 类的名称集合
 */
+ (NSSet *)allBundleClassNames;


/**
 获取所有main bundle下运行时的类集合
 
 @return 类的名称集合
 */
+ (NSSet *)mainBundleClassNames;


@end

NS_ASSUME_NONNULL_END
