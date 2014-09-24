//
//  DetailViewController.h
//  iOSDemo
//
//  Created by adam on 29/09/2012.
//  Copyright (c) 2012 na. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SVGKit.h"
#import "SVGKImage.h"
#import "SHSVGTool.h"
#import "SVGListViewController.h"


/*
 1、打开SVG地图 [传入地图列表数据]
 2、显示某号馆地图
 3、标注某号馆地图的展位号
 4、搜索事件回调
 5、关闭地图
 */

@interface SVGDetailViewController : UIViewController <SVGKImageDelegate, SVGKImageViewDelegate, UIScrollViewDelegate>

@property (nonatomic, retain) IBOutlet UIScrollView *scrollViewForSVG;
@property (nonatomic, retain) IBOutlet SVGKImageView *contentView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *viewActivityIndicator;

@property (retain, nonatomic) IBOutlet UILabel *svgProcInfo;
@property (retain, nonatomic) IBOutlet UILabel *lbNeedTime;

////////
@property (nonatomic, retain) NSString *mapURL;
@property (nonatomic, retain) NSString *mapID;
@property (nonatomic, retain) NSArray  *arMarkCache;

//使用次数，用于内存释放管理
@property (nonatomic, assign) NSInteger userTimes;
@property (nonatomic, assign) BOOL isInit;  //0: svg数据已被释放，  1:svg数据已生成
@property (nonatomic, assign) BOOL dontClear;
////////

@property (nonatomic, retain) SHSVGTool *svgTool;


@property (nonatomic, assign) SVGListViewController* delegate;
/*!
 载入数据
 */
- (void) loadSVGForPath:(NSString *)path;

/*!
 单点地图块颜色标点
 */
- (void) showTapLayerForID:(NSString*) eleID;

/*!
 多点地图块颜色标点
 para arEleID
 */

/*!
 Descript.
 
 @param arEleID 数组包含所有地层id
 @return void
 */
- (void) showTapLayerForListID:(NSArray*) arEleID;


/*!
 清除图层标注
 
 @param <#param#>
 @return <#return#>
 */

-(void) clearTapLayer:(NSArray*) arEleID;

/*
 事件。
 */

-(void) removeAllShowView;

/*
 内存不足处理
 */
-(void) clearResourceForMemoryWarning;

/*
 查找路径
 */
-(void) showPathWithBeginEleID:(NSString*)beginEleID EndEleID:(NSString*)endEleID;

@end
