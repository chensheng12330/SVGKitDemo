//
//  SHTapView.m
//  MDMEngine
//
//  Created by sherwin on 14-7-3.
//  Copyright (c) 2014年 wireless. All rights reserved.
//

#import "SHTapView.h"

@implementation SHTapView

- (id)initWithFrame:(CGRect)frame colorTag:(int)tp
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.backgroundColor = tp==0?[UIColor redColor]:[UIColor greenColor];
        self.alpha = 0.45;
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)dealloc
{
    self.name = nil;
    [super dealloc];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
