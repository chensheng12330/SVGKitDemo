//
//  SVGListViewController.m
//  Demo-iOS
//
//  Created by sherwin on 14-6-16.
//  Copyright (c) 2014年 na. All rights reserved.
//

#import "SVGListViewController.h"
#import "SVGDetailViewController.h"

#import "MKNetworkKit.h"
#import "MKNetworkEngineEx.h"

//#import <libkern/OSMemoryNotification.h>

#define SH_IOS7_SET {if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {\
self.edgesForExtendedLayout = UIRectEdgeNone;}}



static MKNetworkEngineEx *mkEngineEx;


@interface SVGListViewController ()

@property (nonatomic, assign) SVGDetailViewController *curVC;
@property (nonatomic, retain) NSMutableArray *subVCS;

@property (nonatomic, retain) NSDictionary *cacheVCS;  //视图层缓存


//mark cache
@property (nonatomic, retain) NSMutableDictionary *dtMarkCache;
@end

@implementation SVGListViewController

- (void)dealloc
{
    [self.subVCS removeAllObjects];
    
    self.cacheVCS = nil;
    
    self.subVCS = nil;
    
    self.slideSwitchView = nil;
    
    self.svgMapData = nil;
    self.dtMarkCache= nil;
    
    self.areaId = nil;
    //[mkEngineEx release];
    [super dealloc];
    return;
}

-(NSString*) getSVGFolder
{
    NSString *appDoc = [SH_LibraryDir stringByAppendingPathComponent:@"SVGFolderCache"];
    if (![SH_FileMag fileExistsAtPath:appDoc]) {
        [SH_FileMag createDirectoryAtPath:appDoc withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return appDoc;
}

-(void) downSVGFileForUrl:(NSString*) url VC:(SVGDetailViewController *)obj
{
    
    if (![url hasPrefix:@"http"]) {
        if (self.curVC!= NULL) {
            [self.curVC loadSVGForPath:url];
        }
        return;
    }
    
     NSString *fileName = [url md5];
    
    
    //查询文件是否已下载
    NSString *filePath = [[self getSVGFolder] stringByAppendingPathComponent:[fileName stringByAppendingString:@".svg"]];
    if([SH_FileMag fileExistsAtPath:filePath])
    {
        if (self.curVC!= NULL) {
            
            //[self.view addHUDActivityView:@"正中加载数据"];
            [self.curVC loadSVGForPath:filePath];
        }
        return;
    }
    //没缓存，，下载文件
   
    //查询当前URL是否已存在下载线程
    if ([mkEngineEx.OpInfoDictionary objectForKey:fileName]== NULL) {
        
        NSString *filePath = [[self getSVGFolder] stringByAppendingPathComponent:fileName];
        
        //移除未下载完成的
        [SH_FileMag removeItemAtPath:fileName error:nil];
        
        //申请线程资源
        MKNetworkOperation *downloadOperation = [mkEngineEx downloadFileFrom:url toFile:filePath];
        
        MKNKResponseBlock completionHandler = ^(MKNetworkOperation* completedOperation)
        {
            NSString *toPath = [filePath  stringByAppendingString:@".svg"];
            [SH_FileMag moveItemAtPath:filePath toPath:toPath error:nil];
            [SH_FileMag removeItemAtPath:filePath error:nil];
            
            [mkEngineEx.OpInfoDictionary removeObjectForKey:fileName];
            
            //加载数据
            if(obj==self.curVC)
            {
                [self.curVC loadSVGForPath:toPath];
                NSLog(@"loadSVGForPath");
            }
            else{
                NSLog(@"%@ -  %@",self.curVC, obj);
            }
        };
        
        MKNKResponseErrorBlock errorHandler = ^(MKNetworkOperation* completedOperation, NSError* error)
        {
            NSLog(@"下载失败!");
            
            SH_Alert(@"地图下载失败,请稍后再试.");
            
            [self.curVC removeAllShowView];
        };
        
        //加入触发事件
        [downloadOperation addCompletionHandler:completionHandler errorHandler:errorHandler];
        
        //加入线程池队列
        [mkEngineEx.OpInfoDictionary setObject:downloadOperation forKey:fileName];
        [mkEngineEx enqueueOperation:downloadOperation];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ///////////////----------//
    SH_IOS7_SET;
    
    @synchronized(self)
    {
        if (nil == mkEngineEx ) { //@"baidu.com"
            mkEngineEx = [[MKNetworkEngineEx alloc] initWithHostName:@"baidu.com" customHeaderFields:nil];
        }
    }
    
    self.subVCS   = [NSMutableArray array];
    self.cacheVCS = [NSMutableDictionary dictionary];
    
    [self reloadSlideSwitchView];
    
    
    UIButton *btnFull = [UIButton buttonWithType:0];
    
    if (DEVICE_IS_IPHONE4) {
        [btnFull setFrame:CGRectMake(231,430, 84 ,24)];
    }
    else
        
    [btnFull setFrame:CGRectMake(231,520, 84 ,24)];
    
    
    [btnFull setImage:[UIImage imageWithContentsOfFile:[MDMXIB pathForResource:@"svg_fullView" ofType:@"png"]] forState:0];
    [btnFull addTarget:self action:@selector(goToFullImage) forControlEvents:(1<<6)];
    
    [self.view addSubview:btnFull];
    return;
}


-(void) reloadSlideSwitchView
{
    //remove data
    [self.subVCS removeAllObjects]; ;
    [self.slideSwitchView removeFromSuperview]; self.slideSwitchView = nil;
    
    for (NSDictionary *tmpDic  in self.svgMapData) {
        
        SVGDetailViewController *obj = self.cacheVCS[tmpDic[SVG_MAP_mapid]];
        if (obj==NULL) {
            
            obj = [[[NSClassFromString(@"SVGDetailViewController") alloc] initWithNibName:@"SVGDetailViewController" bundle:MDMXIB] autorelease];
            obj.title   = tmpDic[SVG_MAP_name];
            obj.mapID   = tmpDic[SVG_MAP_mapid];
            obj.mapURL  = tmpDic[SVG_MAP_url];
            obj.delegate= self;
            
            [self.cacheVCS setValue:obj forKey:tmpDic[SVG_MAP_mapid]];
        }
        else{
            NSLog(@"使用缓存.mapID:%@",obj.mapID);
        }
        
        //启动下载文件。
        //obj.
        [self downSVGFileForUrl:obj.mapURL VC:obj];
        
        [self.subVCS addObject:obj];
    }
    
    // init
    CGRect svFrame = self.ecpSlideView.frame;
    if (SH_SCREEN_HEIGHT==480) {
        svFrame.size.height -= 88;
    }
    
    self.slideSwitchView = [[[QCSlideSwitchView alloc] initWithFrame:svFrame] autorelease];
    //self.slideSwitchView.
    self.slideSwitchView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.slideSwitchView];
    
    self.slideSwitchView.slideSwitchViewDelegate = self;
    
    self.slideSwitchView.tabItemNormalColor   = [QCSlideSwitchView colorFromHexRGB:@"868686"]; //[UIColor blackColor]; //
    self.slideSwitchView.tabItemSelectedColor = [QCSlideSwitchView colorFromHexRGB:@"bb0b15"];
    
    self.slideSwitchView.shadowImage = [[UIImage imageWithContentsOfFile:[MDMXIB pathForResource:@"red_line_and_shadow@2x" ofType:@"png"]]
                                        stretchableImageWithLeftCapWidth:59.0f topCapHeight:0.0f];

    
    if (self.subVCS.count>4) {
        UIButton *rightSideButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [rightSideButton setImage:[UIImage imageWithContentsOfFile:[MDMXIB pathForResource:@"icon_rightarrow" ofType:@"png"]] forState:UIControlStateNormal];
        rightSideButton.frame = CGRectMake(0, 0, 20.0f, 44.0f);
        rightSideButton.userInteractionEnabled = YES;
        self.slideSwitchView.rigthSideButton = rightSideButton;
    }
    
    [self.slideSwitchView buildUI];
}

- (void) viewDidUnload
{
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"＝＝＝> svg didReceiveMemoryWarning!!");
    
    NSInteger nlvl =  0;//(NSInteger)OSMemoryNotificationCurrentLevel();
    
    int memCount=0;
    for (SVGDetailViewController *tmp in self.subVCS) {
        if (tmp.isInit) {
            memCount++;
        }
    }
    
    if (nlvl==0) {
        if (DEVICE_IS_IPHONE5 && memCount<=6) {
            return;
        }
        else if (DEVICE_IS_IPHONE4 && memCount<=4)
        {
            return;
        }
    }
    else if(nlvl==1)
    {
        if (DEVICE_IS_IPHONE5 && memCount<=4) {
            return;
        }
        else if (DEVICE_IS_IPHONE4 && memCount<=2)
        {
            return;
        }
    }
    
    NSLog(@"MemoryWarning: %d",nlvl);
    //内存级别处理
    
    //svg个人处理
    
    //[self.subVCS[2] clearResourceForMemoryWarning];
    SVGDetailViewController *freeObj = nil;
    SVGDetailViewController *curObj  = self.curVC;

    
    NSArray *keys = [self.cacheVCS allKeys];
    
    //整理mapid顺序，，由小到大。
    NSArray *sortKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
        if ([obj1 intValue] >[obj2 intValue]) {
            return 1;
        }
        
        return -1;
    }];
    
    //找出当前视图所在sortKyes的位置
    int curIndex=0;
    for (int i=0; i<sortKeys.count; i++) {
        if ([curObj.mapID isEqualToString:sortKeys[i]]) {
            curIndex = i;
            break;
        }
    }
    
    //距离排序，由远到近; 远距离排前，，近距离排后
    int min=0, max=sortKeys.count-1;
    NSMutableArray *disSortKeys = [NSMutableArray array];
    
    while (1) {
        if(min==curIndex && max==curIndex)
        {
            break;
        }
        
        if ((curIndex-min) > (max-curIndex)) {
            [disSortKeys addObject:sortKeys[min]];
            min++;
        }
        else
        {
            [disSortKeys addObject:sortKeys[max]];
            max--;
        }
    }
    
    
    for (NSString *key in disSortKeys) {
        SVGDetailViewController *tmpObj = self.cacheVCS[key];
        
        if (tmpObj==curObj) { continue; } //如果是当前页
        if (!tmpObj.isInit) { continue; } //如果是已清楚，或未初使化
        if (freeObj==NULL) {  freeObj = tmpObj; }//如果是首次对比
        
        if (tmpObj.userTimes< freeObj.userTimes ) { //如果对比的使用次数小于，则替换
            freeObj = tmpObj;
        }
    }
    
    //过滤ok.执行操作
    [freeObj clearResourceForMemoryWarning];
    
    return;
}

#pragma mark - 滑动tab视图代理方法

- (NSUInteger)numberOfTab:(QCSlideSwitchView *)view
{
    // you can set the best you can do it ;
    return self.subVCS.count;
}

- (UIViewController *)slideSwitchView:(QCSlideSwitchView *)view viewOfTab:(NSUInteger)number isAddTap:(BOOL*) yesOrNo
{
    return self.subVCS[number];
}

//- (void)slideSwitchView:(QCSlideSwitchView *)view panLeftEdge:(UIPanGestureRecognizer *)panParam
//{
//    QCViewController *drawerController = (QCViewController *)self.navigationController.mm_drawerController;
//    [drawerController panGestureCallback:panParam];
//}

- (void)slideSwitchView:(QCSlideSwitchView *)view didselectTab:(NSUInteger)number
{
    NSLog(@"%d",number);
    
    
    SVGDetailViewController *vc1 = self.subVCS[number];
    self.curVC = vc1;
    
    //设置mark cache
    NSArray *markCache= self.dtMarkCache[vc1.mapID];
    if (markCache) {
        vc1.arMarkCache = markCache;
        [self.dtMarkCache removeObjectForKey:vc1.mapID];
    }
    
    [self performSelector:@selector(slideForView:) withObject:vc1 afterDelay:1];
    //下载
}

-(void) slideForView:(SVGDetailViewController*)vc
{
    [self downSVGFileForUrl:vc.mapURL VC:vc];
}

- (IBAction)btnBack:(UIButton *)sender {

    [self.view removeFromSuperview];
    
    if (self.delegate) {
        [self.delegate backFromSVGMap];
    }
}

- (IBAction)btnSearch:(UIButton *)sender {
    
    //[self.view setHidden:YES];
    
    if (self.delegate) {
        [self.delegate touchSearchButton:self.curVC.mapID];
    }
    return;
}

- (IBAction)btnDownload:(UIButton *)sender {
    
    [self.curVC showPathWithBeginEleID:@"_x32_" EndEleID:@"_x39__7_"];
    
    return;
    
    NSArray *ar = nil;
    if (sender.tag==1) {
        ar = @[@"_x32_",@"_x34_",@"_x36_",@"_x38_"];
        
        sender.tag = 2;
    }
    else
    {
        ar = @[@"_x31__3_",@"_x33__3_",@"_x35__3_",@"_x38__3_"];
        
        sender.tag = 1;
    }
    
    [self.curVC showTapLayerForListID:ar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==0) {
        
        if (self.delegate) {
            [self.view setHidden:YES];
            
            [self.delegate touchMapAreaDown:self.areaId];
        }
    }
}


#pragma mark - AUX Function

-(int) getVCIndexFromMapID:(NSString*) mapID
{
    for (int i=0; i< self.subVCS.count; i++) {
        SVGDetailViewController *vc = self.subVCS[i];
        if ([vc.mapID isEqualToString:mapID]) {
            return i;
        }
    }
    
    //can't find. error!
    return -1;
}


#pragma mark - Outlet Method
-(void) showMapForMapID:(NSString*) mapID
{
    if (mapID==NULL || [mapID isEqualToString:@""]) {
        DLog(@" ＝> mapID 值为空.");
        return;
    }
    
    [self.view setHidden:NO];
    
    int index = [self getVCIndexFromMapID:mapID];
    if (index>=0) {
        
        SVGDetailViewController *svgDVC = self.subVCS[index];
        svgDVC.dontClear = NO; //设置可清除标识
        self.curVC = svgDVC;
        
        [self.slideSwitchView goToViewForIndex:index];
    }
    else
    {
        NSString *info = [NSString stringWithFormat:@"＝> 未能找到mapID对的地图 MapID:[%@]",mapID];
        JSDebugAlert(info);
    }
    return;
}



-(void) addMark:(NSString*) mapID MarkIDs:(NSArray*) markIDs
{
    if (mapID==NULL || [mapID isEqualToString:@""] || markIDs==NULL) {
        DLog(@" ＝> 参数值为空.");
        return;
    }
    
    [self.view setHidden:NO];
    
    // 滚动到目标地图
    if(![self.curVC.mapID isEqualToString:mapID]) [self showMapForMapID:mapID];
    
    // 标注地图信息
    
    [self.curVC showTapLayerForListID:markIDs];
    //if (self.curVC==NULL) {
        self.dtMarkCache = [[[NSMutableDictionary alloc] init] autorelease];
        [self.dtMarkCache setObject:markIDs forKey:mapID];
    //}
    
    return;
}

-(void) clearMarks:(NSString*) mapID MarkIDs:(NSArray*) markIDs
{
    if (SH_isStringNull(mapID)) {
        DLog(@" ＝> 参数值为空.");
        return;
    }
    
    int index = [self getVCIndexFromMapID:mapID];
    if (index==-1) {
        JSDebugAlert(@" ＝> 未能找到mapID对的视图");
        return;
    }
    
    [self.view setHidden:NO];
    
    SVGDetailViewController *vc = self.subVCS[index];
    [vc clearTapLayer:markIDs];
    
    return;
}

-(void) closeSVG:(BOOL) isClearMapCache
{
    
}

@end
