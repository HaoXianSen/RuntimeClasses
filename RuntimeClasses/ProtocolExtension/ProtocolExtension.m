//
//  ProtocolExtension.m
//  RuntimeClasses
//
//  Created by menglingfeng on 2018/11/21.
//  Copyright © 2018 menglingfeng. All rights reserved.
//

/*
 大致思路：
 1. 宏定义每次c生成一个临时的class 实现某个协议
 2. 把每次生成的都实现同一个协议的class中协议扩展方法根据对象方法，类方法进行合并到一个结构体中
 3. runtime获取当前加载的所有的类
 4. 利用 __attribute__((constructor)) 把协议的对象扩展方法，类扩展方法注入到遵循某个协议的类中
 */


#import "ProtocolExtension.h"

#define LOCK(lock)     dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define UNLOCK(lock)   dispatch_semaphore_signal(lock);


//封装的C语言扩展协议结构体，用来保存实现某个协议的所有方法等
typedef struct{
    Protocol * __unsafe_unretained protocol;
    Method *instanceMethods; //保存的实现某个协议的所有对象的实例方法
    unsigned instanceMethodCount;
    Method *classMethods;    //保存的实现某个协议的所有对象的类方法
    unsigned classMethodCount;
}PEExtendedProtocol;

//load static library时的同步锁
static dispatch_semaphore_t loadingLock = NULL;
//用来扩容
static size_t extendedProtocolCount = 0, extenedProtocolCapacity = 0;
// 保存的所有协议c语言内存地址
static PEExtendedProtocol *allExtenedProtocols = NULL;


void lock(){
    
    if(loadingLock == NULL){
        loadingLock = dispatch_semaphore_create(1);
    }
    
    LOCK(loadingLock);
}


void unlock(){
    UNLOCK(loadingLock);
}

//把两个对象的方法合并
Method * _protocol_extension_merge_created(Method *existExtendedMethods, unsigned existExtendedMethodCount, Method *appendExtendedMethods, unsigned appendExtendedMethodCount){
    
    if(0 == existExtendedMethodCount){
        return appendExtendedMethods;
    }
    
    //申请一块内存
    unsigned mergedMethodCount = existExtendedMethodCount + appendExtendedMethodCount;
    Method *mergedMethods = malloc(mergedMethodCount * sizeof(Method));
    //内存复制到mergedMethods中
    memcpy(mergedMethods, existExtendedMethods, existExtendedMethodCount * sizeof(Method));
    memcpy(mergedMethods + existExtendedMethodCount, appendExtendedMethods, appendExtendedMethodCount * sizeof(Method));
    return mergedMethods;
}


void _protocol_extension_merge(PEExtendedProtocol *extendedProtocol, Class container_class){
    
    //对象方法
    unsigned appendInstanceMethodCount;
    //需要合并进去的方法列表
    Method *appendInstanceExtendedMethods = class_copyMethodList(container_class, &appendInstanceMethodCount);
    Method *mergedInstanceExtendedMethods = _protocol_extension_merge_created(extendedProtocol->instanceMethods, extendedProtocol->instanceMethodCount, appendInstanceExtendedMethods, appendInstanceMethodCount);
    
    free(extendedProtocol->instanceMethods);
    extendedProtocol->instanceMethods = mergedInstanceExtendedMethods;
    extendedProtocol->instanceMethodCount += appendInstanceMethodCount;
    
    //类方法
    unsigned appendClassMethodCount;
    //需要合并进去的方法列表
    Method *appendClassExtendedMethods = class_copyMethodList(object_getClass(container_class), &appendClassMethodCount);
    Method *mergedClassExtendedMethods = _protocol_extension_merge_created(extendedProtocol->classMethods, extendedProtocol->classMethodCount, appendClassExtendedMethods, appendClassMethodCount);
    
    free(extendedProtocol->classMethods);
    extendedProtocol->classMethods = mergedClassExtendedMethods;
    extendedProtocol->classMethodCount += appendClassMethodCount;
    
}



void _protocol_extension_load(Protocol *protocol, Class container_class){

    lock();
    
    //检测是否需要扩容
    if(extendedProtocolCount >= extenedProtocolCapacity){
        size_t newCapacity = 0;
        if(0 == extendedProtocolCount){
            newCapacity = 1;
        }else{
            newCapacity = extenedProtocolCapacity << 1; //每次扩大2倍
        }
        
        //重新申请内存
        void *newAllExtenedProtocols = realloc(allExtenedProtocols, newCapacity * sizeof(*allExtenedProtocols));
        if(!newAllExtenedProtocols){
            //申请失败
            NSLog(@"%@ 扩容申请内存失败", NSStringFromProtocol(protocol));
        }else{
            allExtenedProtocols = newAllExtenedProtocols;
        }
        
        extenedProtocolCapacity = newCapacity;
        
    }
    
    //查找是否已经有这个protocol
    size_t resultIndex = SIZE_T_MAX;
    for (size_t index = 0; index < extendedProtocolCount; index++) {
        if(protocol_isEqual(allExtenedProtocols[index].protocol, protocol)){
            resultIndex = index;
            break;
        }
    }
    
    //第一次没有找到创建空
    if(SIZE_T_MAX == resultIndex){
        
        //初始化PEExtendedProtocol
        allExtenedProtocols[extendedProtocolCount] = (PEExtendedProtocol){
            .protocol = protocol,
            .instanceMethods = NULL,
            .instanceMethodCount = 0,
            .classMethods = NULL,
            .classMethodCount = 0
        };
        resultIndex = extendedProtocolCount;
        extendedProtocolCount++;
        
    }
    
    //将遵循同一个协议的对象的方法合并放进PEExtendedProtocol
    _protocol_extension_merge(&(allExtenedProtocols[resultIndex]), container_class);

    unlock();
    
}

static void _protocol_extension_inject_to_class(Class targetClass, PEExtendedProtocol extendedProcol){
    
    //对象方法
    for (unsigned instanceMethodIndex = 0; instanceMethodIndex < extendedProcol.instanceMethodCount; instanceMethodIndex++) {
        Method instanceMethod = extendedProcol.instanceMethods[instanceMethodIndex];
        SEL selector = method_getName(instanceMethod);
        
        //判断方法是否存在
        if(class_getInstanceMethod(targetClass, selector)){
            continue;
        }
        
        IMP imp = method_getImplementation(instanceMethod);
        const char *type = method_getTypeEncoding(instanceMethod);
        class_addMethod(targetClass, selector, imp, type);
        
    }
    
    
    //类方法
    Class targetMetaClass = object_getClass(targetClass);
    for (unsigned classMethodIndex = 0; classMethodIndex < extendedProcol.classMethodCount; classMethodIndex++) {
        
        Method classMethod = extendedProcol.classMethods[classMethodIndex];
        SEL selector = method_getName(classMethod);
        
        //判断方法是否存在
        if(class_getInstanceMethod(targetMetaClass, selector)){
            continue;
        }
        
        if(sel_isEqual(selector, @selector(load)) || sel_isEqual(selector, @selector(initialize))){
            continue;
        }
        
        IMP imp = method_getImplementation(classMethod);
        const char *type = method_getTypeEncoding(classMethod);
        class_addMethod(targetMetaClass, selector, imp, type);
        
    }
    
}


//在main函数调用之前
//__attribute__((constructor)) static void _protocol_extension_inject_entry(){
//    
//    lock();
//    //获取当前内存中所有的类
//    unsigned count;
//    Class *allClasses = objc_copyClassList(&count);
//    
//    @autoreleasepool {
//        for (unsigned protocolIndex = 0; protocolIndex < extendedProtocolCount; protocolIndex++) {
//            PEExtendedProtocol extendProtocol = allExtenedProtocols[protocolIndex];
//            for (unsigned classIndex = 0; classIndex < count; classIndex++) {
//                Class class = allClasses[classIndex];
//                if(!class_conformsToProtocol(class, extendProtocol.protocol)){
//                    continue;
//                }
//                _protocol_extension_inject_to_class(class, extendProtocol);
//            }
//        }
//    }
//    
//    unlock();
//    
//    free(allClasses);
//    free(allExtenedProtocols);
//    extendedProtocolCount = 0;
//    extenedProtocolCapacity = 0;
//    loadingLock = NULL;
//    
//}










