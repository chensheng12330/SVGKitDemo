//
//  SVGListViewController.h
//  Demo-iOS
//
//  Created by sherwin on 14-6-16.
//  Copyright (c) 2014年 na. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QCSlideSwitchView.h"

#define SVG_MAP_name  (@"name")
#define SVG_MAP_mapid (@"mapid")
#define SVG_MAP_url   (@"url")

@protocol SVGDelegate <NSObject>
//按钮事件

//退出SVG map
-(void) backFromSVGMap;

-(void) touchSearchButton:(NSString*) mapId;

-(void) touchMapAreaDown:(NSString*) areaId;
@end



@interface SVGListViewController : UIViewController<QCSlideSwitchViewDelegate,UIActionSheetDelegate,UITextFieldDelegate>

@property (retain, nonatomic) IBOutlet UIView *ecpSlideView;

@property (nonatomic, retain) QCSlideSwitchView *slideSwitchView;

@property (nonatomic, assign) id<SVGDelegate> delegate;
@property (nonatomic, retain) NSArray *svgMapData;

@property (nonatomic, retain) NSString *areaId;

///
@property (nonatomic, readonly) NSDictionary *cacheVCS;  //视图层缓存
@property (nonatomic, readonly) NSMutableArray *subVCS;  //展示视图缓存

//路径导航UI
@property (retain, nonatomic) IBOutlet UITextField *tfStartID;
@property (retain, nonatomic) IBOutlet UITextField *tfEndID;


//重载数据
-(void) reloadSlideSwitchView;

/*
 事件
 */
/*!
 返回
 */
- (IBAction)btnBack:(UIButton *)sender;

/*!
 查找
 */
- (IBAction)btnSearch:(UIButton *)sender;

/*!
 下载
 */
- (IBAction)btnDownload:(UIButton *)sender;

/*
 区域点击事件
 */
//-(void) btnGoodsDown:(NSString*) goodId;


/* 外部接口*/

/*!
 显示某个地图mapid
 
 @param mapid
 @return void
 */
-(void) showMapForMapID:(NSString*) mapID;


/*!
 标注某地图区域

 @param mapID
 @param markIDs
 @return void
 */
-(void) addMark:(NSString*) mapID MarkIDs:(NSArray*) markIDs;

/*!
 清除所有标记
 
 @param mapID
 @param markIDs
 @return void
 */

-(void) clearMarks:(NSString*) mapID MarkIDs:(NSArray*) markIDs;


/*!
 关闭svg地图服务，清除内存
 
 @param isClearMapCache: [int]  0: 不清除已下载的svg缓存,  1 清除. 默认为0.
 @return void
 */

-(void) closeSVG:(BOOL) isClearMapCache;
@end
