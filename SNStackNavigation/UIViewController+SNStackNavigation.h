//
//  UIViewController+StackNavigation.h
//  StackedNavigationSample
//
//  Created by Shu MASUDA on 2011/12/04.
//

#import <UIKit/UIKit.h>


typedef enum
{
    SNStackNavigationInsertPositionDefault,
    SNStackNavigationInsertPositionUnFolded,
} SNStackNavigationInsertPositionType;


@class SNStackNavigationController;


@interface UIViewController (SNStackNavigation)

- (SNStackNavigationController *)stackNavigationController;
- (CGFloat)contentWidthForViewInStackNavigation;
- (SNStackNavigationInsertPositionType)insertedPosition;

@end
