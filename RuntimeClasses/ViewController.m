//
//  ViewController.m
//  RuntimeClasses
//
//  Created by menglingfeng on 2018/11/15.
//  Copyright © 2018 menglingfeng. All rights reserved.
//

#import "ViewController.h"
#import "ImageLoader.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSSet *customClasses = [ImageLoader customClassNames];
    NSLog(@"custom classes : %@  count: %ld \n", customClasses, customClasses.count);
    
    NSSet *allClasses = [ImageLoader allBundleClassNames];
    NSLog(@"all classes : %@  count: %ld \n", allClasses, allClasses.count);
    
    NSSet *mainBundleClasses = [ImageLoader mainBundleClassNames];
    NSLog(@"main bundle classes : %@  count: %ld \n", mainBundleClasses, mainBundleClasses.count);
}


@end
