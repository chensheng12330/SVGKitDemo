//
//  DetailViewController.m
//  iOSDemo
//
//  Created by adam on 29/09/2012.
//  Copyright (c) 2012 na. All rights reserved.
//
#import "SVGDetailViewController.h"
#import "NodeList+Mutable.h"
#import "SVGKFastImageView.h"
#import "SHTapView.h"
#include "aStart.h"

@interface SVGDetailViewController ()
{
    BOOL isFirstZool;
    long curIndex;
}

@property (nonatomic, assign) SVGKImage *svgImage;

@property (nonatomic, retain) SHTapView *tapLayer;



@property (nonatomic, retain) UITapGestureRecognizer* tapGestureRecognizer;

@property (nonatomic, retain) NSMutableArray *arTapLayers;


@property (nonatomic, retain) NSMutableArray *nodeRectMap;

- (void)loadResource:(NSString *)name;

@property (nonatomic, assign) NSInteger eatTime;


//Path Find Model
@property (nonatomic, retain) CAShapeLayer *pathLayer;
@property (nonatomic, retain) CALayer *startImageIcon;
@property (nonatomic,retain)  CALayer *endImageIcon;

@end


@implementation SVGDetailViewController

/*
 内存不足处理
 */
-(void) clearResourceForMemoryWarning
{
    //1. svg图层数据处理
    [SVGKImage releaseGlobalSVGKImageForId:self.svgImage.identify];
    
    //2. 本类辅助数据处理
    self.arMarkCache = nil;
    self.svgTool = nil;
    self.tapGestureRecognizer = nil;
    
    //3. 视图层处理
    
    [self.arTapLayers removeAllObjects]; self.arTapLayers=nil;
    self.tapLayer=nil;
    
    [self.contentView removeFromSuperview];
    self.contentView = nil;
    
    //4.愎恢到初使化原始状态
    
    isFirstZool = YES;
    curIndex    = 0;
    
    self.lbNeedTime.text =@"";
    
    self.isInit = NO;
    
    return;
}



- (void)dealloc {

    //[self.contentView.image releaseGlobalSVGKImageCache];
    self.contentView = nil;
    
	self.scrollViewForSVG = nil;
	self.viewActivityIndicator = nil;

    self.arTapLayers=nil;
    
    self.mapID    = nil;
    self.mapURL   =nil;
    self.arMarkCache =nil;
    
    [_svgProcInfo release];
    [_lbNeedTime release];

    
    self.nodeRectMap = nil;
    self.pathLayer   = nil;
    
	[super dealloc];
}


-(void)viewDidLoad
{
    if([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.arTapLayers = [[[NSMutableArray alloc] init] autorelease];
    self.userTimes = 0;
}


-(NSString*) layerInfo:(CALayer*) l
{
	return [NSString stringWithFormat:@"%@:%@", [l class], NSStringFromCGRect(l.frame)];
}

//
-(void) handleTapGesture:(UITapGestureRecognizer*) recognizer
{
    CGPoint p = [recognizer locationInView:self.contentView];
    
    CALayer*   layerForHitTesting;
	SVGKImage* svgImage = nil;
    
	if( [self.contentView isKindOfClass:[SVGKFastImageView class]])
	{
		layerForHitTesting = ((SVGKFastImageView*)self.contentView).image.CALayerTree;
		svgImage = ((SVGKFastImageView*)self.contentView).image;
		
		CGSize scaleConvertImageToViewForHitTest = CGSizeMake( self.contentView.bounds.size.width / svgImage.size.width, self.contentView.bounds.size.height / svgImage.size.height ); // this is a copy/paste of the internal "SCALING" logic used in SVGKFastImageView
		
		p = CGPointApplyAffineTransform( p, CGAffineTransformInvert( CGAffineTransformMakeScale( scaleConvertImageToViewForHitTest.width, scaleConvertImageToViewForHitTest.height)) ); // must do the OPPOSITE of the zoom (to convert the 'seeming' point to the 'actual' point
	}
	else{ layerForHitTesting = self.contentView.layer;}
	
	
    //****  Set showTap layer;
	CALayer* hitLayer = [layerForHitTesting hitTest:p];
    NSLog(@"%@ - %@ - x:%f , y:%f",hitLayer,hitLayer.name, p.x, p.y);
    
    //--1 judge layer type
    if ([hitLayer isKindOfClass:NSClassFromString(@"CAShapeLayerWithHitTest")]) {
        if (hitLayer.name == NULL || [hitLayer.name isEqualToString:@""]) {
            return;
        }
    }
    else if ([hitLayer isKindOfClass:NSClassFromString(@"CATextLayer")])
    {
        //CALayer *layer = [self.svgImage.CALayerTree valueForKey:kSVGElementIdentifier];
        NSLog(@"%@",hitLayer.name);
        NSString *layerId = hitLayer.name;
        
        if (layerId) {
            CALayer *layer = [self.svgTool getRectLayerByID:layerId];
            //if (layer) {[self showTapLayer:layer];}
            //return;
            hitLayer = layer;
        }
        else
        {
            return;
        }
    }
    else
    {
        return;
    }
    
    if (hitLayer.name!=NULL) {//

    }
    
    if(hitLayer) [self showTapLayer:hitLayer];
    return;
}
//

-(void) showAlert
{
    //[SH_Window addHUDLabelView:@"报歉,未能查询到该展位号的公司信息." Image:nil afterDelay:2];
    ///*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"报歉,未能查询到该展位号的公司信息." delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil];
    [alert show];
    [alert release];
     //*/
}

-(void) showAction1:(NSString*) title
{
    UIActionSheet *activView = [[UIActionSheet alloc] initWithTitle:title delegate:self.delegate cancelButtonTitle:@"取消"  destructiveButtonTitle:nil otherButtonTitles: @"查看公司详情",nil];
    activView.actionSheetStyle = UIActionSheetStyleDefault;
    [activView showInView:self.delegate.view];
    [activView release];
    return;
}

-(void) showTapLayer:(CALayer*) hitLayer
{
    //--2 add tab layer
    if (self.tapLayer)
    {
        //CGRect drawRect = [self getDrawRectWithLayer:self.tapLayer];
        
        [self.tapLayer removeFromSuperview];
        //[self.contentView setNeedsDisplayInRect:drawRect];
        
        if ([self.tapLayer.name isEqualToString:hitLayer.name]) {
            self.tapLayer =  nil;  //relase 取消
            return;
        }
    }
    
    ///
    
    /*
    if (self.arTapLayers.count>0) {
        for (CALayer *layer in self.arTapLayers) {
            [layer removeFromSuperlayer];
        }
        [self.arTapLayers removeAllObjects];
        
        isFull = YES;
    }
     */
    ////
    
    /*
    self.tapLayer = [[[[hitLayer class] alloc] init] autorelease];
    self.tapLayer.frame = CGRectMake(0, 0, hitLayer.frame.size.width, hitLayer.frame.size.height);
    self.tapLayer.backgroundColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.5].CGColor;
    self.tapLayer.name = hitLayer.name;
    
    [hitLayer addSublayer:self.tapLayer];
     */
    
    /////////
    //获取宽度
    CGRect drawRect = [self getDrawRectWithLayer:hitLayer];

    SHTapView *tpView = [[[SHTapView alloc] initWithFrame:drawRect colorTag:0] autorelease];
    
    self.tapLayer = tpView;
    
    [self.contentView addSubview: tpView];

    NSLog(@"--%@", NSStringFromCGRect(drawRect));
    
    //计算偏移
    CGPoint pp = tpView.frame.origin;
    pp.x *= self.scrollViewForSVG.zoomScale;
    pp.y *= self.scrollViewForSVG.zoomScale;
    
    CGFloat sx = self.scrollViewForSVG.frame.size.width/2.0;
    CGFloat sy = self.scrollViewForSVG.frame.size.height/2.0;
    pp.x -= sx;
    pp.y -= sy;
    
    if (pp.x<0) {
        pp.x = 0;
    }
    if (pp.y <0) {
        pp.y =0;
    }
    
    //修改偏移
    CGSize contSize = self.scrollViewForSVG.contentSize;
    
    CGFloat bx = pp.x + sx*2;
    if (bx  > contSize.width) {
        pp.x -=  (bx-contSize.width);
    }
    
    CGFloat by =  pp.y + sy*2;
    if (by > contSize.height) {
        pp.y -= (by -contSize.height);
    }
    
    [self.scrollViewForSVG setContentOffset:pp animated:YES];
    
    return;
}

-(CGRect) getDrawRectWithLayer:(CALayer *) hitLayer
{
    CGRect drawRect;  //= hitLayer.frame;
    
    CALayer* absolutePositionedCloneLayer = [_svgImage newCopyPositionedAbsoluteOfLayer:hitLayer];
    
    drawRect = absolutePositionedCloneLayer.frame;
    
    [absolutePositionedCloneLayer release];
    
    CGSize scaleConvertImageToView = CGSizeMake( self.contentView.bounds.size.width / _svgImage.size.width, self.contentView.bounds.size.height / _svgImage.size.height );
    drawRect = CGRectApplyAffineTransform( drawRect, CGAffineTransformMakeScale(scaleConvertImageToView.width, scaleConvertImageToView.height));
    
    return drawRect;
}


#pragma mark - CRITICAL: this method makes Apple render SVGs in sharp focus

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)finalScale
{
	/** NB: very important! The "finalScale" paramter to this method is SLIGHTLY DIFFERENT from the scale that Apple reports in the other delegate methods
	 
	 This is very confusing, clearly it's bit of a hack - the other methods get called
	 at slightly the wrong time, and so their data is slightly wrong (out-by-one animation step).
	 
	 ONLY the values passed as params to this method are correct!
	 */
	
	/**
	 
	 Apple's implementation of zooming is EXTREMELY poorly designed; it's a hack onto a class
	 that was only designed to do panning (hence the name: uiSCROLLview)
	 
	 So ... "zooming" via a UIScrollView is NOT integrated with UIView
	 rendering - in a UIView subclass, you CANNOT KNOW whether you have been "zoomed"
	 (i.e.: had your view contents ruined horribly by Apple's class)
	 
	 The three lines that follow are - allegedly - Apple's preferred way of handling
	 the situation. Note that we DO NOT SET view.frame! According to official docs,
	 view.frame is UNDEFINED (this is very worrying, breaks a huge amount of UIKit-related code,
	 but that's how Apple has documented / implemented it!)
	 */
    
    
    //注意： 如果需要重绘，那么你得取注该地，以及下面的 needsDisplay:
	//view.transform = CGAffineTransformIdentity; // this alters view.frame! But *not* view.bounds
	//view.bounds    = CGRectApplyAffineTransform( view.bounds, CGAffineTransformMakeScale(finalScale, finalScale));
 
    //CGRect reDrawFrame = self.view.frame;
    //reDrawFrame.origin = CGPointMake(0, 0);
 
    
    if (isFirstZool) {
        
        //dispatch_get_main_queue()
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            //影射图层对象
            self.svgImage.CALayerTree;
            
            //[view setNeedsDisplay];
            //[view setNeedsDisplayInRect:reDrawFrame];
        });
        
        isFirstZool = NO;
    }
	
	/**
	 Workaround for another bug in Apple's hacks for UIScrollView:
	 
	  - when you reset the transform, as advised by Apple, you "break" Apple's memory of the scroll factor.
	     ... because they "forgot" to store it anywhere (they read your view.transform as if it were a private
			 variable inside UIScrollView! This causes MANY bugs in applications :( )
	 */
	//self.scrollViewForSVG.minimumZoomScale /= finalScale;
	//self.scrollViewForSVG.maximumZoomScale /= finalScale;
    
    //NSLog(@"%f",finalScale);
}


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.contentView;
}

#pragma mark - rest of class

-(void) processSVGInfo:(NSString*) path
{
    int ntime = 0;
    if ([SH_FileMag fileExistsAtPath:path]){
        long fs = [[SH_FileMag attributesOfItemAtPath:path error:nil] fileSize]/1024;
        ntime = fs / 12 + 1;
    }
    
    if (ntime> 0) {
        
        NSString *alStr=@"";
        if (ntime>30) {
            //alStr = @"地图过大,";
        }
        
        self.lbNeedTime.text = [NSString stringWithFormat:@"%@预计需耗时[%d]秒,\r\n请耐心稍等..",alStr, ntime];
        [self.lbNeedTime setNeedsDisplay];
        
        self.eatTime = ntime;
    }
}

- (void) loadSVGForPath:(NSString *)path
{
    
    self.userTimes++;
    //740kb/50s = 14.82;
    //[self performSelectorOnMainThread:@selector(processSVGInfo:) withObject:path waitUntilDone:NO];
   
    //[self processSVGInfo:path];
    
    
    //dispatch_get_main_queue()  //dispatch_get_global_queue(0, 0)
    dispatch_async( dispatch_get_main_queue(), ^{
        
        [self loadResource:path];
        
        //[self processSVGInfo:path];

    });
}

- (void) loadResource:(NSString *)name
{
    
    if (self.contentView) {
        
        if(self.dontClear==NO)
        {
            [self clearTapLayer:nil];
        }
        
        if (!self.isInit) {
            [self.contentView setNeedsDisplay];
        }
        //
        return;
    }
    
	[self beginAllSHowView];
    
	//[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]]; // makes the animation appear
	
	SVGKImageView* newContentView = nil;
    
	CGSize customSizeForImage = CGSizeZero;
	{
		SVGKImage *document = nil;
        
		document = [SVGKImage imageWithContentsOfFileOrCache:name];
         
		if( document == nil )
		{
			[[[[UIAlertView alloc] initWithTitle:@"SVG parse failed" message:@"Total failure. See console log" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
			newContentView = nil; // signals to the rest of this method: the load failed
		}
		else
		{
			if( document.parseErrorsAndWarnings.rootOfSVGTree != nil )
			{
				//NSLog(@"[%@] Freshly loaded document (name = %@) has size = %@", [self class], name, NSStringFromCGSize(document.size) );
				/** NB: the SVG Spec says that the "correct" way to upscale or downscale an SVG is by changing the
				 SVG Viewport. SVGKit automagically does this for you if you ever set a value to image.scale */
				if( ! CGSizeEqualToSize( CGSizeZero, customSizeForImage ) )
					document.size = customSizeForImage; // preferred way to scale an SVG! (standards compliant!)
				
				newContentView = [[[SVGKFastImageView alloc] initWithSVGKImage:document] autorelease];
                newContentView.delegate = self;
                newContentView.noDraw = YES;
                
                ((SVGKFastImageView*)newContentView).disableAutoRedrawAtHighestResolution = TRUE;
			}
			else
			{
				[[[[UIAlertView alloc] initWithTitle:@"SVG parse failed" message:[NSString stringWithFormat:@"%i fatal errors, %i warnings. First fatal = %@",[document.parseErrorsAndWarnings.errorsFatal count],[document.parseErrorsAndWarnings.errorsRecoverable count]+[document.parseErrorsAndWarnings.warnings count], ((NSError*)[document.parseErrorsAndWarnings.errorsFatal objectAtIndex:0]).localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
				newContentView = nil; // signals to the rest of this method: the load failed
			}
		}
	}
	
	if( newContentView != nil )
	{
		/**
		 * NB: at this point we're guaranteed to have a "new" replacemtent ready for self.contentView
		 */
		
		/** Move the gesture recognizer off the old view */
		if( self.contentView != nil  && self.tapGestureRecognizer != nil ) {
            [self.contentView removeGestureRecognizer:self.tapGestureRecognizer];
        }
		
		[self.contentView removeFromSuperview];
		
		/******* swap the new contentview in ************/
		self.contentView = newContentView;
		
	
		/** set the border for new item */
		self.contentView.showBorder = FALSE;
	
		/** Move the gesture recognizer onto the new one */	
		if( self.tapGestureRecognizer == nil )
		{
			self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
		}
		[self.contentView addGestureRecognizer:self.tapGestureRecognizer];
		
		
		[self.scrollViewForSVG addSubview:self.contentView];
		[self.scrollViewForSVG setContentSize: self.contentView.frame.size];
		
		float screenToDocumentSizeRatio = self.scrollViewForSVG.frame.size.width / self.contentView.frame.size.width;
		
		self.scrollViewForSVG.minimumZoomScale = MIN( 2.5, screenToDocumentSizeRatio );
		self.scrollViewForSVG.maximumZoomScale = MAX( 2.5, screenToDocumentSizeRatio );
		
		/**
		 EXAMPLE:
		 
		 How to find particular nodes in the tree, after parsing.
		 
		 In this case, we search for all SVG <g> tags, which usually mean grouped-objects in Inkscape etc:
		 NodeList* elementsUsingTagG = [document.DOMDocument getElementsByTagName:@"g"];
		 NSLog( @"[%@] checking for SVG standard set of elements with XML tag/node of <g>: %@", [self class], elementsUsingTagG.internalArray );
		 */
        isFirstZool = YES;
        [self.scrollViewForSVG setZoomScale:1.01 animated:YES];
	}
    
    self.svgImage = self.contentView.image;
    
    if (self.svgImage.bakTree) {
        
        [self completeAddAllLayer:self.svgImage];
    }
    
    self.svgImage.delegate = self;

}


-(void) beginAllSHowView
{
    [self.viewActivityIndicator setHidden:NO];
    [self.viewActivityIndicator startAnimating];
    
    [self.svgProcInfo setHidden:NO];
    [self.lbNeedTime  setHidden:NO];
}

-(void) removeAllShowView
{
    [self.viewActivityIndicator stopAnimating];
    
    [self.svgProcInfo setHidden:YES];
    [self.lbNeedTime  setHidden:YES];
    
    //[self.svgProcInfo removeFromSuperview];
    //[self.lbNeedTime removeFromSuperview];
}


#pragma mark - SVG Delegate

-(void) willDrawSVGView
{
    NSLog(@"=> willDrawSVGView \r\n");
    curIndex=0;
}

-(void) didDrawSVGView
{
    curIndex=0;
    NSLog(@"=> didDrawSVGView \r\n");
    
    self.svgTool  = [[[SHSVGTool alloc] initWithSVGKImage:self.svgImage] autorelease];
    [self removeAllShowView];
    
    NSLog(@"svg Loder OK.");
    
    
    //[[[UIApplication sharedApplication].windows lastObject] removeHUDActivityView];
    
    if (self.arMarkCache) {
        NSArray *ar = [NSArray arrayWithArray:self.arMarkCache];
        self.arMarkCache = nil;
        
        [self performSelector:@selector(showTapLayerForListID:) withObject:ar afterDelay:1];
        //[self :ar];
    }
}

/**/

-(void) PorcessText:(NSString*) text
{
    if ([self.lbNeedTime.text isEqualToString:text]) {
        return;
    }
    
    self.lbNeedTime.text = text;
    [self.lbNeedTime setNeedsDisplay];
    
    //NSLog(@"PorcessText");
    
}

-(void) SVGKParseForCAlayer:(CALayer*) psLayer
{
    curIndex++;
    
    float ft = curIndex*1.0/self.svgImage.DOMTree.childNodes.length; //
    
    //[self.lbProcess performSelectorOnMainThread:@selector(setText:) withObject:[NSString stringWithFormat:@"%.2f",ft] waitUntilDone:YES];
    
    NSString *info;
    if (ft>=0.95) {
        info = @"地图即将更新,请稍候...";
    }
    else
    {
        info = [NSString stringWithFormat:@"%0.0f%%",ft*100];
    }
    
    [self performSelectorOnMainThread:@selector(PorcessText:) withObject:info waitUntilDone:YES];
    
    //NSLog(@"%@",NSStringFromClass([CALayer class]));
}


-(void) completeAddAllLayer:(SVGKImage *)svgImage
{
    [self.contentView performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
    
    self.isInit = YES;
    return;
}


#pragma mark - ShowTapLayer

- (void) showTapLayerForID:(NSString*) eleID
{
    NSAssert(eleID, @"我擦，来了个空值。");
    
    CALayer* seaLayer = [self.svgTool getRectLayerByID:eleID];
    
    [self showTapLayer:seaLayer];
    
    return;
}

- (void) showTapLayerForListID:(NSArray*) arEleID
{
    NSAssert(arEleID, @"我擦，过来了个空值。");
    
    
    self.dontClear = YES; //防止被滚的清除
    
    NSLog(@"=> 显示标注..");
    //**1  remove Super
    if (self.tapLayer) {
        [self.tapLayer removeFromSuperview];
        self.tapLayer = nil;
    }
    for (UIView *layer in self.arTapLayers) {
        [layer removeFromSuperview];
    }
    
    //**2 remove obj.
    [self.arTapLayers removeAllObjects];
    
    
    //**3 add new tap layer.
    for (NSString *eleID in arEleID) {
        
        CALayer *hitLayer = [self.svgTool getRectLayerByID:eleID];
        CGRect   drawRect = [self getDrawRectWithLayer:hitLayer];
        
        if (hitLayer==NULL) continue;
        
        SHTapView *tapLayer = [[[SHTapView alloc] initWithFrame:drawRect] autorelease];
        tapLayer.backgroundColor = [UIColor clearColor];
        tapLayer.layer.borderColor = [UIColor redColor].CGColor;
        tapLayer.layer.borderWidth = 1;
        
        tapLayer.name = hitLayer.name;
        
        [self.contentView addSubview:tapLayer];
        [self.arTapLayers addObject:tapLayer];
    }
    
    
    //***3.1  setting 1 view for tag View
    UIView *lopView=nil;
    
    if (self.arTapLayers.count>0) {
        lopView = [self.arTapLayers objectAtIndex:self.arTapLayers.count/2];
    }
    
    if (lopView) {
        
        /*
        UIImage* image = [UIImage imageWithContentsOfFile:[MDMXIB pathForResource:@"svg_mark" ofType:@"png"]];
        CGRect drawRect = lopView.frame;
        CGRect frame = CGRectMake( drawRect.size.width/4.0, (drawRect.size.height-7)/4.0, drawRect.size.width/2.0, (drawRect.size.height+7)/2.0);
        UIImageView *tipIcon = [[UIImageView alloc] initWithFrame:frame];
        //tipIcon.alpha = 0.8;
        tipIcon.userInteractionEnabled = NO;
        [tipIcon setImage:image];
        [lopView addSubview:tipIcon];
        [tipIcon release];
        */
        //CGRect fram = self.scrollViewForSVG.frame;
        
        //计算偏移
        CGPoint pp = lopView.frame.origin;
        pp.x *= self.scrollViewForSVG.zoomScale;
        pp.y *= self.scrollViewForSVG.zoomScale;
        
        CGFloat sx = self.scrollViewForSVG.frame.size.width/2.0;
        CGFloat sy = self.scrollViewForSVG.frame.size.height/2.0;
        pp.x -= sx;
        pp.y -= sy;
        
        if (pp.x<0) {
            pp.x = 0;
        }
        if (pp.y <0) {
            pp.y =0;
        }
        
        //修改偏移
        CGSize contSize = self.scrollViewForSVG.contentSize;
        
        CGFloat bx = pp.x + sx*2;
        if (bx  > contSize.width) {
            pp.x -=  (bx-contSize.width);
        }
        
        CGFloat by =  pp.y + sy*2;
        if (by > contSize.height) {
            pp.y -= (by -contSize.height);
        }
        
        [self.scrollViewForSVG setContentOffset:pp animated:YES];
    }
    else
    {
        [self.scrollViewForSVG setZoomScale:self.scrollViewForSVG.minimumZoomScale animated:YES];
    }

    
    //**4 show.

    //
    return;
}


-(void) clearTapLayer:(NSArray*) arEleID
{
    NSMutableArray *clearAry = [[[NSMutableArray alloc] init] autorelease];
    
    //**1  remove Super
    if (self.tapLayer) {
        [self.tapLayer removeFromSuperview];
        
        [clearAry addObject:self.tapLayer];
        
        self.tapLayer = nil;
    }

    
    if (arEleID==NULL || arEleID.count==0) {
        //清除所有
        [clearAry addObjectsFromArray:self.arTapLayers];
    }
    else
    {
        //清除列表
        for (NSString *eleID in arEleID) {
            for (CALayer *layer in self.arTapLayers) {
                if ([layer.name isEqualToString:eleID]) {
                    [clearAry addObject:layer];
                }
            }
        }
    }
    
    //chart
    if (clearAry.count>0) {
        for (SHTapView *layer in clearAry) {
        
            [layer removeFromSuperview];
            [self.arTapLayers removeObject:layer];
        }
        
        [clearAry removeAllObjects];
        clearAry = nil;
    }
    
    
    /*
     **2 remove obj.
    [self.arTapLayers removeAllObjects];
    
    //3 redraw.
    [self.contentView setNeedsDisplay];
    */
    
    return;
}

#pragma mark - 路径查找相关函数

//以 5*5 个像素点为一个瓦片单位

#define TilingSize 10

//默认设置，需根据画布大小来确定
int AST_WIDE   =  100; //单位->个数
int AST_LENGTH =  100;

char nodeMap[LENGTH][WIDE]; //[1][2]


//初使化瓦片阵列
-(void) initSVGToTilingArray
{
    //画布大小
    float canvasWidth  = self.contentView.layer.frame.size.width;
    float canvasHeight = self.contentView.layer.frame.size.height;
    
    //瓦片Size
    float nTilingWidth = TilingSize;
    float nTilingHeight= TilingSize;
    
    
    //处理数组
    AST_WIDE  = canvasWidth/nTilingWidth+1;
    AST_LENGTH= canvasHeight/nTilingHeight+1;
    
    //初使化数组
    self.nodeRectMap = [[[NSMutableArray alloc] init] autorelease];
    
    for (int i=0; i<AST_LENGTH; i++) {
        
        //Layer Rect Map
        NSMutableArray *xRowAry = [[NSMutableArray alloc] init];
        
        for (int j=0; j<AST_WIDE; j++) {
            nodeMap[i][j] = '.'; //全部为可行区域
            
            CGRect nodeRect = CGRectMake((j*nTilingWidth),(i*nTilingHeight), nTilingWidth, nTilingHeight);
            
            [xRowAry addObject:NSStringFromCGRect(nodeRect)];
        }
        
        [self.nodeRectMap addObject:xRowAry];
        [xRowAry release];
    }
    
     NSLog(@"%@", self.nodeRectMap);
    
    
    //获取所有展位图形
    NSArray *allRectLayer = [self.svgTool getAllRectLayer];
    
    // 处理所有展位视图,将其转换成墙模式
    for (CALayer *subLayer in allRectLayer) {

        //怪物空间
        float moW = subLayer.frame.size.width;
        float moH = subLayer.frame.size.height;
        float moOrX = subLayer.frame.origin.x;
        float moOrY = subLayer.frame.origin.y;
        
        float moButX = moOrX+moW;
        float moButY = moOrY+moH;
        
        //网格用整形，减少CPU开支
        //墙下标值
        int lbx,lby; lbx=lby=0;
        
        for (float i=(moOrX); ; i+=nTilingWidth) {
            
            //特殊判断 【半部分在矩形内】
            if (i>=moButX && (i-nTilingWidth)>moButX) {  break; }
            
            //执行X下标计算
            lbx = i/nTilingWidth;
            
            // 抛弃多余
            if (moButX< ((lbx)*nTilingWidth)) {  break; }
            
            //数组越界，放弃
            if (lbx>=AST_WIDE || lbx<0) { continue; }
            
            for (float j=(moOrY); ; j+=nTilingHeight) {
                
                if (j>moButY && (j-nTilingHeight)>moButY) {  break; }
                
                //执行Y下标计算
                lby = j/nTilingHeight;
                
                // 抛弃多余
                if (moButY< ((lby)*nTilingHeight)) {
                    break;
                }
                
                if (lby>=AST_LENGTH || lby<0) { //数组越界，放弃
                    continue;
                }
                
                //设置当前为墙属性
                nodeMap[lby][lbx] = 'x';
                
                /*
                CALayer *mainPath = [CALayer layer];
                
                CGRect rect = CGRectFromString(self.nodeRectMap[lby][lbx]);
                
                mainPath.frame = rect;//CGRectMake(rect.origin.x, rect.origin.y, <#CGFloat width#>, <#CGFloat height#>);
                mainPath.backgroundColor = [UIColor clearColor].CGColor;
                mainPath.borderWidth = 0.5;
                mainPath.borderColor = [UIColor redColor].CGColor;
                mainPath.transform          = subLayer.transform;
                mainPath.contentsScale      = subLayer.contentsScale;
                mainPath.rasterizationScale = subLayer.rasterizationScale;
                [self.contentView.layer addSublayer:mainPath];
                 */
            }
        }
    }
    
    //[self.contentView setNeedsDisplay];
    return;
}

/*!
 在svg上显示路径线路
 @param   <#par#> <#info#>
 @return  <#return#>
 */
-(void) displayPathOnLayerForNodeRects:(NSArray*) nodeRects SLayer:(CALayer*) sLayer ELayer:(CALayer*) eLayer
{
    //画布大小
    float canvasWidth  = self.contentView.frame.size.width;
    float canvasHeight = self.contentView.frame.size.height;
    
    //获取所有展位图形
    
    
    //画路径计算
    UIBezierPath *findPath = [UIBezierPath bezierPath];
    
    //从终点画到起点
    
    for (int i=0; i< nodeRects.count; i++) {
        
        NSString *stringRect = nodeRects[i];
        
        
        CGRect pointRect = CGRectFromString(stringRect);
        //CGRectMake(, , CGRectGetWidth(pointRect), CGRectGetHeight(pointRect))
        
        CGPoint center = CGPointMake(CGRectGetMidX(pointRect), CGRectGetMidY(pointRect));
        
        
        if (i==0) {
            [findPath moveToPoint:center];
        }
        else{
            [findPath addLineToPoint:center];
        }
    }
    
    /* 测试点2
     CGPoint p1 = CGPointMake(1, 1);
     CGPoint p2 = CGPointMake(10, 10);
     CGPoint p3 = CGPointMake(40, 20);
     CGPoint p4 = CGPointMake(30, 90);
     CGPoint p5 = CGPointMake(150, 20);
     CGPoint p6 = CGPointMake(200, 200);
     CGPoint p7 = CGPointMake(900, 900);
     
     
     [findPath moveToPoint:p1];
     [findPath addLineToPoint:p2];
     [findPath addLineToPoint:p3];
     [findPath addLineToPoint:p4];
     [findPath addLineToPoint:p5];
     [findPath addLineToPoint:p6];
     [findPath addLineToPoint:p7];
     */
    
    //测试点3
    NSArray *allRectLayer = [self.svgTool getAllRectLayer];
    CALayer *subLayer = allRectLayer[0]; //self.contentView.layer;//
    
    //findPath = [UIBezierPath bezierPathWithRect:self.contentView.layer.frame];
    //[findPath moveToPoint:subLayer.frame.origin];
    //findPath moveToPoint:subLayer.
    
    
    //[findPath closePath];
    
    //set the render colors
    //[[UIColor blackColor] setStroke];
    //[[UIColor redColor] setFill];
    
    //findPath.lineWidth = 4;
    //[findPath fill];
    //[findPath stroke];
    
    self.pathLayer = [CAShapeLayer layer];
    [self.pathLayer setFrame:self.contentView.layer.frame];
    
    self.pathLayer.path = findPath.CGPath;
    self.pathLayer.fillColor = [UIColor clearColor].CGColor;
    self.pathLayer.lineWidth =  5;
    self.pathLayer.strokeColor = [UIColor redColor].CGColor;
    
    
    //属性copy
    CALayer *beLayer = subLayer;
    
    self.pathLayer.transform          = beLayer.transform;
    self.pathLayer.contentsScale      = beLayer.contentsScale;
    self.pathLayer.rasterizationScale = beLayer.rasterizationScale;
    
    
    [self.contentView.layer addSublayer:self.pathLayer];
    
    NSLog(@"canW: %f  canH: %f ",canvasWidth,canvasHeight);
    NSLog(@"canvasFrame: %@",NSStringFromCGRect(self.contentView.frame));
    
    
    
    
    
    //显示起点、终点
    if (self.startImageIcon!=NULL) {
        [self.startImageIcon removeFromSuperlayer];
    }
    if (self.endImageIcon!=NULL) {
        [self.endImageIcon removeFromSuperlayer];
    }
    
    
    /*
    float pxWidth = 23;
    float pxHeight= 35;
    
    float pxVal = sLayer.frame.size.height/pxHeight;
    pxWidth = pxWidth*pxVal;
    */
     
    UIImage* STimage = [UIImage imageWithContentsOfFile:[MDMXIB pathForResource:@"svg_nav_start" ofType:@"png"]];
    self.startImageIcon = [CALayer layer];
    self.startImageIcon.frame = CGRectMake(2, -8, 19, 30);
    self.startImageIcon.contents = (id) STimage.CGImage;
    [sLayer addSublayer:self.startImageIcon];
    
    UIImage* EDimage = [UIImage imageWithContentsOfFile:[MDMXIB pathForResource:@"svg_nav_end" ofType:@"png"]];
    self.endImageIcon = [CALayer layer];
    self.endImageIcon.frame = CGRectMake(2, -8, 19, 30);
    self.endImageIcon.contents = (id) EDimage.CGImage;
    [eLayer addSublayer:self.endImageIcon];
    
    [self.contentView setNeedsDisplay];
    
    return;
}

// 获取可用方向瓦片
/*
 1  2   3
 4  C   6
 7  8   9
 
 取 2，6，8，4 四个方向点
 @par layerRect  SVG图形点标识Layer层
 返回值 CGPoint for String Array
 */
-(NSArray *) getUsableDirectionPointFromLayerRect:(CGRect) layerRect
{

    NSMutableArray *arUasblePoints = [[[NSMutableArray alloc] init] autorelease];
    
    float centX = layerRect.origin.x + layerRect.size.width/2.0;
    float centY = layerRect.origin.y + layerRect.size.height/2.0;
    
    //上中
    CGPoint upCt = CGPointMake(centX, layerRect.origin.y);
    
    //右中
    CGPoint rightCt = CGPointMake(layerRect.origin.x+layerRect.size.width, centY);
    
    //下中
    CGPoint downCt = CGPointMake(centX, layerRect.origin.y+layerRect.size.height);
    
    //左中
    CGPoint leftCt = CGPointMake(layerRect.origin.x, centY);
    
    int x,y;
    x=y=0;
    
    CGPoint dict4Points[]={upCt,rightCt,downCt,leftCt};
    for (int i=0; i<4; i++) {
        CGPoint pt = dict4Points[i];
        
        //1 计算该点所在的二维数组坐标位置
        x = pt.x/TilingSize; //横标
        y = pt.y/TilingSize; //纵标
        
        //2 排除4个方向点块中， 某个点块周围都是墙的点。
        int addx = x+1;
        int addy = y+1;
        int subx = x-1;
        int suby = y-1;
        
        if (addx < AST_WIDE) {
            if (nodeMap[y][addx]=='.') {
                [arUasblePoints addObject:NSStringFromCGPoint(pt)];
                continue;
            }
        }
        
        if (addy < AST_LENGTH) {
            if (nodeMap[addy][x]=='.') {
                [arUasblePoints addObject:NSStringFromCGPoint(pt)];
                continue;
            }
        }
        
        if (subx >= 0) {
            if (nodeMap[y][subx]=='.') {
                [arUasblePoints addObject:NSStringFromCGPoint(pt)];
                continue;
            }
        }
        
        if (suby >= 0) {
            if (nodeMap[suby][x]=='.') {
                [arUasblePoints addObject:NSStringFromCGPoint(pt)];
                continue;
            }
        }
    }
    
    return arUasblePoints;
}

/*!
 分析并设置起点和终点最优的二维坐标点
 @param   <#par#> <#info#>
 @return  int  0=>All OK  1=>未能设置到起点  2=>未能设置到终点
 */

-(int) analysisBestPortForBeginEleID:(CALayer*)startLayer EndEleID:(CALayer*)endLayer
{
    
    //CALayer *startLayer = [self.svgTool getRectLayerByID:beginEleID];
    if (startLayer==NULL) {
        return 1;
    }
    
    //CALayer *endLayer   = [self.svgTool getRectLayerByID:endEleID];
    if (endLayer==NULL) {
        return 2;
    }
    
    /*
    startLayer.borderColor = [UIColor blueColor].CGColor;
    startLayer.borderWidth = 4;
    
    endLayer.borderColor   = [UIColor blueColor].CGColor;
    endLayer.borderWidth = 4;
    */
    
    
    CGRect startRect = startLayer.frame;
    CGRect endRect   = endLayer.frame;
    
    
    
    //1 获取起点、终点图形所有可设置的方向点。
    
    NSArray *usableP = [self getUsableDirectionPointFromLayerRect:startRect];
    if (usableP.count==0) {
        return 1;
    }
    
    NSArray *usablePd = [self getUsableDirectionPointFromLayerRect:endRect];
    if (usablePd.count==0) {
        return 2;
    }

    //2 对比剩余的点，选择起点终中点间最相近的方向点
    typedef   struct MinDist_I_J
    {
        int i;
        int j;
    } MinDist_I_J;
    
    MinDist_I_J minDist_I_J={-1,-1};

    for (int i=0;i<usableP.count; i++) {
        
        NSString *strStartP = usableP[i];
        CGPoint startPt = CGPointFromString(strStartP);
        
        unsigned int minDist = INT_MAX;
        int jIndex=0;
        
        for (int j=0; j<usablePd.count; j++) {
            NSString *strEndP = usablePd[j];
            CGPoint endPt = CGPointFromString(strEndP);
            
            unsigned int tempDist = DistanceManhattan(startPt.x,startPt.y,endPt.x,endPt.y);
            if (minDist>tempDist) {
                minDist = tempDist;
                jIndex = j;
            }
        }
        
        if (minDist_I_J.i==-1) {
            minDist_I_J.i = i;
            minDist_I_J.j = jIndex;
        }
        else
        {
            //对比当前与上次查询
            
            //当前
            
            //上次 - minDist_I_J
            CGPoint comstartPt = CGPointFromString(usableP[minDist_I_J.i]);
            CGPoint comendPt   = CGPointFromString(usablePd[minDist_I_J.j]);
            unsigned int compDist = DistanceManhattan(comstartPt.x,comstartPt.y,comendPt.x,comendPt.y);
            if (minDist > compDist) {
                minDist_I_J.i = i;
                minDist_I_J.j = jIndex;
            }
        }
    }
    
    CGPoint startPoint = CGPointFromString(usableP[minDist_I_J.i]);
    int x = startPoint.x / TilingSize;
    int y = startPoint.y / TilingSize;
    
    //3 将选择出的两个点进行标识位设置
    
    //起点
    nodeMap[y][x] = 's';
    
    //
    
    CGPoint endPoint = CGPointFromString(usablePd[minDist_I_J.j]);
    x = endPoint.x / TilingSize;
    y = endPoint.y / TilingSize;
    
    //起点
    nodeMap[y][x] = 'd';
    
    //4 返回
    
    return 0;
}

-(void) showPathWithBeginEleID:(NSString*)beginEleID EndEleID:(NSString*)endEleID
{
    
    //清空之前的查询记录.
    [self clearTapLayer:nil];
    [self.pathLayer removeFromSuperlayer];
    self.pathLayer = nil;
    
    
    [self showTapLayerForListID:@[endEleID,beginEleID]];
    //重新初使化数据结构信息
    
    [self initSVGToTilingArray];
    //CGRect
    
    
    CALayer *startLayer = [self.svgTool getRectLayerByID:beginEleID];
    if (startLayer==NULL) {
  
    }
    
    CALayer *endLayer   = [self.svgTool getRectLayerByID:endEleID];
    if (endLayer==NULL) {
    }
    
    int retuVal = [self analysisBestPortForBeginEleID:startLayer EndEleID:endLayer];
    if (retuVal==1) {
        SH_Alert(@"路径规化失败，未能找到[起点]的可用路径信息.");
        return;
    }
    else if (retuVal==2)
    {
        SH_Alert(@"路径规化失败，未能找到[终点]的可用路径信息.");
        return;
    }
    
    //启动查找算法
    //c版本
    OpenList *sopenList   = malloc(sizeof(OpenList));
    sopenList->next = NULL;
    sopenList->opennode =NULL;
    
    CloseList *scloseList = malloc(sizeof(CloseList));
    scloseList->next = NULL;
    scloseList->closenode=NULL;
    
    SetFactNodeMapSize(AST_WIDE, AST_LENGTH);
    InitNodeMap(nodeMap, sopenList);
    
    BOOL isSuc=YES;
    NSMutableArray *arPathNodePoints = [[[NSMutableArray alloc] init] autorelease];
    
    if((isSuc=FindDestinnation(sopenList, scloseList)))
    {
        TNode tempnode = m_node[endpoint_y][endpoint_x];
        
        if (tempnode.parent==NULL) {
            
           // NSLog(@"查找失败");
            isSuc = NO;
        }
        else{
            while(tempnode.parent!=NULL && tempnode.flag!=STARTPOINT )
            {
                
                /*
                 if (tempnode.flag!=DESTINATION) {
                 //continue;
                 
                 //UIView *subView = self.nodeViewMap[tempnode.location_y][tempnode.location_x];
                 //subView.backgroundColor = [UIColor redColor];
                 }*/
                
                [arPathNodePoints addObject:self.nodeRectMap[tempnode.location_y][tempnode.location_x]];
                
                NSLog(@"x: %d , y:%d",tempnode.location_x,tempnode.location_y);
                
                tempnode = *tempnode.parent;
            }
            
            //加入起点
            [arPathNodePoints addObject:self.nodeRectMap[tempnode.location_y][tempnode.location_x]];
        }
    }
    
    
    //显示路径
    if (isSuc) {
        [self displayPathOnLayerForNodeRects:arPathNodePoints SLayer:startLayer ELayer:endLayer];
    }
    else{
        //失败!
        SH_Alert(@"寻路失败! 未能找到起点与终点间可用的通行路径.");
        NSLog(@"寻路失败! 未能找到起点与终点间可用的通行路径.");
    }
    
    //释放相关的内存
    /*
    while (sopenList!=nil) {
        TNode *temp = sopenList->opennode;
        if (temp!=NULL) {
            //free(temp);
            sopenList->opennode = nil;
        }
        OpenList *tempOpen = sopenList->next;
        free(sopenList);
        sopenList = tempOpen;
    }
    
    while (scloseList!=nil) {
        TNode *temp = scloseList->closenode;
        if (temp!=NULL) {
            //free(temp);
            scloseList->closenode = nil;
        }
        CloseList *tempOpen = scloseList->next;
        free(scloseList);
        scloseList = tempOpen;
    }
     */
    //TNode relsNode=
    
}
@end
