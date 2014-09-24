//
//  SHSVGTool.h
//  SVGKit-iOS
//
//  Created by sherwin on 14-6-9.
//  Copyright (c) 2014年 na. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVGKImage.h"

@interface SHSVGTool : NSObject
@property (nonatomic, assign) SVGKImage *svgImage;

/*!
 根据SVGKimage，进行初使化本类。
 */
-(id) initWithSVGKImage:(SVGKImage *)svgImage;


/*!
 获取SVG Layer Tree的所有Rect对象。
 */
-(void) analysisSVGToRectLayerMap;

/*!
 根据元素id,获取文字
 */
-(NSString*) getTextByID:(NSString*) elementId;

/*!
 根据元素id,获取Rect图层
 */
-(CALayer*)  getRectLayerByID:(NSString*) elementId;
-(NSArray*)  getAllRectLayer;

/*!
 查找关键字
 */
-(NSDictionary*) searchStringWithKey:(NSString*) key;
@end
