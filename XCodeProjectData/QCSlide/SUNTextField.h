//
//  SUNTextField.h
//  SUNCommonComponent
//
//  Created by sh on 13-8-21.
//  Copyright (c) 2013年 sh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SUNTextField : UITextField
{
    UILabel *_customerLeftView;
    UIColor *_placeHolderColor;
    CGFloat _cornerRadius;
    UIColor *_backgroundColor;
}

@property (nonatomic, strong) IBOutlet UILabel *customerLeftView;
@property (nonatomic, strong) UIColor *placeHolderColor;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, strong) UIColor *backgroundColor;

@end
