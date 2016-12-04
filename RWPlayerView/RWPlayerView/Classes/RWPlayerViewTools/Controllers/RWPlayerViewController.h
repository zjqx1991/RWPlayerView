//
//  RWPlayerViewController.h
//  RWPlayerView
//
//  Created by 紫荆秋雪 on 16/12/4.
//  Copyright © 2016年 紫荆秋雪. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RWPlayerViewController : UIViewController
/**
 *  设置播放视频的USRLString，可以是本地的路径也可以是http的网络路径
 */
@property (nonatomic,copy) NSString *URLString;

/**
 *  播放视频的标题
 */
@property (nonatomic, copy) NSString *titleName;


@end
