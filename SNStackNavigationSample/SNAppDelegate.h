//
//  SNAppDelegate.h
//  StackedNavigationSample
//
//  Created by Shu MASUDA on 2011/12/04.
//  Copyright (c) 2012 Shu MASUDA. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SNRootViewController;

#pragma mark - LDAppDelegate

@interface SNAppDelegate : UIResponder
<
    UIApplicationDelegate
>

#pragma mark - Public Properties

@property (strong, nonatomic) SNRootViewController  *rootViewController;
@property (strong, nonatomic) UIWindow              *window;

#pragma mark - Public Methods

@end
