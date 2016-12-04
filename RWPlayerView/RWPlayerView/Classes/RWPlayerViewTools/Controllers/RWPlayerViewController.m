//
//  RWPlayerViewController.m
//  RWPlayerView
//
//  Created by 紫荆秋雪 on 16/12/4.
//  Copyright © 2016年 紫荆秋雪. All rights reserved.
//

#import "RWPlayerViewController.h"
#import "RWConst.h"

@interface RWPlayerViewController ()<RWPlayerViewDelegate>{
    RWPlayerView  *playerView;
    CGRect     playerFrame;
}

@end


@implementation RWPlayerViewController

/**
 *  隐藏状态栏
 *
 *  @return YES: 隐藏 NO：显示
 */
- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark ********** 1-系统生命周期 **********
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //隐藏导航条
    self.navigationController.navigationBarHidden = YES;
    //旋转屏幕通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rw_observerDeviceOrientationDidChangeNotification) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    self.navigationController.navigationBarHidden = NO;
    [super viewDidDisappear:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //加载视图
    //    [self setupUI];
}

#pragma mark ********** 1-1初始播放器 **********
- (void)setupUI {
    playerFrame = CGRectMake(0, 0, kScreenWidth, kScreenWidth * 3/4);
    
    playerView = [[RWPlayerView alloc] initWithFrame:playerFrame];
    playerView.rwPlayerViewDelegate = self;
    //背景颜色
    playerView.backgroundColor = [UIColor blackColor];
    //URL
    playerView.URLString = self.URLString;
    //    playerView.URLString = @"http://v1.mukewang.com/a45016f4-08d6-4277-abe6-bcfd5244c201/L.mp4";
    [self.view addSubview:playerView];
    [playerView play];
    
}

- (void)setupUIURL:(NSString *)urlString {
    playerFrame = CGRectMake(0, 0, kScreenWidth, kScreenWidth * 3/4);
    
    playerView = [[RWPlayerView alloc] initWithFrame:playerFrame];
    playerView.rwPlayerViewDelegate = self;
    //背景颜色
    playerView.backgroundColor = [UIColor whiteColor];
    //URL
    playerView.URLString = urlString;
    //    playerView.URLString = @"http://v1.mukewang.com/a45016f4-08d6-4277-abe6-bcfd5244c201/L.mp4";
    [self.view addSubview:playerView];
    [playerView play];
    
}

- (void)setURLString:(NSString *)URLString {
    _URLString = URLString;
    [self setupUIURL:URLString];
}

- (void)setTitleName:(NSString *)titleName {
    _titleName = titleName;
    playerView.titleName = titleName;
}


#pragma mark ********** 2-监听屏幕旋转 **********
/**
 *  旋转屏幕通知
 */
- (void)rw_observerDeviceOrientationDidChangeNotification {
    if (playerView == nil || playerView.superview == nil) {
        return;
    }
    
    //1、获取屏幕方向
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    //2、判断屏幕方向
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            NSLog(@"第3个旋转方向 -- 电池栏在下");
        }
            break;
        case UIInterfaceOrientationPortrait:
        {
            NSLog(@"第0个旋转方向 -- 电池栏在上");
            if (playerView.isFullscreen) {
                [self fullScreenToNormal];
            }
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:
        {
            NSLog(@"第2个旋转方向 -- 电池栏在左");
            playerView.isFullscreen = YES;
            [self setNeedsStatusBarAppearanceUpdate];
            [self normalToFullScreenWithInterfaceOrientation:interfaceOrientation];
        }
            break;
        case UIInterfaceOrientationLandscapeRight:
        {
            NSLog(@"第1个旋转方向 -- 电池栏在右");
            playerView.isFullscreen = YES;
            [self setNeedsStatusBarAppearanceUpdate];
            [self normalToFullScreenWithInterfaceOrientation:interfaceOrientation];
        }
            break;
            
        default:
            break;
    }
    
}




#pragma mark ********** 3-屏幕旋转方法 **********
#pragma mark 3-1、全屏方法
- (void)normalToFullScreenWithInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
    
    [playerView removeFromSuperview];
    playerView.transform = CGAffineTransformIdentity;
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {//向左
        playerView.transform = CGAffineTransformMakeRotation(-M_PI_2);
    } else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {//向右
        playerView.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    playerView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    playerView.playerLayer.frame = CGRectMake(0, 0, kScreenHeight, kScreenWidth);
    
    //重写布局
    //1、底部布局
    [playerView.bottomToolView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.top.mas_equalTo(kScreenWidth - 40);
        make.width.mas_equalTo(kScreenHeight);
    }];
    
    //2、顶部布局
    [playerView.topToolView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.left.equalTo(playerView).with.offset(0);
        make.width.mas_equalTo(kScreenHeight);
    }];
    
    //3、关闭按钮
    [playerView.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(playerView.topToolView).offset(5);
        make.height.mas_equalTo(30);
        make.top.mas_equalTo(playerView.topToolView.mas_top).offset(5);
        make.width.mas_equalTo(30);
    }];
    
    //4、title
    [playerView.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(playerView.topToolView.mas_left).offset(45);
        make.right.mas_equalTo(playerView.topToolView.mas_right).offset(-45);
        make.center.mas_equalTo(playerView.topToolView);
        make.top.mas_equalTo(playerView.topToolView.mas_top);
    }];
    
    //5、加载失败提示
    [playerView.loadFailedLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(kScreenHeight);
        make.center.mas_equalTo(CGPointMake(kScreenWidth / 2 - 36, -(kScreenWidth / 2) + 36));
        make.height.mas_equalTo(30);
    }];
    
    //6、菊花
    [playerView.loadingView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(CGPointMake(kScreenWidth / 2 - 37, -(kScreenWidth / 2) - 37));
    }];
    
    [self.view addSubview:playerView];
    playerView.fullScreenBtn.selected = YES;
    [playerView bringSubviewToFront:playerView.bottomToolView];
}
#pragma mark 3-2、非全屏方法
- (void)fullScreenToNormal {
    [playerView removeFromSuperview];
    
    [UIView animateWithDuration:0.5f animations:^{
        playerView.transform = CGAffineTransformIdentity;
        playerView.frame = CGRectMake(playerFrame.origin.x, playerFrame.origin.y, playerFrame.size.width, playerFrame.size.height);
        playerView.playerLayer.frame = playerView.bounds;
        [self.view addSubview:playerView];
        
        [playerView.bottomToolView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(playerView.mas_left);
            make.right.mas_equalTo(playerView.mas_right);
            make.height.mas_equalTo(40);
            make.bottom.mas_equalTo(playerView.mas_bottom);
        }];
        
        [playerView.topToolView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(playerView.mas_left);
            make.right.mas_equalTo(playerView.mas_right);
            make.height.mas_equalTo(40);
            make.top.mas_equalTo(playerView.mas_top);
        }];
        
        [playerView.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(playerView.topToolView.mas_left).offset(5);
            make.height.mas_equalTo(30);
            make.top.mas_equalTo(playerView.topToolView.mas_top).offset(5);
            make.width.mas_equalTo(30);
        }];
        
        [playerView.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(playerView.topToolView.mas_left).offset(45);
            make.right.mas_equalTo(playerView.topToolView.mas_right).offset(-45);
            make.center.mas_equalTo(playerView.topToolView);
            make.top.mas_equalTo(playerView.topToolView.mas_top);
        }];
        
        [playerView.loadFailedLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(playerView);
            make.width.mas_equalTo(playerView);
            make.height.mas_equalTo(30);
        }];
        
    } completion:^(BOOL finished) {
        playerView.isFullscreen = NO;
        [self setNeedsStatusBarAppearanceUpdate];
        playerView.fullScreenBtn.selected = NO;
    }];
}

#pragma mark ********** 4-RWPlayerDelegate代理方法 **********
#pragma mark 4-1、点击全屏按钮的代理方法
/**
 *  点击全屏按钮的代理方法
 */
- (void)rw_playerDelegate:(RWPlayerView *)rwPlayer fullScreenBtnClick:(UIButton *)fullScreenBtn {
    if (fullScreenBtn.isSelected) {//全屏显示
        playerView.isFullscreen = YES;
        [self setNeedsStatusBarAppearanceUpdate];
        
        //显示全屏
        [self normalToFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
    } else {
        [self fullScreenToNormal];
    }
}

#pragma mark 4-2、点击 播放/暂停 按钮的代理方法
/**
 *  点击 播放/暂停 按钮的代理方法
 */
- (void)rw_playerDelegate:(RWPlayerView *)rwPlayer playOrPauseBtnClick:(UIButton *)playOrPauseBtn {
    [MBProgressHUD showSuccessWithText:@"TODU__点击 播放/暂停"];
}

#pragma mark 4-3、单击手势代理方法
/**
 *  单击手势代理方法
 */
- (void)rw_playerDelegate:(RWPlayerView *)rwPlayer handleSingleTap:(UITapGestureRecognizer *)singleTap {
    [MBProgressHUD showSuccessWithText:@"TODU__单击手势代理方法"];
}

#pragma mark 4-4、双击手势代理方法
/**
 *  双击手势代理方法
 */
- (void)rw_playerDelegate:(RWPlayerView *)rwPlayer handleDoubleTap:(UITapGestureRecognizer *)doubleTap {
    [MBProgressHUD showSuccessWithText:@"TODU__双击手势代理方法"];
    
}

#pragma mark 4-5、关闭代理方法
/**
 *  关闭代理方法
 */
- (void)rw_playerDelegate:(RWPlayerView *)rwPlayer closeBtnClick:(UIButton *)closeBtn {
    [MBProgressHUD showSuccessWithText:@"TODU__关闭代理方法"];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark 4-6、准备播放代理方法
/**
 *  准备播放代理方法
 */
- (void)rw_playerReadyToPlay:(RWPlayerView *)rwplayer playerStatus:(RWPlayerViewState)state {
    [MBProgressHUD showSuccessWithText:@"TODU__双击手势代理方法"];
}

#pragma mark 4-7、播放失败代理方法
/**
 *  播放失败代理方法
 */
- (void)rw_playerFailedPlay:(RWPlayerView *)rwplayer playerStatus:(RWPlayerViewState)state {
    [MBProgressHUD showSuccessWithText:@"TODU__播放失败代理方法"];
}

#pragma mark 4-8、播放完成代理方法
/**
 *  播放完成代理方法
 */
-(void)rw_playerFinishedPlay:(RWPlayerView *)rwplayer {
    [MBProgressHUD showSuccessWithText:@"TODU__播放完成代理方法"];
}

#pragma mark ********** 5-delloc *********
- (void)dealloc {
    //清除播放器控制器
    [self releaseRWPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"PlayerViewController___dealloc");
}

#pragma mark ********** 6-清空播放器控制器 *********
- (void)releaseRWPlayer {
    //1、暂停播放器
    [playerView pause];
    //2、移除播放器
    [playerView removeFromSuperview];
    //3、移除播放器图层
    [playerView.playerLayer removeFromSuperlayer];
    //4、更换当前 Item
    [playerView.player replaceCurrentItemWithPlayerItem:nil];
    //5、
    playerView.player = nil;
    //6、
    playerView.currentItem = nil;
    //7、是否定时器
    [playerView removeToolsTimer];
    [playerView removeProgressTimer];
    //8、
    playerView.playerLayer = nil;
    playerView.playOrPauseBtn = nil;
    playerView = nil;
    
}

@end
