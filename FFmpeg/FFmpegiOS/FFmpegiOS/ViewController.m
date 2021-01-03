//
//  ViewController.m
//  FFmpegiOS
//
//  Created by zhangguangpeng on 2020/5/25.
//  Copyright © 2020 zhangguangpeng. All rights reserved.
//

#import "ViewController.h"

#include "test.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *recButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 50)];
    recButton.backgroundColor = [UIColor redColor];
    [recButton addTarget:self action:@selector(recAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:recButton];
    
  
}

- (void)recAction{
    rec_video();
}


@end
