//
//  RWPlayerView.h
//  RWPlayerView
//
//  Created by 紫荆秋雪 on 16/12/4.
//  Copyright © 2016年 紫荆秋雪. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MediaPlayer;
@import AVFoundation;
@import UIKit;
@class RWPlayerView;


// 播放器的几种状态
typedef NS_ENUM(NSInteger, RWPlayerViewState) {
    RWPlayerViewStateFailed,        // 播放失败
    RWPlayerViewStateBuffering,     // 缓冲中
    RWPlayerViewStatusReadyToPlay,  //将要播放
    RWPlayerViewStatePlaying,       // 播放中
    RWPlayerViewStateStopped,        //暂停播放
    RWPlayerViewStateFinished       //播放完毕
};


// 枚举值，包含播放器左上角的关闭按钮的类型
typedef NS_ENUM(NSInteger, CloseBtnStyle){
    CloseBtnStylePop, //pop箭头<-
    CloseBtnStyleClose  //关闭（X）
};


@protocol RWPlayerViewDelegate <NSObject>

@optional
/**
 *  点击全屏按钮代理方法
 *
 *  @param RWPlayerViewView      播放器
 *  @param fullScreenBtn 全屏按钮
 */
- (void)rw_playerDelegate:(RWPlayerView *) RWPlayerViewView fullScreenBtnClick:(UIButton *) fullScreenBtn;

/**
 *  点击 播放/暂停 按钮
 *
 *  @param RWPlayerViewView       播放器
 *  @param playOrPauseBtn 播放/暂停 按钮
 */
- (void)rw_playerDelegate:(RWPlayerView *) RWPlayerViewView playOrPauseBtnClick:(UIButton *) playOrPauseBtn;

/**
 *  点击关闭按钮
 *
 *  @param RWPlayerViewView 播放器
 *  @param closeBtn 关闭按钮
 */
- (void)rw_playerDelegate:(RWPlayerView *)RWPlayerViewView closeBtnClick:(UIButton *)closeBtn;

/**
 *  单击 播放器界面
 *
 *  @param RWPlayerView  播放器
 *  @param singleTap 单击手势
 */
- (void)rw_playerDelegate:(RWPlayerView *)RWPlayerView handleSingleTap:(UITapGestureRecognizer *)singleTap;

/**
 *  双击 播放器界面
 *
 *  @param RWPlayerView  播放器
 *  @param doubleTap 双击手势
 */
- (void)rw_playerDelegate:(RWPlayerView *)RWPlayerView handleDoubleTap:(UITapGestureRecognizer *)doubleTap;

#pragma mark - 播放状态代理方法
/**
 *  准备播放的代理方法
 *
 *  @param RWPlayerView 播放器
 *  @param state    准备播放状态
 */
-(void)rw_playerReadyToPlay:(RWPlayerView *)RWPlayerView playerStatus:(RWPlayerViewState) state;

/**
 *  播放失败的代理方法
 *
 *  @param RWPlayerView 播放器
 *  @param state    播放失败状态
 */
-(void)rw_playerFailedPlay:(RWPlayerView *)RWPlayerView playerStatus:(RWPlayerViewState) state;

/**
 *  播放完毕的代理方法
 *
 *  @param RWPlayerView 播放器
 */
-(void)rw_playerFinishedPlay:(RWPlayerView *)RWPlayerView;


@end



@interface RWPlayerView : UIView
/**
 *  RWPlayerView代理方法
 */
@property (nonatomic, weak) id<RWPlayerViewDelegate> rwPlayerViewDelegate;

/**
 *  播放器player
 */
@property (nonatomic,retain ) AVPlayer *player;
/**
 *playerLayer,可以修改frame
 */
@property (nonatomic,retain ) AVPlayerLayer  *playerLayer;
/**
 *  当前播放的item
 */
@property (nonatomic, retain) AVPlayerItem   *currentItem;
/**
 *  设置播放视频的USRLString，可以是本地的路径也可以是http的网络路径
 */
@property (nonatomic,copy) NSString *URLString;
/**
 ＊  播放器状态
 */
@property (nonatomic, assign) RWPlayerViewState   state;

/**
 ＊  播放器左上角按钮的类型
 */
@property (nonatomic, assign) CloseBtnStyle   closeBtnStyle;

/**
 *  播放暂停按钮
 */
@property (nonatomic,retain ) UIButton *playOrPauseBtn;
/**
 *  底部操作工具栏
 */
@property (nonatomic,retain ) UIView *bottomToolView;
/**
 *  顶部操作工具栏
 */
@property (nonatomic,retain ) UIView *topToolView;

/**
 *  左上角关闭按钮
 */
@property (nonatomic,retain ) UIButton *closeBtn;
/**
 *  显示播放视频的title
 */
@property (nonatomic,strong) UILabel *titleLabel;

/**
 *  播放视频title
 */
@property (nonatomic, copy) NSString *titleName;
/**
 *  显示加载失败的UILabel
 */
@property (nonatomic,strong) UILabel *loadFailedLabel;

/**
 *  菊花（加载框）
 */
@property (nonatomic,strong) UIActivityIndicatorView *loadingView;

/**
 *  控制全屏的按钮
 */
@property (nonatomic,retain ) UIButton *fullScreenBtn;

/**
 *  BOOL值判断当前的状态
 */
@property (nonatomic,assign ) BOOL            isFullscreen;

#pragma mark 2- 方法
/**
 *  播放
 */
-(void)play;
/**
 *  暂停
 */
-(void)pause;
/**
 *  更新UI界面的定时器
 */
- (void)addProgressTimer;
/**
 *  移除UI界面的定时器
 */
- (void)removeProgressTimer;
/**
 *  工具条定时器
 */
- (void)addToolsTimer;
/**
 *  移除工具条的定时器
 */
- (void)removeToolsTimer;
@end

