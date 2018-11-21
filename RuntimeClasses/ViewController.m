//
//  ViewController.m
//  RuntimeClasses
//
//  Created by menglingfeng on 2018/11/15.
//  Copyright © 2018 menglingfeng. All rights reserved.
//

#import "ViewController.h"
#import "ImageLoader.h"
#import "ProtocolExtension.h"

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

//- (void)fly{
//    NSLog(@"----------object implement fly-------");
//}
//
//
//- (void)jump{
//    NSLog(@"----------object implement jump-------");
//}


@end


@interface TestBird : NSObject <Test>

@end

@implementation TestBird

//- (void)fly{
//    NSLog(@"----------object implement fly-------");
//}
//
//
//- (void)jump{
//    NSLog(@"----------object implement jump-------");
//}


@end





@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSSet *customClasses = [ImageLoader customClassNames];
    NSLog(@"custom classes : %@ \n count: %ld \n", customClasses, customClasses.count);
    
    NSSet *allClasses = [ImageLoader allBundleClassNames];
    NSLog(@"all classes : %@ \n count: %ld \n", allClasses, allClasses.count);
    
    NSSet *mainBundleClasses = [ImageLoader mainBundleClassNames];
    NSLog(@"main bundle classes : %@ \n count: %ld \n", mainBundleClasses, mainBundleClasses.count);
    

    TestPerson *person = [[TestPerson alloc] init];
    [person jump];
    [person fly];
    
    
    TestBird *bird = [[TestBird alloc] init];
    [bird jump];
    [bird fly];

}


@end
