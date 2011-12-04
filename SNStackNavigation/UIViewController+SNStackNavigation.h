//
//  UIViewController+StackNavigation.h
//  StackedNavigationSample
//
//  Created by Shu MASUDA on 2011/12/04.
//

#import <UIKit/UIKit.h>


@class SNStackNavigationController;


@interface UIViewController (SNStackNavigation)

- (SNStackNavigationController *)stackNavigationController;
- (CGFloat)contentWidthForViewInStackNavigation;

@end
