//
//  SNStackNavigationController.h
//  StackedNavigationSample
//
//  Created by Shu MASUDA on 2011/12/04.
//  Copyright (c) 2012 Shu MASUDA. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol SNStackNavigationControllerDelegate;


#pragma mark - SNStackNavigationController Interface


@interface SNStackNavigationController : UIViewController

#pragma mark - Public Properties

@property (nonatomic, readonly) UIViewController    *rootViewController;
@property (nonatomic, readonly) NSArray             *viewControllers;

@property (nonatomic)           CGFloat             tabWidth;
@property (nonatomic)           CGFloat             minimumTabWidth;

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_5_0

@property (weak, nonatomic)                 id<SNStackNavigationControllerDelegate> delegate;

#else

@property (unsafe_unretained, nonatomic)    id<SNStackNavigationControllerDelegate> delegate;

#endif

#pragma mark - Public Methods

- (void)pushViewController:(UIViewController *)viewController
        fromViewController:(UIViewController *)fromViewController
                  animated:(BOOL)animated;
- (void)popToViewController:(UIViewController *)viewController
                   animated:(BOOL)animated;

@end


#pragma mark - SNStackNavigationControllerDelegate Protocol


@protocol SNStackNavigationControllerDelegate
<
    NSObject
>

@optional

- (void)stackNavigationControllerBeginCuttingDown:(SNStackNavigationController *)stackNavigationController;
- (void)stackNavigationControllerCancelCuttingDown:(SNStackNavigationController *)stackNavigationController;
- (void)stackNavigationControllerWillCuttingDown:(SNStackNavigationController *)stackNavigationController;
- (void)stackNavigationControllerDidCuttingDown:(SNStackNavigationController *)stackNavigationController;

- (void)stackNavigationController:(SNStackNavigationController *)stackNavigationController
             didAddViewController:(UIViewController *)viewController;
- (void)stackNavigationController:(SNStackNavigationController *)stackNavigationController
            willAddViewController:(UIViewController *)viewController;

- (void)stackNavigationController:(SNStackNavigationController *)stackNavigationController
         willRemoveViewController:(UIViewController *)viewController;
- (void)stackNavigationController:(SNStackNavigationController *)stackNavigationController
          didRemoveViewController:(UIViewController *)viewController;

@end
