//
//  TmbSVGKit.m
//  MDMEngine
//
//  Created by sherwin on 14-6-23.
//  Copyright (c) 2014年 wireless. All rights reserved.
//

#import "TmbSVGKit.h"
#import "SVGListViewController.h"
//#import "SVGDetailViewController.h"


#define SVG_VIEW_Tag 10240707

@interface TmbSVGKit ()

@property (nonatomic, retain) SVGListViewController *listVC;
@end


@implementation TmbSVGKit


- (void)openSVG:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    [arguments pop];
    
    if (arguments.count!=1) {
        JSDebugAlert(@"tmbSVGKit.openSVG: 参数不符合要求。(mapsForJSON)");
    }
    
    NSString *jsonStr = JSGetArgmForString(arguments[0]);
    self.webView = [options objectForKey:@"webview"];
    
    NSArray *maps = [jsonStr cdvjk_objectFromJSONString];
    
    //self.listVC = NULL;
    
    if (self.listVC ==NULL) {
        
        self.listVC = [[[SVGListViewController alloc] initWithNibName:@"SVGListViewController" bundle:MDMXIB] autorelease];
        self.listVC.delegate = self;
        [self.listVC setSvgMapData:maps];
        
        self.listVC.view.tag = SVG_VIEW_Tag;
        [self.webView addSubview:self.listVC.view];
    }
    else
    {
        ///*
        //比对数据
        BOOL isNeedLoad = NO;
        if (maps.count != self.listVC.svgMapData.count) {
            isNeedLoad = YES;
        }
        else
        {
            for (NSDictionary *tmpDict in maps) {
                
                NSObject *objDVC = self.listVC.cacheVCS[tmpDict[SVG_MAP_mapid]];
                
                if(objDVC == NULL)
                {
                    isNeedLoad = YES;
                    break;
                }
                else
                {
                    BOOL isFind=NO;
                    for (NSObject *svgDVC in self.listVC.cacheVCS) {
                        if (svgDVC == objDVC) {
                            isFind = YES;
                            break;
                        }
                    }
                    
                    if (isFind==NO)
                    {
                       isNeedLoad = YES;
                        break;
                    }
                }
            }
        }
        
        //重刷视图
        if (isNeedLoad) {
            self.listVC.svgMapData = maps;
            self.listVC.view.tag = SVG_VIEW_Tag;
            [self.listVC reloadSlideSwitchView];
            
            NSLog(@"=> 重新加载-SlideSwitchView");
        }
        else
        {
            self.listVC.view.tag = SVG_VIEW_Tag;
        }
        
        [self.webView addSubview:self.listVC.view];
    }
    /*
    else
    {
        //--1 查找是否已在图层
        for (UIView *view in [self.webView subviews]) {
            if (view.tag == SVG_VIEW_Tag) {
                [self.listVC.view setHidden:NO];
                return;
            }
        }
        
        //--2 未在图层，加上
        [self.webView addSubview:self.listVC.view];
    }*/
    
    
    return;
}


/*!
 显示某号馆地图
 
 @param arguments options
 @return void
 */
-(void) show:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    [arguments pop];
    
    if (arguments.count!=1) {
        JSDebugAlert(@"tmbSVGKit.showMap: 参数不符合要求。(mapID)");
        return;
    }
    
    if (self.listVC == NULL) {
        JSDebugAlert(@"tmbSVGKit.showMap: 请先调用 [openSVG] 初使化地图");
        return;
    }
    
    NSString *mapID = JSGetArgmForString(arguments[0]);
    
    if (SH_isStringNull(mapID)) {
        JSDebugAlert(@"tmbSVGKit.showMap: 请确保mapID 不为空值。");
        return;
    }
    
    [self.listVC showMapForMapID:mapID];
    return;
}



/*!
 标注某号馆地图的展位标注
 
 @param arguments options
 @return void
 */

-(void) addMark:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    [arguments pop];
    
    if (arguments.count!=2) {
        JSDebugAlert(@"tmbSVGKit.addMark: 参数不符合要求。(mapID,MarkIDs)");
        return;
    }
    
    if (self.listVC == NULL) {
        JSDebugAlert(@"tmbSVGKit.addMark: 请先调用 [openSVG] 初使化地图.");
        return;
    }
    
    NSString *mapID   = JSGetArgmForString(arguments[0]);
    NSString *jsonStr = JSGetArgmForString(arguments[1]);
    
    NSArray *mapIDs = [jsonStr cdvjk_objectFromJSONString];
    
    [self.listVC addMark:mapID MarkIDs:mapIDs];
    
    return;
}

/*!
 清除某号馆地图的展位标注

 @param arguments options
 @return void
 */

-(void) clearMarks:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    [arguments pop];
    
    if (arguments.count!=2) {
        JSDebugAlert(@"tmbSVGKit.clearMarks: 参数不符合要求。(mapID,MarkIDs)");
        return;
    }
    
    if (self.listVC == NULL) {
        JSDebugAlert(@"tmbSVGKit.clearMarks: 请先调用 [openSVG] 初使化地图.");
        return;
    }
    
    NSString *mapID   = JSGetArgmForString(arguments[0]);
    NSString *jsonStr = JSGetArgmForString(arguments[1]);
    
    NSArray *mapIDs = [jsonStr cdvjk_objectFromJSONString];
    
    [self.listVC clearMarks:mapID MarkIDs:mapIDs];
    
    return;
}


/*!
 关闭SVG地图
 
 @param arguments options
 @return void
 */
-(void) closeSVG:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    [arguments pop];
    
    if (arguments.count!=1) {
        JSDebugAlert(@"closeSVG: 参数不符合要求。(isClearMapCache:[int])");
    }
    
    NSNumber *number = JSGetArgmForNumber(arguments[0]);
    if (number.intValue ==1) {
        //清掉已下载的SVG缓存
    }
    
    self.webView = [options objectForKey:@"webview"];
    
    if (self.listVC!=NULL) {
        [self.listVC.view removeFromSuperview];
        //self.listVC = nil;
        
        NSLog(@"==>listVC.view removeFromSuperview!!");
    }
    
    return;
}


#pragma mark - SVGDelegate
-(void) backFromSVGMap
{
    if (self.webView) {
        
        NSString* jsCallback = [NSString stringWithFormat:@"if(tmbSVGKit.cbBackSVG) tmbSVGKit.cbBackSVG();"];
        [self webView:self.webView writeJavascript:jsCallback];
    }
    else
    {
        JSDebugAlert(@"backFromSVGMap-> webView不存在，联系IOS开发人员。");
    }
}


-(void) touchSearchButton:(NSString *)mapId
{
    //tmbSVGKit.cbSearch=function(mapID){}
    if (self.webView) {
        
        NSString* jsCallback = [NSString stringWithFormat:@"if(tmbSVGKit.cbSearch) tmbSVGKit.cbSearch(%@);",mapId];
        [self webView:self.webView writeJavascript:jsCallback];
        
        [self.listVC.view removeFromSuperview];
    }
    else
    {
        JSDebugAlert(@"touchSearchButton-> webView不存在，联系IOS开发人员");
    }
}

-(void) touchMapAreaDown:(NSString*) areaId
{
    if (self.webView) {
        
        NSString* jsCallback = [NSString stringWithFormat:@"if(tmbSVGKit.cbOpenCDetail) tmbSVGKit.cbOpenCDetail(\'%@\');",areaId];
        [self webView:self.webView writeJavascript:jsCallback];
    }
    else
    {
        JSDebugAlert(@"touchMapAreaDown-> webView不存在，联系IOS开发人员。");
    }
}
@end
