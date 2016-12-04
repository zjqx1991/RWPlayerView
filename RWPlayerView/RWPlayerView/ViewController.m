//
//  ViewController.m
//  RWPlayerView
//
//  Created by 紫荆秋雪 on 16/12/4.
//  Copyright © 2016年 紫荆秋雪. All rights reserved.
//

#import "ViewController.h"
#import "RWConst.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //创建播放按钮
    UIButton *playerButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    
    [playerButton setTitle:@"播放按钮" forState:UIControlStateNormal];
    [playerButton setBackgroundColor:[UIColor orangeColor]];
    [playerButton addTarget:self action:@selector(playerButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playerButton];
}

#pragma mark - 监听播放按钮
- (void)playerButtonClick:(UIButton *) playerBtn {
    RWPlayerViewController *playerVC = [[RWPlayerViewController alloc] init];
    playerVC.view.backgroundColor = [UIColor whiteColor];
    //视频链接
    playerVC.URLString = @"http://v1.mukewang.com/a45016f4-08d6-4277-abe6-bcfd5244c201/L.mp4";
    playerVC.titleName = @"播放视频__title";
    [self presentViewController:playerVC animated:YES completion:^{
        
    }];
}

@end
