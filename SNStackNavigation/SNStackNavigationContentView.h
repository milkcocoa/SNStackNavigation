//
//  SNStackNavigationContentView.h
//  StackNavigationSample
//
//  Created by Shu MASUDA on 2011/12/28.
//

#import <UIKit/UIKit.h>


@interface SNStackNavigationContentView : UIView

#pragma mark - Public Properties

@property (nonatomic)   CGFloat                 tabWidth;
@property (nonatomic)   CGFloat                 minimumTabWidth;

@property (strong, readonly, nonatomic) UIView  *stackedViews;
@property (strong, nonatomic)   UIView          *leftView;
@property (strong, nonatomic)   UIView          *rightView;
@property (strong, nonatomic)   UIView          *moreLeftView;
@property (strong, nonatomic)   UIView          *moreRightView;

@end
