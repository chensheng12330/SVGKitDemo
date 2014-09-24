//
//  TmbSVGKit.h
//  MDMEngine
//
//  Created by sherwin on 14-6-23.
//  Copyright (c) 2014年 wireless. All rights reserved.
//

#import "CDVPlugin.h"

@protocol SVGDelegate;

@interface TmbSVGKit : CDVPlugin<SVGDelegate>


/*!
 打开SVG地图
 
 @param arguments options
 @return void
 */
- (void)openSVG:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;


/*!
 显示某号馆地图
 
 @param arguments options
 @return void
 */
-(void) show:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;


/*!
 标注某号馆地图的展位标注
 
 @param arguments options
 @return void
 */

-(void) addMark:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;


/*!
 清除某号馆地图的展位标注
 
 @param arguments options
 @return <#return#>
 */

-(void) clearMarks:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

/*!
 注册搜索事件回调
 @param arguments options
 @return void
 */

/*!
 关闭SVG地图
 
 @param @param arguments options
 @return void
 */
-(void) closeSVG:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

 /* 6
 搜索事件回调
 mapID: 当前搜索的展位地图ID.
 tmbSVGKit.cbSearch=function(mapID){};
  
  tmbSVGKit.cpOpenCDetail(areaID){};
 */

@end
