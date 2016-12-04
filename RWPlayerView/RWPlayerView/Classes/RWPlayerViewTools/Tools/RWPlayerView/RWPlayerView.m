//
//  RWPlayerView.m
//  RWPlayerView
//
//  Created by 紫荆秋雪 on 16/12/4.
//  Copyright © 2016年 紫荆秋雪. All rights reserved.
//

#import "RWPlayerView.h"
#import "RWConst.h"


#define kScreenWidthHalf self.frame.size.width * 0.5
#define kScreenHeightHalf self.frame.size.height * 0.5


@interface RWPlayerView (){
    UISlider *systemSlider;
    UITapGestureRecognizer* singleTap;
}

@property (nonatomic,assign)CGPoint firstPoint;
@property (nonatomic,assign)CGPoint secondPoint;
@property (nonatomic, assign) CGPoint originalPoint;

/**
 *  显示播放时间的UILabel
 */
@property (nonatomic,strong) UILabel *leftTimeLabel;
@property (nonatomic,strong) UILabel *rightTimeLabel;

/**
 *  跳到time处播放
 *  @param seekTime这个时刻，这个时间点
 */
@property (nonatomic, assign) double  seekTime;

/**
 * 亮度的进度条
 */
@property (nonatomic,strong) UISlider *lightSlider;

/**
 *  音量进度条
 */
@property (nonatomic,strong) UISlider *volumeSlider;

/**
 *  播放进度条
 */
@property (nonatomic,strong) UISlider *progressSlider;

//视频进度条的单击事件
@property (nonatomic, strong) UITapGestureRecognizer *tap;

/**
 *  缓存进度条
 */
@property (nonatomic,strong) UIProgressView *loadingProgress;

/**
 *  工具条定时器
 */
@property (nonatomic, strong) NSTimer *toolsTimer;
/**
 *  刷新界面定时器
 */
@property (nonatomic, strong) NSTimer *progressTimer;

@end

static void *PlayViewStatusObservationContext = &PlayViewStatusObservationContext;


@implementation RWPlayerView
#pragma mark ********** 1- 初始化方法 *************
/**
 *  alloc init的初始化方法
 */
- (instancetype)init {
    self = [super init];
    if (self) {
        [self initRWplayer];
    }
    return self;
}

/**
 *  storyboard、xib的初始化方法
 */
- (void)awakeFromNib {
    [self initRWplayer];
}

/**
 *  initWithFrame的初始化方法
 */
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initRWplayer];
    }
    return self;
}

/**
 *  初始化WMPlayer的控件，添加手势，添加通知，添加kvo等
 */
- (void)initRWplayer {
    
    //防止在block中循环引用
    __unsafe_unretained __typeof(self) weakSelf = self;
    //0、设置背景颜色
    self.backgroundColor = [UIColor whiteColor];
    //1、设置seekTime播放时刻
    self.seekTime = 0.00;
    //2、小菊花
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    //UIActivityIndicatorViewStyleWhiteLarge,的尺寸是（37，37）
    //UIActivityIndicatorViewStyleWhite,的尺寸是（22，22）
    //UIActivityIndicatorViewStyleGray
    [self addSubview:self.loadingView];
    
    //小菊花开始动画
    [self.loadingView startAnimating];
    
    //1、小菊花
    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(weakSelf);
    }];
    
    //3、顶部操作工具栏
    self.topToolView = [[UIView alloc] init];
    
    self.topToolView.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.6];
    [self addSubview:self.topToolView];
    
    //3、顶部操作工具栏
    [self.topToolView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.height.mas_equalTo(40);
    }];
    
    //4、底部操作工具栏
    self.bottomToolView = [[UIView alloc] init];
    self.bottomToolView.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.6];
    [self addSubview:self.bottomToolView];
    
    //4、底部操作工具栏
    [self.bottomToolView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.right.mas_equalTo(0);
        make.height.mas_equalTo(40);
        make.bottom.mas_equalTo(0);
    }];
    
    
    //4-1、播放/暂停按钮
    self.playOrPauseBtn = [[UIButton alloc] init];
    self.playOrPauseBtn.showsTouchWhenHighlighted = YES;
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateSelected];
    //播放按钮添加播放事件
    [self.playOrPauseBtn addTarget:self action:@selector(playOrPauseBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomToolView addSubview:self.playOrPauseBtn];
    
    //4-1、播放按钮
    [self.playOrPauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(weakSelf.bottomToolView.mas_left);
        make.top.mas_equalTo(weakSelf.bottomToolView.mas_top);
        make.bottom.mas_equalTo(weakSelf.bottomToolView.mas_bottom);
        make.width.mas_equalTo(40);
    }];
    
    
    
    //5、亮度进度条
    self.lightSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.lightSlider.hidden = YES;
    self.lightSlider.minimumValue = 0.0;
    self.lightSlider.maximumValue = 1.0;
    //进度条的值等于当前系统亮度的值，范围都是0~1
    self.lightSlider.value = [UIScreen mainScreen].brightness;
    [self addSubview:self.lightSlider];
    
    
    
    
    //6、音量
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    //打开隐藏：系统音量显示
    //    [self addSubview:volumeView];
    volumeView.frame = CGRectMake(-1000, -100, 100, 100);
    [volumeView sizeToFit];
    systemSlider = [[UISlider alloc] init];
    systemSlider.backgroundColor = [UIColor clearColor];
    for (UIControl *view in volumeView.subviews) {
        if ([view.superclass isSubclassOfClass:[UISlider class]]) {
            systemSlider = (UISlider *)view;
        }
    }
    systemSlider.autoresizesSubviews = NO;
    systemSlider.autoresizingMask = UIViewAutoresizingNone;
    //打开隐藏：系统音量显示
    //    [self addSubview:systemSlider];
    
    
    
    /**
     *  音量进度条
     */
    self.volumeSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, -1000, 0, 0)];
    self.volumeSlider.tag = 1000;
    self.volumeSlider.hidden = YES;
    self.volumeSlider.minimumValue = systemSlider.minimumValue;
    self.volumeSlider.maximumValue = systemSlider.maximumValue;
    self.volumeSlider.value = systemSlider.value;
    //监听音量进度条
    [self.volumeSlider addTarget:self action:@selector(updateSystemVolumeValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.volumeSlider];
    
    
    //7、播放进度条
    self.progressSlider = [[UISlider alloc] init];
    self.progressSlider.backgroundColor = [UIColor redColor];
    self.progressSlider.minimumValue = 0.0;
    //进度条-滑块
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    //播放进度条颜色
    self.progressSlider.minimumTrackTintColor = [UIColor greenColor];
    self.progressSlider.maximumTrackTintColor = [UIColor clearColor];
    //指定初始值
    self.progressSlider.value = 0.0;
    
#warning 播放进度条
    //1、触摸到进度条
    [self.progressSlider addTarget:self action:@selector(progressSliderTouchDown:) forControlEvents:UIControlEventTouchDown];
    
    //2、播放进度条的拖拽事件
    [self.progressSlider addTarget:self action:@selector(valueChangeProgressSlider:) forControlEvents:UIControlEventValueChanged];
    
    //3、滑动结束
    [self.progressSlider addTarget:self action:@selector(progressSliderTouchUpInside:) forControlEvents:UIControlEventTouchCancel | UIControlEventTouchUpOutside | UIControlEventTouchUpInside];
    
    //给进度条添加单击手势
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTapGesture:)];
    [self.progressSlider addGestureRecognizer:self.tap];
    [self.bottomToolView addSubview:self.progressSlider];
    self.progressSlider.backgroundColor = [UIColor clearColor];
    
    
    //5、进度条
    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(45);
        make.right.mas_equalTo(-45);
        make.center.mas_equalTo(weakSelf.bottomToolView.center);
        //        make.height.mas_equalTo(1.0);
    }];
    
    
    
    //8、缓冲进度条
    self.loadingProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.loadingProgress.progressTintColor = [UIColor clearColor];
    //缓冲进度条的颜色
    self.loadingProgress.trackTintColor = [UIColor lightGrayColor];
    [self.bottomToolView addSubview:self.loadingProgress];
    [self.loadingProgress setProgress:0.0 animated:NO];
    
    //self.bottomView显示到最上面
    [self.bottomToolView sendSubviewToBack:self.loadingProgress];
    
    //6、缓冲进度条
    [self.loadingProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(weakSelf.progressSlider.mas_left);
        make.right.mas_equalTo(weakSelf.progressSlider.mas_right);
        make.centerY.mas_equalTo(weakSelf.progressSlider.mas_centerY).offset(1);
        make.height.mas_equalTo(1.5);
    }];
    
    
    //9、控制全屏的按钮
    self.fullScreenBtn = [[UIButton alloc] init];
    self.fullScreenBtn.showsTouchWhenHighlighted = YES;
    [self.fullScreenBtn addTarget:self action:@selector(fullScreenBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.fullScreenBtn setImage:[UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
    [self.fullScreenBtn setImage:[UIImage imageNamed:@"nonfullscreen"] forState:UIControlStateSelected];
    [self.bottomToolView addSubview:self.fullScreenBtn];
    
    //autoLayout fullScreenBtn
    [self.fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomToolView).with.offset(0);
        make.height.mas_equalTo(40);
        make.bottom.equalTo(self.bottomToolView).with.offset(0);
        make.width.mas_equalTo(40);
        
    }];
    
    //10、播放时间
    self.leftTimeLabel = [[UILabel alloc] init];
    self.leftTimeLabel.textAlignment = NSTextAlignmentLeft;
    self.leftTimeLabel.textColor = [UIColor whiteColor];
    self.leftTimeLabel.backgroundColor = [UIColor clearColor];
    self.leftTimeLabel.font = [UIFont systemFontOfSize:11.0];
    [self.bottomToolView addSubview:self.leftTimeLabel];
    
    //8、播放时间
    [self.leftTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(weakSelf.bottomToolView.mas_left).offset(45);
        make.right.mas_equalTo(weakSelf.bottomToolView.mas_right).offset(-45);
        make.height.mas_equalTo(20);
        make.bottom.mas_equalTo(weakSelf.bottomToolView.mas_bottom);
    }];
    
    
    //11、音频总时间
    self.rightTimeLabel = [[UILabel alloc] init];
    self.rightTimeLabel.textAlignment = NSTextAlignmentRight;
    self.rightTimeLabel.textColor = [UIColor whiteColor];
    self.rightTimeLabel.backgroundColor = [UIColor clearColor];
    self.rightTimeLabel.font = [UIFont systemFontOfSize:11.0];
    [self.bottomToolView addSubview:self.rightTimeLabel];
    
    //9、音频总时间
    [self.rightTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(weakSelf.bottomToolView.mas_left).offset(45);
        make.right.mas_equalTo(weakSelf.bottomToolView.mas_right).offset(-45);
        make.height.mas_equalTo(20);
        make.bottom.mas_equalTo(weakSelf.bottomToolView.mas_bottom);
    }];
    
#pragma mark - topToolView内容设置
    //12、左上角的关闭按钮
    self.closeBtn = [[UIButton alloc] init];
    [self.closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [self.closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    self.closeBtn.showsTouchWhenHighlighted = YES;
    [self.closeBtn addTarget:self action:@selector(closeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.topToolView addSubview:self.closeBtn];
    
    //10、关闭按钮
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(weakSelf.topToolView.mas_left).offset(5);
        make.height.mas_equalTo(30);
        make.top.mas_equalTo(weakSelf.topToolView.mas_top).offset(5);
        make.width.mas_equalTo(30);
    }];
    
    //13、显示播放视频的title
    self.titleLabel  = [[UILabel alloc] init];
    self.titleLabel.text = @"播放视频";
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.font = [UIFont systemFontOfSize:17.0];
    [self.topToolView addSubview:self.titleLabel];
    
    //11、音频标题
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(weakSelf.topToolView.mas_left).offset(45);
        make.right.mas_equalTo(weakSelf.topToolView).offset(-45);
        make.center.mas_equalTo(weakSelf.topToolView.center);
        make.top.mas_equalTo(weakSelf.topToolView.mas_top);
    }];
    
    
    //把 小菊花 加载到最上面
    [self bringSubviewToFront:self.loadingView];
    //把 底部工具条添加到最上面
    [self bringSubviewToFront:self.bottomToolView];
    
#pragma mark - 给Views添加单击时间
    [self addSingleTapGestureRecognizer];
#pragma mark - 添加通知
    [self addObserverRWPlayerNotification];
    //移除定时器
    [self removeProgressTimer];
    //添加定时器
    [self addProgressTimer];
    //移除定时器
    [self removeToolsTimer];
    //添加隐藏工具条定时器
    [self addToolsTimer];
}


- (void)addObserverRWPlayerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appwillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}



#pragma mark ********** 2-使用KVO来监听当前Item的状态 **********
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    //监听状态
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown:
            {
                [self.loadingProgress setProgress:0.0 animated:NO];
                self.state = RWPlayerViewStateBuffering;
                //开始菊花
                [self.loadingView startAnimating];
            }
                break;
                
            case AVPlayerStatusReadyToPlay:
            {
                self.state = AVPlayerStatusReadyToPlay;
                //添加双击
                [self addDoubleTapGestureRecognizer];
                
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                if (CMTimeGetSeconds(_currentItem.duration)) {
                    
                    double _x = CMTimeGetSeconds(_currentItem.duration);
                    if (!isnan(_x)) {
                        self.progressSlider.maximumValue = CMTimeGetSeconds(self.player.currentItem.duration);
                    }
                }
                //准备播放
                if (self.rwPlayerViewDelegate && [self.rwPlayerViewDelegate respondsToSelector:@selector(rw_playerReadyToPlay:playerStatus:)]) {
                    [self.rwPlayerViewDelegate rw_playerReadyToPlay:self playerStatus:AVPlayerStatusReadyToPlay];
                }
                
                [self.loadingView stopAnimating];
                //跳转xx
                if (self.seekTime) {
                    [self seekToTimeToPlay:self.seekTime];
                }
                
            }
                break;
                
            case AVPlayerStatusFailed:
            {
                self.state = RWPlayerViewStateFailed;
                
                //播放失败代理方法
                if (self.rwPlayerViewDelegate && [self.rwPlayerViewDelegate respondsToSelector:@selector(rw_playerFailedPlay:playerStatus:)]) {
                    [self.rwPlayerViewDelegate rw_playerFailedPlay:self playerStatus:RWPlayerViewStateFailed];
                }
                
                
                NSError *error = [self.player.currentItem error];
                if (error) {
                    self.loadFailedLabel.hidden = NO;
                    [self bringSubviewToFront:self.loadFailedLabel];
                    [self.loadingView stopAnimating];
                }
                NSLog(@"视频加载失败===%@",error.description);
            }
                break;
        }
        
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {//监听缓存
        // 计算缓冲进度
        NSTimeInterval timeInterval = [self availableDuration];
        CMTime duration             = self.currentItem.duration;
        CGFloat totalDuration       = CMTimeGetSeconds(duration);
        //缓冲颜色
        //            self.loadingProgress.progressTintColor = [UIColor redColor];
        self.loadingProgress.progressTintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7];
        [self.loadingProgress setProgress:timeInterval / totalDuration animated:NO];
        
        
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        //开始菊花
        [self.loadingView startAnimating];
        // 当缓冲是空的时候
        if (self.currentItem.playbackBufferEmpty) {
            self.state = RWPlayerViewStateBuffering;
            [self loadedTimeRanges];
        }
        
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        //菊花结束
        [self.loadingView stopAnimating];
        // 当缓冲好的时候
        if (self.currentItem.playbackLikelyToKeepUp && self.state == RWPlayerViewStateBuffering){
            self.state = RWPlayerViewStatePlaying;
        }
        
    }
    
    
}
/**
 *  跳到time处播放
 *  @param seekTime 这个时刻，这个时间点
 */
- (void)seekToTimeToPlay:(double)time{
    if (self.player&&self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        if (time>[self duration]) {
            time = [self duration];
        }
        if (time<=0) {
            time=0.0;
        }
        //        int32_t timeScale = self.player.currentItem.asset.duration.timescale;
        //currentItem.asset.duration.timescale计算的时候严重堵塞主线程，慎用
        /* A timescale of 1 means you can only specify whole seconds to seek to. The timescale is the number of parts per second. Use 600 for video, as Apple recommends, since it is a product of the common video frame rates like 50, 60, 25 and 24 frames per second*/
        
        [self.player seekToTime:CMTimeMakeWithSeconds(time, _currentItem.currentTime.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            
        }];
        
        
    }
}

#pragma mark ********** 3-处理传入的当前Item **********
#pragma mark -重写URLString的setter方法，处理自己的逻辑，
/**
 *  重写URLString的setter方法，处理自己的逻辑，
 */
- (void)setURLString:(NSString *)URLString{
    _URLString = URLString;
    //设置player的参数
    self.currentItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:URLString]];
    
    self.player = [AVPlayer playerWithPlayerItem:_currentItem];
    self.player.usesExternalPlaybackWhileExternalScreenIsActive=YES;
    //AVPlayerLayer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.layer.bounds;
    //WMPlayer视频的默认填充模式，AVLayerVideoGravityResizeAspect
    self.playerLayer.videoGravity = AVLayerVideoGravityResize;
    [self.layer insertSublayer:_playerLayer atIndex:0];
    self.state = RWPlayerViewStateBuffering;
    if (self.closeBtnStyle==CloseBtnStylePop) {
        [_closeBtn setImage:[UIImage imageNamed:@"play_back.png"] forState:UIControlStateNormal];
        [_closeBtn setImage:[UIImage imageNamed:@"play_back.png"] forState:UIControlStateSelected];
        
    }else{
        [_closeBtn setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
        [_closeBtn setImage:[UIImage imageNamed:@"close"] forState:UIControlStateSelected];
    }
}

- (void)setTitleName:(NSString *)titleName {
    _titleName = titleName;
    self.titleLabel.text = titleName;
}

#pragma mark - 当前播放的item的set方法
-(void)setCurrentItem:(AVPlayerItem *)currentItem{
    if (_currentItem==currentItem) {
        return;
    }
    
    //如果存在旧的currentItem，那么就移除【监听】
    if (_currentItem) {
        //移除监听播放完成通知
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_currentItem];
        //移除KVO
        [self removeRWPlayerKVO];
    }
    //给当前Item重新复制
    _currentItem = currentItem;
    if (_currentItem) {
        //添加 KVO
        [self addRWPlayerKVO];
        //更换当前播放Item
        [self.player replaceCurrentItemWithPlayerItem:_currentItem];
        // 添加视频播放结束通知
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_currentItem];
    }
}

#pragma mark - 添加KVO
/**
 *  添加KVO
 */
- (void)addRWPlayerKVO {
    //监听播放状态
    [_currentItem addObserver:self
                   forKeyPath:@"status"
                      options:NSKeyValueObservingOptionNew
                      context:PlayViewStatusObservationContext];
    //监听缓存
    [_currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
    // 缓冲区空了，需要等待数据
    [_currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options: NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
    // 缓冲区有足够数据可以播放了
    [_currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options: NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
}
#pragma mark - 移除KVO
/**
 *  移除KVO
 */
- (void)removeRWPlayerKVO {
    //移除关于【状态】的监听
    [_currentItem removeObserver:self forKeyPath:@"status"];
    //移除关于缓存进度的监听
    [_currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    //移除缓存为0时
    [_currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    //移除缓存有足够
    [_currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    _currentItem = nil;
}

/**
 *  设置播放的状态
 *  @param state WMPlayerState
 */
- (void)setState:(RWPlayerViewState)state
{
    _state = state;
    // 控制菊花显示、隐藏
    if (state == RWPlayerViewStateBuffering) {
        [self.loadingView startAnimating];
    }else if(state == RWPlayerViewStatePlaying){
        [self.loadingView stopAnimating];//
    }else if(state == AVPlayerStatusReadyToPlay){
        [self.loadingView stopAnimating];//
    }
    else{
        [self.loadingView stopAnimating];//
    }
}

#pragma mark ********** 4-监听点击事件 **********
#pragma mark 4-1播放暂停按钮点击事件
/**
 *  播放暂停按钮点击事件
 */
- (void)playOrPauseBtnClick:(UIButton *) playOrPause {
    if (self.player.rate != 1.f) {
        if ([self currentTime] == [self duration])
            [self setCurrentTime:0.f];
        playOrPause.selected = NO;
        [self.player play];
    } else {
        playOrPause.selected = YES;
        [self.player pause];
    }
    //播放/暂停按钮代理
    if ([self.rwPlayerViewDelegate respondsToSelector:@selector(rw_playerDelegate:playOrPauseBtnClick:)]) {
        [self.rwPlayerViewDelegate rw_playerDelegate:self playOrPauseBtnClick:playOrPause];
    }
}
///播放
-(void)play {
    [self playOrPauseBtnClick:self.playOrPauseBtn];
}
///暂停
-(void)pause{
    [self playOrPauseBtnClick:self.playOrPauseBtn];
}

/**
 * 重写 获取正在播放的时间点
 */
- (void)setCurrentTime:(double)time{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.player seekToTime:CMTimeMakeWithSeconds(time, self.currentItem.currentTime.timescale)];
    });
}


#pragma mark 4-2监听全屏按钮
- (void)fullScreenBtnClick:(UIButton *) fullScreen {
    fullScreen.selected = !fullScreen.selected;
    NSLog(@"点击了 全屏按钮");
    if (self.rwPlayerViewDelegate && [self.rwPlayerViewDelegate respondsToSelector:@selector(rw_playerDelegate:fullScreenBtnClick:)]) {
        [self.rwPlayerViewDelegate rw_playerDelegate:self fullScreenBtnClick:fullScreen];
    }
}

#pragma mark 4-3关闭按钮
- (void)closeBtnClick:(UIButton *) closeBut {
    if (self.rwPlayerViewDelegate && [self.rwPlayerViewDelegate respondsToSelector:@selector(rw_playerDelegate:closeBtnClick:)]) {
        [self.rwPlayerViewDelegate rw_playerDelegate:self closeBtnClick:closeBut];
    }
}
#pragma mark 4-5 单击手势方法
/**
 *  添加单击手势
 */
- (void)addSingleTapGestureRecognizer {
    
    // 单击的 Recognizer
    singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.numberOfTapsRequired = 1; // 单击
    singleTap.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:singleTap];
    
}

/**
 *  监听单击手势的点击
 *
 *  @param sender 单击手势
 */
- (void)handleSingleTap:(UITapGestureRecognizer *)sender{
    
    //单击手势代理方法
    if (self.rwPlayerViewDelegate&&[self.rwPlayerViewDelegate respondsToSelector:@selector(rw_playerDelegate:handleSingleTap:)]) {
        [self.rwPlayerViewDelegate rw_playerDelegate:self handleSingleTap:sender];
    }
    [self removeToolsTimer];
    [self addToolsTimer];
    [UIView animateWithDuration:0.5 animations:^{
        if (self.bottomToolView.alpha == 0.0) {
            self.bottomToolView.alpha = 1.0;
            self.closeBtn.alpha = 1.0;
            self.topToolView.alpha = 1.0;
            
        } else {
            self.bottomToolView.alpha = 0.0;
            self.closeBtn.alpha = 0.0;
            self.topToolView.alpha = 0.0;
            
        }
    } completion:^(BOOL finish){
        
    }];
}


#pragma mark 4-6 双击手势方法
/**
 *  添加双击手势
 */
- (void)addDoubleTapGestureRecognizer {
    // 双击的 Recognizer
    UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2; // 双击
    [singleTap requireGestureRecognizerToFail:doubleTap];//如果双击成立，则取消单击手势（双击的时候不回走单击事件）
    [self addGestureRecognizer:doubleTap];
}
/**
 *  监听手势的双击
 *
 *  @param doubleTap 双击手势
 */
- (void)handleDoubleTap:(UITapGestureRecognizer *)doubleTap{
    
    //双击手势代理方法
    if (self.rwPlayerViewDelegate&&[self.rwPlayerViewDelegate respondsToSelector:@selector(rw_playerDelegate:handleDoubleTap:)]) {
        [self.rwPlayerViewDelegate rw_playerDelegate:self handleDoubleTap:doubleTap];
    }
    
    if (self.player.rate != 1.f) {
        if ([self currentTime] == self.duration)
            [self setCurrentTime:0.f];
        [self.player play];
        self.playOrPauseBtn.selected = NO;
    } else {
        [self.player pause];
        self.playOrPauseBtn.selected = YES;
    }
    [UIView animateWithDuration:0.5 animations:^{
        self.bottomToolView.alpha = 1.0;
        self.topToolView.alpha = 1.0;
        self.closeBtn.alpha = 1.0;
        
    } completion:^(BOOL finish){
        
    }];
}

#pragma mark *********** 5-监听手势的滑动 ***********
#pragma mark 5-1 监听音量进度条的变化
/**
 *  监听音量进度条的变化
 */
- (void)updateSystemVolumeValue:(UISlider *)slider{
    systemSlider.value = slider.value;
}

#pragma mark 5-2 监听播放进度条的变化
/**
 *  触摸到进度条
 */
- (void)progressSliderTouchDown:(UISlider *)slider{
    //结束定时
    [self removeProgressTimer];
    NSLog(@"progressSliderTouchDown");
}

#pragma mark 5-3 监听播放进度条的变化
/**
 *  监听播放进度条的变化
 */
- (void)valueChangeProgressSlider:(UISlider *)slider{
    //更新UI界面
    // 1.更新时间
    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.duration) * self.progressSlider.value;
    NSLog(@"开始时间：%f", currentTime);
    NSLog(@"%f", CMTimeGetSeconds(self.player.currentItem.duration));
    NSLog(@"结束时间：%f", self.progressSlider.value);
    
    //当前播放时间
    self.leftTimeLabel.text = [self stringWithCurrentTime:self.progressSlider.value];
}

#pragma mark 5-4 结束滑动进度条
/**
 *  结束滑动进度条
 */
- (void)progressSliderTouchUpInside:(UISlider *)slider {
    
    [self addProgressTimer];
    //    NSTimeInterval currentTime = CMTimeGetSeconds(self.player.currentItem.duration) * self.progressSlider.value;
    
    NSTimeInterval currentTime = self.progressSlider.value;
    
    // 设置当前播放时间
    [self.player seekToTime:CMTimeMakeWithSeconds(currentTime, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    
    //设置按钮状态(播放状态)
    self.playOrPauseBtn.selected = NO;
    [self.player play];
    
    //打开定时器
    //    [self addProgressTimer];
    //    [self.player seekToTime:CMTimeMakeWithSeconds(slider.value, _currentItem.currentTime.timescale)];
    //    //设置按钮状态(播放状态)
    //    self.playOrPauseBtn.selected = NO;
    //
    //    [self.player play];
}

#pragma mark 5-5 视频进度条的点击事件
/**
 *  视频进度条的点击事件
 */
- (void)actionTapGesture:(UITapGestureRecognizer *)sender {
    //1、点击位置
    CGPoint touchLocation = [sender locationInView:self.progressSlider];
    CGFloat value = (self.progressSlider.maximumValue - self.progressSlider.minimumValue) * (touchLocation.x / self.progressSlider.frame.size.width);
    //给进度条设值
    [self.progressSlider setValue:value animated:YES];
    
    //跳转到相应位置
    [self.player seekToTime:CMTimeMakeWithSeconds(self.progressSlider.value, self.currentItem.currentTime.timescale)];
    //如果当前是暂停状态
    if (self.player.rate != 1.0) {
        if ([self currentTime] == [self duration]) {
            [self setCurrentTime:0.00];
            self.playOrPauseBtn.selected = NO;
        }
        self.playOrPauseBtn.selected = YES;
        [self.player play];
    }
    
}


#pragma mark ************ 6-通知方法 ************
#pragma mark 6-1 进入前台
- (void)appWillEnterForeground:(NSNotification*)note
{
    NSLog(@"进入前台");
    if (self.playOrPauseBtn.isSelected == NO) {//如果是播放中，则继续播放
        NSArray *tracks = [self.currentItem tracks];
#warning AVPlayerItemTrack的作用
        for (AVPlayerItemTrack *playerItemTrack in tracks) {
            if ([playerItemTrack.assetTrack hasMediaCharacteristic:AVMediaCharacteristicVisual]) {
                playerItemTrack.enabled = YES;
            }
        }
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.frame = self.bounds;
        self.playerLayer.videoGravity = AVLayerVideoGravityResize;
        [self.layer insertSublayer:self.playerLayer atIndex:0];
        [self.player play];
        self.state = RWPlayerViewStatePlaying;
    } else {
        self.state = RWPlayerViewStateStopped;
    }
}

#pragma mark 6-2 进入后台
- (void)appDidEnterBackground:(NSNotification*)note
{
    NSLog(@"进入后台");
    //如果是播放中，则暂停播放
    if (self.playOrPauseBtn.isSelected == NO) {
        NSArray *tracks = [self.currentItem tracks];
        for (AVPlayerItemTrack *playerItemTrack in tracks) {
            if ([playerItemTrack.assetTrack hasMediaCharacteristic:AVMediaCharacteristicDubbedTranslation]) {
                playerItemTrack.enabled = YES;
            }
        }
        self.playerLayer.player = nil;
        [self.player pause];
        self.state = RWPlayerViewStateStopped;
        
    } else {
        self.state = RWPlayerViewStateStopped;
    }
}

#pragma mark 6-3 appwillResignActive
- (void)appwillResignActive:(NSNotification *)note
{
    NSLog(@"appwillResignActive");
}

#pragma mark 6-4 appBecomeActive
- (void)appBecomeActive:(NSNotification *)note
{
    NSLog(@"appBecomeActive");
}

#pragma mark 6-5 监听播放完成
/**
 *  监听播放完成
 */
- (void)moviePlayDidEnd:(NSNotification *)notification {
    self.state = RWPlayerViewStateFinished;
    //播放完成代理
    if (self.rwPlayerViewDelegate&&[self.rwPlayerViewDelegate respondsToSelector:@selector(rw_playerFinishedPlay:)]) {
        [self.rwPlayerViewDelegate rw_playerFinishedPlay:self];
    }
    
    [self.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [self.progressSlider setValue:0.0 animated:YES];
        self.playOrPauseBtn.selected = YES;
    }];
    [UIView animateWithDuration:0.5 animations:^{
        self.bottomToolView.alpha = 1.0;
        self.topToolView.alpha = 1.0;
    } completion:^(BOOL finish){
        
    }];
}

#pragma mark ********* 7-定时器初始化 **********
#pragma mark 7-1 更新UI界面定时器
/**
 *  更新UI界面的定时器
 */
- (void)addProgressTimer {
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateProgressInfo) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];
}


#pragma mark 7-2 移除UI界面的定时器
/**
 *  移除UI界面的定时器
 */
- (void)removeProgressTimer {
    [self.progressTimer invalidate];
    self.progressTimer = nil;
}


#pragma mark 7-3 更新UI界面
/**
 *  更新UI界面
 */
- (void)updateProgressInfo {
    // 1.更新时间
    NSTimeInterval currentTime = [self currentTime];
    //当前播放时间
    self.leftTimeLabel.text = [self stringWithCurrentTime:currentTime];
    //视频总时间
    NSTimeInterval duration = [self duration];
    self.rightTimeLabel.text = [self stringWithCurrentTime:duration];
    
    // 2.设置进度条的value
    //    self.progressSlider.value = CMTimeGetSeconds(self.player.currentTime) / CMTimeGetSeconds(self.player.currentItem.duration);
    
    float minValue = [self.progressSlider minimumValue];
    float maxValue = [self.progressSlider maximumValue];
    double nowTime = CMTimeGetSeconds([self.player currentTime]);
    [self.progressSlider setValue:(maxValue - minValue) * nowTime / duration + minValue];
    //    self.progressSlider.value = CMTimeGetSeconds(self.player.currentTime) / CMTimeGetSeconds(self.currentItem.duration);
    
    
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)){
        self.progressSlider.minimumValue = 0.0;
        return;
    }
    //    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)){
        //        float minValue = [self.progressSlider minimumValue];
        //        float maxValue = [self.progressSlider maximumValue];
        //        double nowTime = CMTimeGetSeconds([self.player currentTime]);
        //        double remainTime = duration-nowTime;
        //        [self.progressSlider setValue:(maxValue - minValue) * nowTime / duration + minValue];
        //        self.leftTimeLabel.text = [self convertTime:nowTime];
        //        self.rightTimeLabel.text = [self convertTime:remainTime];
        //        if (self.isDragingSlider==YES) {//拖拽slider中，不更新slider的值
        //
        //        }else if(self.isDragingSlider==NO){
        //            [self.progressSlider setValue:(maxValue - minValue) * nowTime / duration + minValue];
        //        }
    }
}


#pragma mark 7-4 工具条定时器
/**
 *  工具条定时器
 */
- (void)addToolsTimer {
    self.toolsTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(disappearToolsTimerInfo) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.toolsTimer forMode:NSRunLoopCommonModes];
}

#pragma mark 7-5 移除工具条的定时器
/**
 *  移除工具条的定时器
 */
- (void)removeToolsTimer {
    [self.toolsTimer invalidate];
    self.toolsTimer = nil;
}

#pragma mark 7-6 监听隐藏工具条
- (void)disappearToolsTimerInfo {
    
    if (self.bottomToolView.alpha==1.0) {
        [UIView animateWithDuration:0.5 animations:^{
            self.bottomToolView.alpha = 0.0;
            self.closeBtn.alpha = 0.0;
            self.topToolView.alpha = 0.0;
            
        } completion:^(BOOL finish){
            
        }];
    }
    
}





#pragma mark ********* 8-私有方法 **********
#pragma mark 8-1 当前播放时间
- (NSString *)timeString
{
    NSTimeInterval duration = [self duration];
    NSTimeInterval currentTime = [self currentTime];
    
    return [self stringWithCurrentTime:currentTime duration:duration];
}

#pragma mark 8-2 当前时间转成为 字符串
- (NSString *)stringWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration
{
    NSInteger dMin = duration / 60;
    NSInteger dSec = (NSInteger)duration % 60;
    
    NSInteger cMin = currentTime / 60;
    NSInteger cSec = (NSInteger)currentTime % 60;
    
    NSString *durationString = [NSString stringWithFormat:@"%02ld:%02ld", dMin, dSec];
    NSString *currentString = [NSString stringWithFormat:@"%02ld:%02ld", cMin, cSec];
    
    return [NSString stringWithFormat:@"%@/%@", currentString, durationString];
}

#pragma mark 8-3 当前时间转成为 字符串
/**
 *  转换时间
 */
- (NSString *)stringWithCurrentTime:(NSTimeInterval)currentTime
{
    NSInteger cMin = currentTime / 60;
    NSInteger cSec = (NSInteger)currentTime % 60;
    NSString *currentString = [NSString stringWithFormat:@"%02ld:%02ld", cMin, cSec];
    return currentString;
}

#pragma mark 8-4 获取视频长度
///获取视频长度
- (double)duration{
    AVPlayerItem *playerItem = self.player.currentItem;
    if (playerItem.status == AVPlayerItemStatusReadyToPlay){
        return CMTimeGetSeconds([[playerItem asset] duration]);
    }
    else{
        return 0.f;
    }
}

#pragma mark 8-5 获取视频当前播放的时间
///获取视频当前播放的时间
- (double)currentTime{
    if (self.player) {
        return CMTimeGetSeconds([self.player currentTime]);
    }else{
        return 0.0;
    }
}

#pragma mark 8-5 获取时长
- (CMTime)playerItemDuration{
    AVPlayerItem *playerItem = _currentItem;
    if (playerItem.status == AVPlayerItemStatusReadyToPlay){
        return([playerItem duration]);
    }
    return(kCMTimeInvalid);
}


#pragma mark ********** 9-计算缓冲 ***********
/**
 *  计算缓冲进度
 *
 *  @return 缓冲进度
 */
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [_currentItem loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

/**
 *  缓冲回调
 */
- (void)loadedTimeRanges
{
    self.state = RWPlayerViewStateBuffering;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //        [self play];
        //结束菊花
        [self.loadingView stopAnimating];
    });
}


#pragma mark 10-lazy 加载失败的label
-(UILabel *)loadFailedLabel{
    if (_loadFailedLabel==nil) {
        _loadFailedLabel = [[UILabel alloc]init];
        _loadFailedLabel.textColor = [UIColor whiteColor];
        _loadFailedLabel.textAlignment = NSTextAlignmentCenter;
        _loadFailedLabel.text = @"视频加载失败";
        _loadFailedLabel.hidden = YES;
        [self addSubview:_loadFailedLabel];
        
        [_loadFailedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.width.equalTo(self);
            make.height.equalTo(@30);
            
        }];
    }
    return _loadFailedLabel;
}






#pragma mark ********** 11-监听屏幕点击、滑动来改变 音量、亮度 ***********
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in event.allTouches) {
        self.firstPoint = [touch locationInView:self];
    }
    self.volumeSlider.value = systemSlider.value;
    //记录下第一个点的位置，用于moved方法判断用户是调节音量还是调节视频
    self.originalPoint = self.firstPoint;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in event.allTouches) {
        self.secondPoint = [touch locationInView:self];
    }
    
    //判断是左右滑动 还是 上下滑动
    //上下滑动
    CGFloat verValue = fabs(self.originalPoint.y - self.secondPoint.y);
    //左右滑动
    CGFloat horValue = fabs(self.originalPoint.x - self.secondPoint.x);
    
    /**
     *  1、如果竖直方向的偏移量大于水平方向的偏移量，那么是调节 音量 或 亮度
     */
    if (verValue > horValue) {//上下滑动
        //判断是全屏模式还是正常模式
        if (self.isFullscreen) {//全屏下
            //判断刚开始的点是左边还是右边，左边控制音频
            if (self.originalPoint.x <= kScreenWidthHalf) {//全屏下:point在view的左边(控制音量)
                /* 手指上下移动的计算方式,根据y值,刚开始进度条在0位置,当手指向上移动1000个点后,当手指向上移动N个点的距离后,
                 当前的进度条的值就是N/1000,1000随开发者任意调整,数值越大,那么进度条到大1这个峰值需要移动的距离也变大,反之越小 */
                systemSlider.value += (self.firstPoint.y - self.secondPoint.y) / 1000.0;
                //赋值给音量
                self.volumeSlider.value = systemSlider.value;
                
            } else {//全屏下:point在view的右边(控制亮度)
                //右边调节屏幕亮度
                self.lightSlider.value += (self.firstPoint.y - self.secondPoint.y)/1000.0;
                [[UIScreen mainScreen] setBrightness:self.lightSlider.value];
                
            }
            
        } else { //非全屏
            //判断刚开始的点是左边还是右边,左边控制音量
            if (self.originalPoint.x <= kScreenWidthHalf) {//非全屏下:point在view的左边(控制音量)
                /* 手指上下移动的计算方式,根据y值,刚开始进度条在0位置,当手指向上移动1000个点后,当手指向上移动N个点的距离后,
                 当前的进度条的值就是N/1000,1000随开发者任意调整,数值越大,那么进度条到大1这个峰值需要移动的距离也变大,反之越小 */
                systemSlider.value += (self.firstPoint.y - self.secondPoint.y) / 1000.0;
                self.volumeSlider.value = systemSlider.value;
            } else {//非全屏下:point在view的右边(控制亮度)
                //右边调节屏幕亮度
                self.lightSlider.value += (self.firstPoint.y - self.secondPoint.y)/1000.0;
                [[UIScreen mainScreen] setBrightness:self.lightSlider.value];
                
            }
            
        }
    } else {//左右滑动,调节视频的播放进度
        //视频进度不需要除以600是因为self.progressSlider没设置最大值,它的最大值随着视频大小而变化
        //要注意的是,视频的一秒时长相当于progressSlider.value的1,视频有多少秒,progressSlider的最大值就是多少
        self.progressSlider.value -= (self.firstPoint.x - self.secondPoint.x);
        //跳转到滑动到的位置
        [self.player seekToTime:CMTimeMakeWithSeconds(self.progressSlider.value, self.currentItem.currentTime.timescale)];
        //滑动太快可能会停止播放,所以这里自动继续播放
        if (self.player.rate != 1.f) {
            if ([self currentTime] == [self duration])
                [self setCurrentTime:0.f];
            self.playOrPauseBtn.selected = NO;
            [self.player play];
        }
        
    }
    self.firstPoint = self.secondPoint;
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    self.firstPoint = self.secondPoint = CGPointZero;
}

#pragma mark ********* 12-播放器销毁 **********
- (void)dealloc {
    NSLog(@"RWPlayer播放器___dealloc");
    //1、取消通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //2、currentItem
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    //3、暂停播放器
    [self.player pause];
    //4、移除观察者
    [_currentItem removeObserver:self forKeyPath:@"status"];
    [_currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    
    //移除视图
    [self.playerLayer removeFromSuperlayer];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player = nil;
    self.currentItem = nil;
    self.playOrPauseBtn = nil;
    self.playerLayer = nil;
    
    self.progressTimer = nil;
    self.toolsTimer = nil;
}


@end
