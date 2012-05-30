//
//  SNStackNavigationContentView.h
//  StackNavigationSample
//
//  Created by Shu MASUDA on 2011/12/28.
//  Copyright (c) 2012 Shu MASUDA. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SNStackNavigationContentView : UIView

#pragma mark - Public Properties

@property (nonatomic)   CGFloat         tabWidth;
@property (nonatomic)   CGFloat         minimumTabWidth;
@property (nonatomic)   CGFloat         shadowWidth;

@property (readonly, nonatomic) CALayer *leftMaskLayer;
@property (readonly, nonatomic) CALayer *rightMaskLayer;

@property (readonly, nonatomic) UIView  *stackedViews;
@property (nonatomic)   UIView          *leftView;
@property (nonatomic)   UIView          *rightView;
@property (nonatomic)   UIView          *moreLeftView;
@property (nonatomic)   UIView          *moreRightView;

@end
