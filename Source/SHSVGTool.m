//
//  SHSVGTool.m
//  SVGKit-iOS
//
//  Created by sherwin on 14-6-9.
//  Copyright (c) 2014年 na. All rights reserved.
//

#import "SHSVGTool.h"
//#define SVG_Text_ID @""

@interface SHSVGTool ()
@property (nonatomic, assign) SVGDocument *DOM;
@property (nonatomic, retain) NodeList *textlist;

@property (nonatomic, retain) NSMutableDictionary *textMap;
@property (nonatomic, retain) NSMutableDictionary *rectLayerMap;
@end


@implementation SHSVGTool
- (void)dealloc
{
    self.DOM      = nil;
    self.textlist = nil;
    
    self.textMap  = nil;
    self.rectLayerMap=nil;
    [super dealloc];
}

-(id) initWithSVGKImage:(SVGKImage *)svgImage
{
    self = [super init];
    
    NSAssert(svgImage, @"我操，传错值了.");
    
    self.svgImage = svgImage;
    self.DOM = self.svgImage.DOMDocument;
    
    self.textlist = [_DOM getElementsByTagName:@"text"];
    
    self.textMap = nil;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //[self processTextMap];
        
        [self processRectLayerMap];
    });
    /*
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
    });
     */
    
    return self;
}

/*!
 process text.  replacing text for  \n \t and space
 */
- (NSString *)stripText:(NSString *)text
{
    // Remove all newline characters
    text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    // Convert tabs into spaces
    text = [text stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    // Consolidate all contiguous space characters

    // Remove leading and trailing spaces
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return text;
}


-(NSString*) getTextByID:(NSString*) elementId
{
    NSAssert(elementId, @"我了个去,传了个空值.");
    
    if(self.textlist==NULL || _textlist.length==0) return nil;
    
    //Begain
    if (self.textMap) {
        NSString *retuText = self.textMap[elementId];
        if (retuText) {  return retuText; }
    }
    
    //not get text, search text on document.
    
    SVGElement *searchElem=nil;
    NSString   *searchText=nil;
    
    // 1  search node.
    for (SVGElement *textElem in _textlist) {
        if ([textElem.identifier  isEqualToString:elementId]) {
            searchElem = textElem;
            break;
        }
    }
    
    if (searchElem==nil) return nil;
    
    // 2  get text.
    
    //-- 2.1 get text from tspan
    if (searchElem.childNodes.length>1) {
        NSMutableString *str = [NSMutableString new];
        for (Node *node in searchElem.childNodes) {
            
            //NSLog(@"%@",node.textContent);
            if (node.nodeType==DOMNodeType_ELEMENT_NODE) {
                [str appendString:node.textContent];
            }
            
        }
        searchText = [self stripText:str];
        [str release];
    }
    //-- 2.2 get text from text
    else
    {
        searchText = [self stripText:searchElem.textContent];
    }
    
    //ok return text
    
    return searchText;
}

-(NSArray*)  getAllRectLayer
{
    return [self.rectLayerMap allValues];
}

-(CALayer*)  getRectLayerByID:(NSString*) elementId
{
    NSAssert(elementId, @"我了个去,传了个空值.");
    
    //- 1
    if (self.rectLayerMap==NULL) {   return nil; }
    
    return self.rectLayerMap[elementId];
}

-(NSDictionary*) searchStringWithKey:(NSString*) tkey
{
    NSAssert(tkey, @"我了个去,传了个空值.你这是在玩哥!");
    
    //-1 textMap search.
    NSMutableDictionary *seaValue= [NSMutableDictionary new];
    
    for (NSString *key in  self.textMap.allKeys) {
        
        NSString *tempStr = self.textMap[key];
        if ([tempStr rangeOfString:tkey].length > 0) {
            [seaValue setValue:tempStr forKey:key];
        }
    }
    
    //-2 element Root search.

    return [seaValue autorelease];
}

#pragma mark - Process Data
-(void) processTextMap
{
    if(self.textlist==NULL || _textlist.length==0 || self.textMap!=NULL) return;
    
    self.textMap = [[NSMutableDictionary new] autorelease];
    
    for (SVGElement *textElem in _textlist) {
        
        if (textElem.identifier==NULL || [textElem.identifier isEqualToString:@""]) {continue;}
        NSString *textString=nil;
        
        if (textElem.childNodes.length>1) {
            NSMutableString *str = [NSMutableString new];
            for (Node *node in textElem.childNodes) {
                
                //NSLog(@"%@",node.textContent);
                if (node.nodeType==DOMNodeType_ELEMENT_NODE) {
                    [str appendString:node.textContent];
                }
                
            }
            textString = [self stripText:str];
            [str release];
        }
        //-- 2.2 get text from text
        else
        {
            textString = [self stripText:textElem.textContent];
        }
        
        NSLog(@"TextMap: %@-%@",textElem.identifier, textString);
        [self.textMap setObject:textString forKey:textElem.identifier];
    }
}

-(void) analysisSVGToRectLayerMap
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self processRectLayerMap];
        
        
    });
}

-(void) processRectLayerMap
{
    NSArray *treeList = self.svgImage.CALayerTree.sublayers;
    if (treeList==NULL || treeList.count==0 ) { return; }
    
    self.rectLayerMap = [[[NSMutableDictionary alloc] init] autorelease];
    
    for (CALayer *subLayer in treeList) {
        
        NSLog(@"%@",subLayer.name);
        
        if (subLayer.name && ([subLayer isKindOfClass:NSClassFromString(@"CAShapeLayerWithHitTest")] || [subLayer isKindOfClass:NSClassFromString(@"CALayerWithChildHitTest")])) {
            [self.rectLayerMap setObject:subLayer forKey:subLayer.name];
            //NSLog(@"RectMap: %@",subLayer);
        }
    }
}
@end
