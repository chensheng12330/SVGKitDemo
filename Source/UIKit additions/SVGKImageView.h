#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import "SVGKImage.h" // cannot import "SVGKit.h" because that would cause ciruclar imports

/**
 * SVGKit's version of UIImageView - with some improvements over Apple's design. There are multiple versions of this class, for different use cases.
 
 STANDARD USAGE:
   - SVGKImageView *myImageView = [[SVGKFastImageView alloc] initWithSVGKImage: [SVGKImage imageNamed:@"image.svg"]];
   - [self.view addSubview: myImageView];
 
 NB: the "SVGKFastImageView" is the one you want 9 times in 10. The alternative classes (e.g. SVGKLayeredImageView) are for advanced usage.
 
 NB: read the class-comment for each subclass carefully before deciding what to use.
 
 */

@class SVGKImageView;

@protocol SVGKImageViewDelegate <NSObject>
-(void) willDrawSVGView;  //将要开始绘制图层
-(void) didDrawSVGView;   //完成图层绘制，即将显示
@end

@interface SVGKImageView : UIView

@property(nonatomic,retain) SVGKImage* image;
@property(nonatomic) BOOL showBorder; /*< mostly for debugging - adds a coloured 1-pixel border around the image */

- (id)initWithSVGKImage:(SVGKImage*) im;

//  add new propert
@property(nonatomic) BOOL noDraw;
@property (nonatomic, assign) id<SVGKImageViewDelegate> delegate;

@end
