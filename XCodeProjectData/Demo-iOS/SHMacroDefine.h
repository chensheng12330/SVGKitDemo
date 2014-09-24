//
//  SHMacroDefine.h
//  TestFrame
//
//  Created by sherwin.chen on 13-6-15.
//  Copyright (c) 2013年 sherwin.chen. All rights reserved.
//

#ifndef SHMacroDefine
#define SHMacroDefine


#define NavigationBar_HEIGHT 44

#define SH_SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SH_SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

#define SH_SAFE_RELEASE(x) [x release];x=nil
#define SH_IOS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]
#define SH_CurrentSystemVersion ([[UIDevice currentDevice] systemVersion])
#define SH_CurrentLanguage ([[NSLocale preferredLanguages] objectAtIndex:0])
#define SH_BACKGROUND_COLOR [UIColor colorWithRed:242.0/255.0 green:236.0/255.0 blue:231.0/255.0 alpha:1.0]

#define SH_CLEARCOLOR [UIColor clearColor]

//devices
#define DEVICE_IS_IPHONE5 ([[UIScreen mainScreen] bounds].size.height >= 568)
#define DEVICE_IS_IPHONE4 ([[UIScreen mainScreen] bounds].size.height == 480)

#define DEVICE_IS_IOS7 ([[[UIDevice currentDevice] systemVersion] floatValue]>=7.0)
#define DEVICE_IS_480IOS7 (SH_SCREEN_HEIGHT==480 && DEVICE_IS_IOS7)

//file dir
#define SH_LibraryDir ([NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0])
#define SH_FileMag ([NSFileManager defaultManager])


//use dlog to print while in debug model
#define DEBUG 1
#ifdef DEBUG
#   define DLog(fmt, ...) {NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);}
#   define ELog(err) {if(err) DLog(@"%@", err)}
#else
#   define DLog(...)
#   define ELog(err)
#endif

//use JS Function Interaction
#define JSDebugAlert(info) {UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"JS调试出错!" message:info delegate:nil cancelButtonTitle:@"马上修改" otherButtonTitles:nil];\
[alert show];[alert release];}

#define JSGetArgmForNumber(argument) ([argument isKindOfClass:[NSNumber class]] ? argument:[argument isKindOfClass:[NSString class]]?[NSNumber numberWithDouble:[argument doubleValue]]:NULL)
#define JSGetArgmForString(argument) ([argument isKindOfClass:[NSString class]] ? argument:[argument isKindOfClass:[NSNumber class]]?[argument stringValue]:NULL)


#define MDMXIB [NSBundle mainBundle]
#define SH_Window [[UIApplication sharedApplication].windows lastObject]
#define SH_Alert(info) [[[[UIAlertView alloc] initWithTitle:@"温馨提示" message:info delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil] autorelease] show];

//exception info
#define SHExcpInfo(xx, ...) [NSString stringWithFormat:@"%s(%d): " xx, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__]
#define SHExcp(er_lvl,er_info) ([NSException exceptionWithName:er_lvl reason: SHExcpInfo(@"内部异常: %@",er_info) userInfo:nil])

#define SH_isRetina ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
#define SH_iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

//方正黑体简体字体定义
#define FONT(F) [UIFont fontWithName:@"FZHTJW--GB1-0" size:F]

//安全删除对象
#define SAFE_DELETE(P) if(P) { [P release], P = nil; }

#if TARGET_OS_IPHONE
//iPhone Device
#endif

#if TARGET_IPHONE_SIMULATOR
//iPhone Simulator
#endif

//文件管理
//缓存目录
#define SH_DefaultCaches  NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)
#define SH_DefaultFileManager              [NSFileManager defaultManager]

//判断类是否可用
#define SH_USABLE_CLASS(a)    ([UICollectionView class]==NULL?FALSE:TRUE)
#define SH_USABLE_SELECTOR(c,s) ([c instancesRespondToSelector:s]==NULL?FALSE:TRUE)

///字符串NULL处理
#define StringNULL(string) (string==NULL?@"":string)
#define SH_isStringNull(strV) ((strV==NULL||[strV isEqualToString:@""])?1:0)

//ARC
#if __has_feature(objc_arc)
//compiling with ARC
#else
// compiling without ARC
#endif


//G－C－D
#define BACK(block) dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
#define MAIN(block) dispatch_async(dispatch_get_main_queue(),block)


#define SH_USER_DEFAULT [NSUserDefaults standardUserDefaults]
#define SH_ImageNamed(_pointer) [UIImage imageNamed:[UIUtil imageName:_pointer]]


#pragma mark - common functions
#define RELEASE_SAFELY(__POINTER) { [__POINTER release]; __POINTER = nil; }


#pragma mark - degrees/radian functions
#define degreesToRadian(x) (M_PI * (x) / 180.0)
#define radianToDegrees(radian) (radian*180.0)/(M_PI)

#pragma mark - color functions
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:(a)]
#define ITTDEBUG
#define ITTLOGLEVEL_INFO     10
#define ITTLOGLEVEL_WARNING  3
#define ITTLOGLEVEL_ERROR    1

#ifndef ITTMAXLOGLEVEL

#ifdef DEBUG
#define ITTMAXLOGLEVEL ITTLOGLEVEL_INFO
#else
#define ITTMAXLOGLEVEL ITTLOGLEVEL_ERROR
#endif

#endif

// The general purpose logger. This ignores logging levels.
#ifdef ITTDEBUG
#define ITTDPRINT(xx, ...)  NSLog(@"%s(%d): " xx, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define ITTDPRINT(xx, ...)  ((void)0)
#endif

// Prints the current method's name.
#define ITTDPRINTMETHODNAME() ITTDPRINT(@"%s", __PRETTY_FUNCTION__)

// Log-level based logging macros.
#if ITTLOGLEVEL_ERROR <= ITTMAXLOGLEVEL
#define ITTDERROR(xx, ...)  ITTDPRINT(xx, ##__VA_ARGS__)
#else
#define ITTDERROR(xx, ...)  ((void)0)
#endif

#if ITTLOGLEVEL_WARNING <= ITTMAXLOGLEVEL
#define ITTDWARNING(xx, ...)  ITTDPRINT(xx, ##__VA_ARGS__)
#else
#define ITTDWARNING(xx, ...)  ((void)0)
#endif

#if ITTLOGLEVEL_INFO <= ITTMAXLOGLEVEL
#define ITTDINFO(xx, ...)  ITTDPRINT(xx, ##__VA_ARGS__)
#else
#define ITTDINFO(xx, ...)  ((void)0)
#endif

#ifdef ITTDEBUG
#define ITTDCONDITIONLOG(condition, xx, ...) { if ((condition)) { \
ITTDPRINT(xx, ##__VA_ARGS__); \
} \
} ((void)0)
#else
#define ITTDCONDITIONLOG(condition, xx, ...) ((void)0)
#endif

#define ITTAssert(condition, ...)                                       \
do {                                                                      \
if (!(condition)) {                                                     \
[[NSAssertionHandler currentHandler]                                  \
handleFailureInFunction:[NSString stringWithUTF8String:__PRETTY_FUNCTION__] \
file:[NSString stringWithUTF8String:__FILE__]  \
lineNumber:__LINE__                                  \
description:__VA_ARGS__];                             \
}                                                                       \
} while(0)


#endif


