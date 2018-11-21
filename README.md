## OC Runtime 获取各种类名(真机环境)

+ 获取mainBundle中自定义的类名
+ 获取整个workspace(包含各种三方库)中自定义的类名
+ 获取运行时所有的类

## OC Runtime 添加协议扩展方法默认实现(类Swift protocol extension)

```
@protocol Test <NSObject>

- (void)jump;

- (void)fly;

@end

@extension(Test)

- (void)jump{
    NSLog(@"%@ jump ----", [self classForCoder]);
}

- (void)fly{
    NSLog(@"%@ fly ----", [self classForCoder]);
}

@extEnd


@interface TestPerson : NSObject <Test>

@end

@implementation TestPerson

@end


TestPerson *person = [[TestPerson alloc] init];
[person jump];
[person fly];

控制台输出

2018-11-21 16:32:58.930 RuntimeClasses[1602:317354] TestPerson jump ----
2018-11-21 16:32:58.930 RuntimeClasses[1602:317354] TestPerson fly ----


```