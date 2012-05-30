//
//  UIViewController+StackNavigation.m
//  StackedNavigationSample
//
//  Created by Shu MASUDA on 2011/12/04.
//  Copyright (c) 2012 Shu MASUDA. All rights reserved.
//

#import "UIViewController+SNStackNavigation.h"

#import <objc/runtime.h>

#import "SNStackNavigationControllerConstants.h"


@implementation UIViewController (SNStackNavigation)


- (SNStackNavigationController *)stackNavigationController
{
    return objc_getAssociatedObject(self, SNStackNavigationControllerKey);
}


- (CGFloat)contentWidthForViewInStackNavigation
{
    return 476;
}


- (SNStackNavigationInsertPositionType)insertedPosition
{
    return SNStackNavigationInsertPositionDefault;
}


@end
