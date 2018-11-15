//
//  ImageLoader.m
//  HIFrameworkDemo
//
//  Created by menglingfeng on 2018/11/15.
//  Copyright © 2018 menglingfeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ImageLoader.h"
#include <mach-o/dyld.h>
#import <mach-o/ldsyms.h>
#include <vector>
#include <string>
#include <objc/runtime.h>
#import <dlfcn.h>


@implementation ImageLoader

static void AppendAllImagePaths(std::vector<std::string> & image_paths){
    uint32_t imageCount = _dyld_image_count();
    for(uint32_t imageIndex = 0; imageIndex < imageCount; ++imageIndex){
        const char * path = _dyld_get_image_name(imageIndex);
        image_paths.push_back(std::string(path));
    }
}


// 打印所有加载的macho path
+ (NSArray *)allImagePaths
{
    uint32_t imageCount = _dyld_image_count();
    NSMutableArray *allImagePaths = [NSMutableArray arrayWithCapacity:imageCount];
    std::vector<std::string> image_paths;
    AppendAllImagePaths(image_paths);
    for(auto path: image_paths){
//        NSLog(@"%s",path.c_str());
        [allImagePaths addObject:[NSString stringWithUTF8String:path.c_str()]];
    }
    
    return allImagePaths;
}


/**
 获取所有开发者创建的类的名称
 
 @return 类的名称集合
 */
+ (NSSet *)customClassNames
{
    NSMutableSet *customClassName = [NSMutableSet set];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (self BEGINSWITH %@ OR self BEGINSWITH %@)", @"/System/Library", @"/usr/lib"];
    
    NSArray *filteredBundlePaths = [[ImageLoader allImagePaths] filteredArrayUsingPredicate:predicate];
    
    
    for (NSString *bundlePath in filteredBundlePaths) {
        
        unsigned int classNamesCount = 0;    // 用 executablePath 获取当前 app image
        NSString *appImage = bundlePath;    // objc_copyClassNamesForImage 获取到的是 image 下的类，直接排除了系统的类
        
//        NSLog(@"executablePath : %@", appImage);
        
        const char **classNames = objc_copyClassNamesForImage([appImage UTF8String], &classNamesCount);
        if (classNames) {
            for (unsigned int i = 0; i < classNamesCount; i++) {
                const char *className = classNames[i];
                NSString *classNameString = [NSString stringWithUTF8String:className];
                [customClassName addObject:classNameString];
            }
            free(classNames);
        }
        
        
    }
    
    
    return customClassName;
}



+ (NSSet *)mainBundleClassNames
{
    NSMutableSet *resultSet = [NSMutableSet set];
    
    unsigned int classCount;
    const char **classes;
    Dl_info info;
    
    dladdr(&_mh_execute_header, &info);
    classes = objc_copyClassNamesForImage(info.dli_fname, &classCount);

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_apply(classCount, dispatch_get_global_queue(0, 0), ^(size_t index) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSString *className = [NSString stringWithCString:classes[index] encoding:NSUTF8StringEncoding];
        Class classType = NSClassFromString(className);
        [resultSet addObject:classType];
        dispatch_semaphore_signal(semaphore);
    });
    
    return resultSet.mutableCopy;
}



+ (NSSet *)allBundleClassNames
{
   NSMutableSet *resultSet = [NSMutableSet set];
    
    int classCount = objc_getClassList(NULL, 0);
    
    Class *classes = NULL;
    classes = (__unsafe_unretained Class *)malloc(sizeof(Class) *classCount);
    classCount = objc_getClassList(classes, classCount);
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    dispatch_apply(classCount, dispatch_get_global_queue(0, 0), ^(size_t index) {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        Class classType = classes[index];
        NSString *className = [[NSString alloc] initWithUTF8String: class_getName(classType)];
        [resultSet addObject:className];
        dispatch_semaphore_signal(semaphore);
    });
    
    free(classes);
    
    return resultSet.mutableCopy;
}



@end
