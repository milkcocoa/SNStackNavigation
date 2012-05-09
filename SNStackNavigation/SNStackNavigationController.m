//
//  SNStackNavigationController.m
//  StackedNavigationSample
//
//  Created by Shu Masuda on 2011/12/04.
//

#import "SNStackNavigationController.h"

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

#import "SNStackNavigationControllerConstants.h"

#import "SNStackNavigationContentView.h"


static CGFloat const _SNStackNavigationDefaultToolbarWidth          = 292;
static CGFloat const _SNStackNavigationDefaultToolbarMinimumWidth   = 72;
static CGFloat const _SNStackNavigationCutDownWidth                 = 120;
static CGFloat const _SNStackNavigationMoveFrictionCoEfficient      = 0.5;
static CGFloat const _SNStackNavigationAnimationDuration            = 0.2;
static CGFloat const _SNStackNavigationBounceAnimationDuration      = 0.2;
static CGFloat const _SNStackNavigationMoveOffset                   = 10;

static NSString * const _SNStackNavigationWillCuttingDownObservingKey   = @"_willCuttingDown";

typedef enum
{
    _SNStackNavigationDragDirectionNone,
    _SNStackNavigationDragDirectionLeft,
    _SNStackNavigationDragDirectionRight,
} _SNStackNavigationDragDirectionType;


typedef enum
{
    _SNStackNavigationStateNone,
    _SNStackNavigationStateL,
    _SNStackNavigationStateLR,
    _SNStackNavigationStateLRMR,
    _SNStackNavigationStateMLLR,
    _SNStackNavigationStateMLLRMR,
} _SNStackNavigationStateType;


#define CONTENT_VIEW (SNStackNavigationContentView *)[self view]
#define STACKED_VIEWS [CONTENT_VIEW stackedViews]
#define STACKED_VIEWS_FRAME [STACKED_VIEWS frame]
#define STACKED_VIEWS_CONCRETE [STACKED_VIEWS subviews]
#define IS_VIEW_ROOT_VIEW(_view) ([[STACKED_VIEWS subviews] indexOfObject:_view] == 0)

#define _VIEW(_viewName) [CONTENT_VIEW _viewName]
#define _VIEW_FRAME(_name) [_name frame]
#define _SET_VIEW_FRAME(_name, _x, _y, _width, _height) [_name setFrame:CGRectMake((_x), (_y), (_width), (_height))]
#define _SET_VIEW_X(_name, _x) _SET_VIEW_FRAME(_name, floorf(_x), 0, CGRectGetWidth([_name frame]), CGRectGetHeight([_name frame]))

#define LEFT_VIEW _VIEW(leftView)
#define LEFT_VIEW_FRAME _VIEW_FRAME(LEFT_VIEW)
#define LEFT_VIEW_SET_X(_x) _SET_VIEW_X(LEFT_VIEW, _x)

#define RIGHT_VIEW _VIEW(rightView)
#define RIGHT_VIEW_FRAME _VIEW_FRAME(RIGHT_VIEW)
#define RIGHT_VIEW_SET_X(_x) _SET_VIEW_X(RIGHT_VIEW, _x)
#define RIGHT_VIEW_FOLDED_X (CGRectGetWidth([STACKED_VIEWS bounds]) - CGRectGetWidth([RIGHT_VIEW frame]))

#define MORE_LEFT_VIEW [CONTENT_VIEW moreLeftView]
#define MORE_LEFT_VIEW_FRAME _VIEW_FRAME(MORE_LEFT_VIEW)
#define MORE_LEFT_VIEW_SET_X(_x) _SET_VIEW_X(MORE_LEFT_VIEW, _x)

#define MORE_RIGHT_VIEW [CONTENT_VIEW moreRightView]
#define MORE_RIGHT_VIEW_FRAME _VIEW_FRAME(MORE_RIGHT_VIEW)
#define MORE_RIGHT_VIEW_SET_X(_x) _SET_VIEW_X(MORE_RIGHT_VIEW, _x)


#pragma mark - SNStackNavigationController () Interface


@interface SNStackNavigationController ()

#pragma mark - Private Properties

@property (nonatomic)   CGFloat         _tabEndX;
@property (nonatomic)   NSMutableArray  *_viewControllers;
@property (nonatomic)   BOOL            _willCuttingDown;

#pragma mark - Private Methods

- (void)_initializeViewControllers;
- (void)_initializeWillCuttingDown;

- (void)_initializeContentView;
- (void)_initializePanGesture;

- (CGFloat)_tabFoldedWidth;

- (void)_registerViewController:(UIViewController *)viewController;
- (void)_unregisterViewController:(UIViewController *)viewController;

- (void)_onPanGesture:(UIPanGestureRecognizer *)recognizer;

- (void)_updateCornerRadius;

- (_SNStackNavigationStateType)_decideMainState;

- (void)_moveToStateL:(_SNStackNavigationDragDirectionType)dragDirection;
- (void)_cutDownViewControllersExceptRootViewController;
- (void)_moveToStateLRWithRightDirection;
- (void)_moveToStateMLLRWithRightDirection;
- (void)_moveToStateMLLRMRWithLeftDirection;
- (void)_moveToState:(_SNStackNavigationDragDirectionType)dragDirection;

@end


#pragma mark - SNStackNavigationController


@implementation SNStackNavigationController


#pragma mark - Properties


@synthesize _tabEndX;
@synthesize _viewControllers;
@synthesize _willCuttingDown;

@synthesize delegate = _delegate;
@synthesize minimumTabWidth = _minimumTabWidth;
@synthesize tabWidth = _tabWidth;


- (void)setMinimumTabWidth:(CGFloat)minimumTabWidth
{
    if (_minimumTabWidth != minimumTabWidth)
    {
        _minimumTabWidth = minimumTabWidth;

        _tabEndX = _tabWidth - _minimumTabWidth;
    }
}


- (void)setTabWidth:(CGFloat)tabWidth
{
    if (_tabWidth != tabWidth)
    {
        _tabWidth = tabWidth;

        _tabEndX = _tabWidth - _minimumTabWidth;
    }
}


- (UIViewController *)rootViewController
{
    if ([_viewControllers count])
    {
        return [_viewControllers objectAtIndex:0];
    }

    return nil;
}


- (NSArray *)viewControllers
{
    return [NSArray arrayWithArray:_viewControllers];
}


#pragma mark -


- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _tabWidth           = _SNStackNavigationDefaultToolbarWidth;
        _minimumTabWidth    = _SNStackNavigationDefaultToolbarMinimumWidth;
        _tabEndX            = _tabWidth - _minimumTabWidth;

        [self _initializeViewControllers];
        [self _initializeWillCuttingDown];
    }

    return self;
}


- (void)_initializeViewControllers
{
    [self set_viewControllers:[NSMutableArray array]];
}


- (void)_initializeWillCuttingDown
{
    _willCuttingDown = NO;

    [self addObserver:self
           forKeyPath:_SNStackNavigationWillCuttingDownObservingKey
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
              context:NULL];
}


- (void)dealloc
{
    [self removeObserver:self forKeyPath:_SNStackNavigationWillCuttingDownObservingKey];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:_SNStackNavigationWillCuttingDownObservingKey])
    {
        if ([[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[change objectForKey:NSKeyValueChangeOldKey]])
        {
            return;
        }

        if (_willCuttingDown)
        {
            if ([_delegate respondsToSelector:@selector(stackNavigationControllerBeginCuttingDown:)])
            {
                [_delegate stackNavigationControllerBeginCuttingDown:self];
            }
        }
        else
        {
            if ([_delegate respondsToSelector:@selector(stackNavigationControllerCancelCuttingDown:)])
            {
                [_delegate stackNavigationControllerCancelCuttingDown:self];
            }
        }
    }
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    [self _initializeContentView];
    [self _initializePanGesture];
}


- (void)_initializeContentView
{
    SNStackNavigationContentView    *contentView;

    contentView = [[SNStackNavigationContentView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self setView:contentView];

    [contentView setAutoresizesSubviews:YES];
    [contentView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [contentView setMinimumTabWidth:_minimumTabWidth];
    [contentView setTabWidth:_tabWidth];
}


- (void)_initializePanGesture
{
    UIPanGestureRecognizer  *recognizer;

    recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                         action:@selector(_onPanGesture:)];
    [[self view] addGestureRecognizer:recognizer];

    [recognizer setMaximumNumberOfTouches:1];
    [recognizer setDelaysTouchesBegan:YES];
    [recognizer setDelaysTouchesEnded:YES];
    [recognizer setCancelsTouchesInView:YES];
}


/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad
 {
 [super viewDidLoad];
 }
 */


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    for (UIViewController *viewController in _viewControllers)
    {
        if ([viewController view] == LEFT_VIEW)
        {
            CGFloat             viewWidth;
            CGRect              frame;

            viewWidth = [viewController contentWidthForViewInStackNavigation];

            frame = CGRectMake(0,
                               0,
                               viewWidth,
                               CGRectGetHeight([[self view] bounds]));

            if (RIGHT_VIEW)
            {
                frame.origin.x = CGRectGetMinX([LEFT_VIEW frame]);
            }
            else
            {
                switch ([viewController insertedPosition])
                {
                    case SNStackNavigationInsertPositionDefault:
                    {
                        frame.origin.x = _tabEndX;
                        break;
                    }

                    case SNStackNavigationInsertPositionUnFolded:
                    {
                        frame.origin.x = CGRectGetWidth([STACKED_VIEWS frame]) - viewWidth;
                        break;
                    }

                    default:
                        break;
                }
            }

            [LEFT_VIEW setFrame:frame];
        }
    }


    for (UIViewController *viewController in _viewControllers)
    {
        [viewController willRotateToInterfaceOrientation:toInterfaceOrientation
                                                duration:duration];
    }
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    for (UIViewController *viewController in _viewControllers)
    {
        [viewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
}


- (CGFloat)_tabFoldedWidth
{
    return _tabWidth - _minimumTabWidth;
}


- (void)_registerViewController:(UIViewController *)viewController
{
    if ([_delegate respondsToSelector:@selector(stackNavigationController:willAddViewController:)])
    {
        [_delegate stackNavigationController:self
                       willAddViewController:viewController];
    }

    [_viewControllers addObject:viewController];

    objc_setAssociatedObject(viewController, SNStackNavigationControllerKey, self, OBJC_ASSOCIATION_ASSIGN);

    if ([_delegate respondsToSelector:@selector(stackNavigationController:didAddViewController:)])
    {
        [_delegate stackNavigationController:self
                        didAddViewController:viewController];
    }
}


- (void)_unregisterViewController:(UIViewController *)viewController
{
    if ([_delegate respondsToSelector:@selector(stackNavigationController:willRemoveViewController:)])
    {
        [_delegate stackNavigationController:self
                    willRemoveViewController:viewController];
    }

    [[viewController view] removeFromSuperview];

    [_viewControllers removeObject:viewController];

    objc_setAssociatedObject(viewController, SNStackNavigationControllerKey, nil, OBJC_ASSOCIATION_ASSIGN);

    if ([_delegate respondsToSelector:@selector(stackNavigationController:didRemoveViewController:)])
    {
        [_delegate stackNavigationController:self
                     didRemoveViewController:viewController];
    }
}


- (_SNStackNavigationStateType)_decideMainState
{
    if (!LEFT_VIEW)
    {
        return _SNStackNavigationStateNone;
    }

    if (!RIGHT_VIEW)
    {
        return _SNStackNavigationStateL;
    }

    if (!MORE_LEFT_VIEW && !MORE_RIGHT_VIEW)
    {
        return _SNStackNavigationStateLR;
    }

    if (!MORE_LEFT_VIEW)
    {
        return _SNStackNavigationStateLRMR;
    }

    if (!MORE_RIGHT_VIEW)
    {
        return _SNStackNavigationStateMLLR;
    }

    return _SNStackNavigationStateMLLRMR;
}


- (void)_moveToStateL:(_SNStackNavigationDragDirectionType)dragDirection
{
    void (^animationBlock)(void);
    void (^completionBlock)(BOOL);

    int offsetDirection;

    offsetDirection = dragDirection == _SNStackNavigationDragDirectionLeft ? 1 : -1;

    animationBlock = ^(void)
    {
        LEFT_VIEW_SET_X(_tabEndX +  _SNStackNavigationMoveOffset * offsetDirection);
    };

    completionBlock = ^(BOOL finished)
    {
        void (^bounceBlock)(void);

        bounceBlock = ^(void)
        {
            LEFT_VIEW_SET_X(_tabEndX);
        };

        [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                         animations:bounceBlock
                         completion:NULL];
    };

    [UIView animateWithDuration:_SNStackNavigationAnimationDuration
                     animations:animationBlock
                     completion:completionBlock];
}


- (void)_cutDownViewControllersExceptRootViewController
{
    if ([_delegate respondsToSelector:@selector(stackNavigationControllerWillCuttingDown:)])
    {
        [_delegate stackNavigationControllerWillCuttingDown:self];
    }

    [_viewControllers enumerateObjectsWithOptions:NSEnumerationReverse
                                       usingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         UIViewController   *removedViewController;

         removedViewController = obj;
         if (IS_VIEW_ROOT_VIEW([removedViewController view]))
         {
             *stop = YES;
             return;
         }

         [self _unregisterViewController:removedViewController];
     }];

    [CONTENT_VIEW setRightView:nil];
    [CONTENT_VIEW setMoreRightView:nil];

    [self _updateCornerRadius];
}


- (void)_moveToStateLRWithRightDirection
{
    void (^animationBlock)(void);
    void (^completionBlock)(BOOL);

    if (CGRectGetMinX(RIGHT_VIEW_FRAME) < CGRectGetMaxX(LEFT_VIEW_FRAME))
    {
        animationBlock = ^(void)
        {
            LEFT_VIEW_SET_X(0);
            RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
        };

        completionBlock = ^(BOOL finished)
        {
            void (^bounceAnimationBlock)(void);
            void (^bounceCompletionBlock)(BOOL);

            bounceAnimationBlock = ^(void)
            {
                LEFT_VIEW_SET_X(_SNStackNavigationMoveOffset);
                // -1 is so as not to appear background for an instant
                RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME) - 1);
            };

            bounceCompletionBlock = ^(BOOL finished)
            {
                void (^bounceBackAnimation)(void);

                bounceBackAnimation = ^(void)
                {
                    LEFT_VIEW_SET_X(0);
                    RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                };

                [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                                 animations:bounceBackAnimation];
            };

            [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                             animations:bounceAnimationBlock
                             completion:bounceCompletionBlock];
        };
    }
    else
    {
        int offsetDirection;

        offsetDirection = CGRectGetMinX(LEFT_VIEW_FRAME) < 0 ? 1 : -1;

        animationBlock = ^(void)
        {
            // TODO: 移動距離に応じて変化させる
            LEFT_VIEW_SET_X(_tabEndX + _SNStackNavigationMoveOffset * offsetDirection);
            RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
        };

        completionBlock = ^(BOOL finished)
        {
            void (^bounceBlock)(void);

            bounceBlock = ^(void)
            {
                LEFT_VIEW_SET_X(_tabEndX);
                RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
            };

            [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                                  delay:0.05
                                options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                             animations:bounceBlock
                             completion:NULL];
        };

        if (CGRectGetMinX(LEFT_VIEW_FRAME) > _tabEndX + _SNStackNavigationCutDownWidth)
        {
            [self _cutDownViewControllersExceptRootViewController];
        }
    }

    [UIView animateWithDuration:_SNStackNavigationAnimationDuration
                     animations:animationBlock
                     completion:completionBlock];
}


- (void)_moveToStateMLLRWithRightDirection
{
    void (^animationBlock)(void);
    void (^completionBlock)(BOOL);

    if (CGRectGetMinX(RIGHT_VIEW_FRAME) < CGRectGetMaxX(LEFT_VIEW_FRAME))
    {
        CGFloat leftViewX;

        leftViewX = 0;

        animationBlock = ^(void)
        {
            LEFT_VIEW_SET_X(leftViewX);
            RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
        };

        completionBlock = ^(BOOL finished)
        {
            void (^bounceAnimationBlock)(void);
            void (^bounceCompletionBlock)(BOOL);

            bounceAnimationBlock = ^(void)
            {
                LEFT_VIEW_SET_X(leftViewX + _SNStackNavigationMoveOffset);
                RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
            };

            bounceCompletionBlock = ^(BOOL finished)
            {
                void (^bounceBackAnimationBlock)(void);

                bounceBackAnimationBlock = ^(void)
                {
                    LEFT_VIEW_SET_X(leftViewX);
                    RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                };

                [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                                 animations:bounceBackAnimationBlock];
            };

            [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                             animations:bounceAnimationBlock
                             completion:bounceCompletionBlock];
        };

    }
    else
    {
        CGFloat leftViewX, moreLeftViewX;

        leftViewX       = CGRectGetMaxX(MORE_LEFT_VIEW_FRAME);
        moreLeftViewX   = 0;

        animationBlock = ^(void)
        {
            LEFT_VIEW_SET_X(leftViewX);
            // 第1引数を CGRectGetMaxX(STACKED_VIEWS_FRAME) とするときれいにアニメーションしない
            RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
        };

        completionBlock = ^(BOOL finished)
        {
            void (^bounceAnimationBlock)(void);
            void (^bounceCompletionBlock)(BOOL);

            bounceAnimationBlock = ^(void)
            {
                MORE_LEFT_VIEW_SET_X(moreLeftViewX + _SNStackNavigationMoveOffset);
                LEFT_VIEW_SET_X(CGRectGetMaxX(MORE_LEFT_VIEW_FRAME));
            };

            bounceCompletionBlock = ^(BOOL finished)
            {
                void (^bounceBackAnimationBlock)(void);
                void (^bounceBackCompletionBlock)(BOOL);

                bounceBackAnimationBlock = ^(void)
                {
                    LEFT_VIEW_SET_X(leftViewX);
                    MORE_LEFT_VIEW_SET_X(moreLeftViewX);
                };

                bounceBackCompletionBlock = ^(BOOL finished)
                {
                    RIGHT_VIEW_SET_X(CGRectGetMaxX(STACKED_VIEWS_FRAME));

                    [CONTENT_VIEW setMoreRightView:RIGHT_VIEW];
                    [CONTENT_VIEW setRightView:LEFT_VIEW];
                    [CONTENT_VIEW setLeftView:MORE_LEFT_VIEW];

                    if (IS_VIEW_ROOT_VIEW(MORE_LEFT_VIEW))
                    {
                        [CONTENT_VIEW setMoreLeftView:nil];
                    }
                    else
                    {
                        [CONTENT_VIEW setMoreLeftView:[STACKED_VIEWS_CONCRETE objectAtIndex:[STACKED_VIEWS_CONCRETE indexOfObject:MORE_LEFT_VIEW] - 1]];
                    }
                };

                [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                                 animations:bounceBackAnimationBlock
                                 completion:bounceBackCompletionBlock];
            };

            [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                             animations:bounceAnimationBlock
                             completion:bounceCompletionBlock];
        };
    }

    [UIView animateWithDuration:_SNStackNavigationAnimationDuration
                     animations:animationBlock
                     completion:completionBlock];
}


- (void)_moveToStateMLLRMRWithLeftDirection
{
    void (^animationBlock)(void);
    void (^completionBlock)(BOOL);

    if (CGRectGetMinX(RIGHT_VIEW_FRAME) < (CGRectGetWidth(STACKED_VIEWS_FRAME) - CGRectGetWidth(RIGHT_VIEW_FRAME)))
    {
        CGFloat moreRightViewX;

        moreRightViewX = CGRectGetWidth(STACKED_VIEWS_FRAME) - CGRectGetWidth(MORE_RIGHT_VIEW_FRAME);

        animationBlock = ^(void)
        {
            LEFT_VIEW_SET_X(0);
            RIGHT_VIEW_SET_X(0);
            MORE_RIGHT_VIEW_SET_X(moreRightViewX);
        };

        completionBlock = ^(BOOL finished)
        {
            void (^bounceAnimationBlock)(void);
            void (^bounceAnimationCompletionBlock)(BOOL);

            [CONTENT_VIEW setMoreLeftView:LEFT_VIEW];
            [CONTENT_VIEW setLeftView:RIGHT_VIEW];
            [CONTENT_VIEW setRightView:MORE_RIGHT_VIEW];

            if ([STACKED_VIEWS_CONCRETE lastObject] == MORE_RIGHT_VIEW)
            {
                [CONTENT_VIEW setMoreRightView:nil];
            }
            else
            {
                [CONTENT_VIEW setMoreRightView:[STACKED_VIEWS_CONCRETE objectAtIndex:[STACKED_VIEWS_CONCRETE indexOfObject:MORE_RIGHT_VIEW] + 1]];
            }

            bounceAnimationBlock = ^(void)
            {
                RIGHT_VIEW_SET_X(moreRightViewX - _SNStackNavigationMoveOffset);
                MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
            };

            bounceAnimationCompletionBlock = ^(BOOL finished)
            {
                void (^bounceBackAnimationBlock)(void);

                bounceBackAnimationBlock = ^(void)
                {
                    RIGHT_VIEW_SET_X(moreRightViewX);
                    MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                };

                [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                                 animations:bounceBackAnimationBlock];
            };

            [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                             animations:bounceAnimationBlock
                             completion:bounceAnimationCompletionBlock];
        };
    }
    else
    {
        CGFloat rightViewX;

        rightViewX = CGRectGetWidth(STACKED_VIEWS_FRAME) - CGRectGetWidth(RIGHT_VIEW_FRAME);

        animationBlock = ^(void)
        {
            LEFT_VIEW_SET_X(0);
            RIGHT_VIEW_SET_X(rightViewX - _SNStackNavigationMoveOffset);
            MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
        };

        completionBlock = ^(BOOL finished)
        {
            void (^bounceBackAnimationBlock)(void);

            bounceBackAnimationBlock = ^(void)
            {
                LEFT_VIEW_SET_X(0);
                RIGHT_VIEW_SET_X(rightViewX);
                MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
            };

            [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                             animations:bounceBackAnimationBlock];
        };
    }

    [UIView animateWithDuration:_SNStackNavigationAnimationDuration
                     animations:animationBlock
                     completion:completionBlock];
}


- (void)_moveToState:(_SNStackNavigationDragDirectionType)dragDirection
{
    void (^animationBlock)(void);
    void (^completionBlock)(BOOL);

    switch ([self _decideMainState])
    {
        case _SNStackNavigationStateL:
        {
            [self _moveToStateL:dragDirection];
            break;
        }

        case _SNStackNavigationStateLR:
        {
            if (dragDirection == _SNStackNavigationDragDirectionLeft)
            {
                if (CGRectGetMinX(LEFT_VIEW_FRAME) > _tabEndX)
                {
                    animationBlock = ^(void)
                    {
                        LEFT_VIEW_SET_X(_tabEndX);
                        RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                    };
                }
                else if (CGRectGetMinX(LEFT_VIEW_FRAME) <= _tabEndX)
                {
                    CGFloat rightViewX;

                    rightViewX = CGRectGetWidth(STACKED_VIEWS_FRAME) - CGRectGetWidth(RIGHT_VIEW_FRAME);

                    animationBlock = ^(void)
                    {
                        LEFT_VIEW_SET_X(0);
                        RIGHT_VIEW_SET_X(rightViewX - _SNStackNavigationMoveOffset);
                    };

                    completionBlock = ^(BOOL finished)
                    {
                        void (^bounceBlock)(void);

                        bounceBlock = ^(void)
                        {
                            RIGHT_VIEW_SET_X(rightViewX);
                        };

                        [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                                         animations:bounceBlock];
                    };
                }
                else
                {
                    animationBlock = ^(void)
                    {
                        LEFT_VIEW_SET_X(0);
                        RIGHT_VIEW_SET_X(CGRectGetWidth(LEFT_VIEW_FRAME));
                    };
                }
            }
            else if (dragDirection == _SNStackNavigationDragDirectionRight)
            {
                [self _moveToStateLRWithRightDirection];
            }

            break;
        }

        case _SNStackNavigationStateLRMR:
        {
            if (dragDirection == _SNStackNavigationDragDirectionLeft)
            {
                if (CGRectGetMinX(LEFT_VIEW_FRAME) > _tabEndX)
                {
                    animationBlock = ^(void)
                    {
                        LEFT_VIEW_SET_X(_tabEndX);
                        RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                    };
                }
                else if (CGRectGetMinX(LEFT_VIEW_FRAME) <= _tabEndX)
                {
                    [self _moveToStateMLLRMRWithLeftDirection];
                }
                else
                {
                    animationBlock = ^(void)
                    {
                        LEFT_VIEW_SET_X(0);
                        RIGHT_VIEW_SET_X(CGRectGetWidth(LEFT_VIEW_FRAME));
                    };
                }
            }
            else if (dragDirection == _SNStackNavigationDragDirectionRight)
            {
                [self _moveToStateLRWithRightDirection];
            }

            break;
        }

        case _SNStackNavigationStateMLLR:
        {
            if (dragDirection == _SNStackNavigationDragDirectionLeft)
            {
                if (CGRectGetMinX(LEFT_VIEW_FRAME) <= _tabEndX)
                {
                    CGFloat rightViewX;
                    int     offsetDirection;

                    rightViewX      = CGRectGetWidth(STACKED_VIEWS_FRAME) - CGRectGetWidth(RIGHT_VIEW_FRAME);
                    offsetDirection = CGRectGetMinX(RIGHT_VIEW_FRAME) < rightViewX ? 1 : -1;

                    animationBlock = ^(void)
                    {
                        LEFT_VIEW_SET_X(0);
                        RIGHT_VIEW_SET_X(rightViewX);
                    };

                    completionBlock = ^(BOOL finished)
                    {
                        void (^bounceBlock)(void);
                        void (^bounceCompletionBlock)(BOOL);

                        bounceBlock = ^(void)
                        {
                            LEFT_VIEW_SET_X(_SNStackNavigationMoveOffset * offsetDirection);
                            RIGHT_VIEW_SET_X(rightViewX + _SNStackNavigationMoveOffset * offsetDirection);
                        };

                        bounceCompletionBlock = ^(BOOL finished)
                        {
                            LEFT_VIEW_SET_X(0);
                            RIGHT_VIEW_SET_X(rightViewX);
                        };

                        [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                                         animations:bounceBlock
                                         completion:bounceCompletionBlock];
                    };
                }
                else
                {
                    CGFloat rightViewX;

                    rightViewX = CGRectGetMaxX(LEFT_VIEW_FRAME);

                    animationBlock = ^(void)
                    {
                        LEFT_VIEW_SET_X(0);
                        RIGHT_VIEW_SET_X(rightViewX - _SNStackNavigationMoveOffset);
                    };

                    completionBlock = ^(BOOL finished)
                    {
                        void (^bounceBlock)(void);

                        bounceBlock = ^(void)
                        {
                            RIGHT_VIEW_SET_X(rightViewX);
                        };

                        [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                                         animations:bounceBlock];
                    };
                }
            }
            else if (dragDirection == _SNStackNavigationDragDirectionRight)
            {
                [self _moveToStateMLLRWithRightDirection];
            }

            break;
        }

        case _SNStackNavigationStateMLLRMR:
        {
            if (dragDirection == _SNStackNavigationDragDirectionLeft)
            {
                [self _moveToStateMLLRMRWithLeftDirection];
            }
            else if (dragDirection == _SNStackNavigationDragDirectionRight)
            {
                [self _moveToStateMLLRWithRightDirection];
            }

            break;
        }

        default:
        {
            NSException *exception;

            exception = [NSException exceptionWithName:@"UnknownStateException"
                                                reason:@"State is unknown"
                                              userInfo:nil];
            @throw exception;

            break;
        }
    }

    [UIView animateWithDuration:_SNStackNavigationAnimationDuration
                     animations:animationBlock
                     completion:completionBlock];
}



- (void)_onPanGesture:(UIPanGestureRecognizer *)recognizer
{
    static CGPoint  lastTouchLocation, startPointOfRightView, startPointOfLeftView, translationStart;
    _SNStackNavigationDragDirectionType dragDirection;
    CGPoint translation, location;

    translation = [recognizer translationInView:[self view]];
    location    = [recognizer locationInView:[self view]];

    [[MORE_LEFT_VIEW layer] removeAllAnimations];
    [[LEFT_VIEW layer] removeAllAnimations];
    [[RIGHT_VIEW layer] removeAllAnimations];
    [[MORE_RIGHT_VIEW layer] removeAllAnimations];

    if ([recognizer state] == UIGestureRecognizerStateBegan)
    {
        translationStart        = translation;
        startPointOfLeftView    = LEFT_VIEW.frame.origin;
        startPointOfRightView   = RIGHT_VIEW.frame.origin;
    }
    else
    {
        _SNStackNavigationStateType state;

        dragDirection = _SNStackNavigationDragDirectionNone;
        if (location.x < lastTouchLocation.x)
        {
            dragDirection = _SNStackNavigationDragDirectionLeft;
        }
        else if (location.x > lastTouchLocation.x)
        {
            dragDirection = _SNStackNavigationDragDirectionRight;
        }

        state = [self _decideMainState];

        if (state == _SNStackNavigationStateL)
        {
            LEFT_VIEW_SET_X(startPointOfLeftView.x + translation.x * _SNStackNavigationMoveFrictionCoEfficient);
        }
        else if (state == _SNStackNavigationStateLR)
        {
            if (CGRectGetMinX(RIGHT_VIEW_FRAME) <= RIGHT_VIEW_FOLDED_X)
            {
                RIGHT_VIEW_SET_X(startPointOfRightView.x + translationStart.x + (translation.x - translationStart.x) * _SNStackNavigationMoveFrictionCoEfficient);
            }
            else if (RIGHT_VIEW_FOLDED_X < CGRectGetMinX(RIGHT_VIEW_FRAME) &&
                     CGRectGetMinX(RIGHT_VIEW_FRAME) < CGRectGetMaxX(LEFT_VIEW_FRAME))
            {
                if (dragDirection == _SNStackNavigationDragDirectionLeft)
                {
                    RIGHT_VIEW_SET_X(startPointOfRightView.x + translation.x);
                }
                else
                {
                    RIGHT_VIEW_SET_X(MIN(startPointOfRightView.x + translation.x, CGRectGetMaxX(LEFT_VIEW_FRAME)));
                }

                translationStart = translation;
            }
            else if (CGRectGetMaxX(LEFT_VIEW_FRAME) <= CGRectGetMinX(RIGHT_VIEW_FRAME))
            {
                CGFloat coefficient = 1;

                if (0 < CGRectGetMinX(LEFT_VIEW_FRAME))
                {
                    coefficient = _SNStackNavigationMoveFrictionCoEfficient;
                }
                else
                {
                    translationStart = translation;
                }

                RIGHT_VIEW_SET_X(startPointOfRightView.x + translationStart.x + (translation.x - translationStart.x) * coefficient);

                if (0 <= CGRectGetMinX(RIGHT_VIEW_FRAME) - CGRectGetWidth(LEFT_VIEW_FRAME))
                {
                    LEFT_VIEW_SET_X(CGRectGetMinX(RIGHT_VIEW_FRAME) - CGRectGetWidth(LEFT_VIEW_FRAME));
                }
                else
                {
                    LEFT_VIEW_SET_X(0);
                }
            }

            if (CGRectGetMinX(LEFT_VIEW_FRAME) > _tabEndX + _SNStackNavigationCutDownWidth)
            {
                [self set_willCuttingDown:YES];
            }
            else
            {
                [self set_willCuttingDown:NO];
            }
        }
        else if (state == _SNStackNavigationStateLRMR)
        {
            if (CGRectGetMinX(RIGHT_VIEW_FRAME) <= 0)
            {
                [CONTENT_VIEW setMoreLeftView:LEFT_VIEW];
                [CONTENT_VIEW setLeftView:RIGHT_VIEW];
                [CONTENT_VIEW setRightView:MORE_RIGHT_VIEW];

                if ([STACKED_VIEWS_CONCRETE lastObject] == MORE_RIGHT_VIEW)
                {
                    [CONTENT_VIEW setMoreRightView:nil];
                }
                else
                {
                    [CONTENT_VIEW setMoreRightView:[STACKED_VIEWS_CONCRETE objectAtIndex:[STACKED_VIEWS_CONCRETE indexOfObject:MORE_RIGHT_VIEW] + 1]];
                }

                startPointOfLeftView    = LEFT_VIEW_FRAME.origin;
                startPointOfRightView   = RIGHT_VIEW_FRAME.origin;
                translationStart        = translation;
            }
            else if (CGRectGetMinX(RIGHT_VIEW_FRAME) <= RIGHT_VIEW_FOLDED_X)
            {
                RIGHT_VIEW_SET_X(MAX(startPointOfRightView.x + translation.x, 0));
                MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
            }
            else if (RIGHT_VIEW_FOLDED_X < CGRectGetMinX(RIGHT_VIEW_FRAME) &&
                     CGRectGetMinX(RIGHT_VIEW_FRAME) < CGRectGetMaxX(LEFT_VIEW_FRAME))
            {
                if (dragDirection == _SNStackNavigationDragDirectionLeft)
                {
                    RIGHT_VIEW_SET_X(startPointOfRightView.x + translation.x);
                }
                else
                {
                    RIGHT_VIEW_SET_X(MIN(startPointOfRightView.x + translation.x, CGRectGetMaxX(LEFT_VIEW_FRAME)));
                }

                translationStart = translation;
            }
            else if (CGRectGetMaxX(LEFT_VIEW_FRAME) <= CGRectGetMinX(RIGHT_VIEW_FRAME))
            {
                CGFloat coefficient = 1;

                if (0 < CGRectGetMinX(LEFT_VIEW_FRAME))
                {
                    coefficient = _SNStackNavigationMoveFrictionCoEfficient;
                }
                else
                {
                    translationStart = translation;
                }

                RIGHT_VIEW_SET_X(startPointOfRightView.x + translationStart.x + (translation.x - translationStart.x) * coefficient);

                if (0 <= CGRectGetMinX(RIGHT_VIEW_FRAME) - CGRectGetWidth(LEFT_VIEW_FRAME))
                {
                    LEFT_VIEW_SET_X(CGRectGetMinX(RIGHT_VIEW_FRAME) - CGRectGetWidth(LEFT_VIEW_FRAME));
                }
                else
                {
                    LEFT_VIEW_SET_X(0);
                }
            }

            if (CGRectGetMinX(LEFT_VIEW_FRAME) > _tabEndX + _SNStackNavigationCutDownWidth)
            {
                [self set_willCuttingDown:YES];
            }
            else
            {
                [self set_willCuttingDown:NO];
            }
        }
        else if (state == _SNStackNavigationStateMLLR)
        {
            if (CGRectGetMinX(RIGHT_VIEW_FRAME) <= RIGHT_VIEW_FOLDED_X)
            {
                RIGHT_VIEW_SET_X(startPointOfRightView.x + translationStart.x + (translation.x - translationStart.x) * _SNStackNavigationMoveFrictionCoEfficient);
            }
            else if (RIGHT_VIEW_FOLDED_X < CGRectGetMinX(RIGHT_VIEW_FRAME) &&
                     CGRectGetMinX(RIGHT_VIEW_FRAME) < CGRectGetMaxX(LEFT_VIEW_FRAME))
            {
                if (dragDirection == _SNStackNavigationDragDirectionLeft)
                {
                    if (startPointOfRightView.x + (translation.x - translationStart.x) <= RIGHT_VIEW_FOLDED_X)
                    {
                        RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X);

                        startPointOfRightView = RIGHT_VIEW_FRAME.origin;
                        translationStart = translation;
                    }
                    else
                    {
                        RIGHT_VIEW_SET_X(startPointOfRightView.x + (translation.x - translationStart.x));
                    }
                }
                else
                {
                    RIGHT_VIEW_SET_X(MIN(startPointOfRightView.x + (translation.x - translationStart.x), CGRectGetMaxX(LEFT_VIEW_FRAME)));
                }
            }
            else if (CGRectGetMaxX(LEFT_VIEW_FRAME) <= CGRectGetMinX(RIGHT_VIEW_FRAME))
            {
                RIGHT_VIEW_SET_X(startPointOfRightView.x + (translation.x - translationStart.x));

                if (0 <= CGRectGetMinX(RIGHT_VIEW_FRAME) - CGRectGetWidth(LEFT_VIEW_FRAME))
                {
                    LEFT_VIEW_SET_X(CGRectGetMinX(RIGHT_VIEW_FRAME) - CGRectGetWidth(LEFT_VIEW_FRAME));
                }
                else
                {
                    LEFT_VIEW_SET_X(0);

                    startPointOfRightView = RIGHT_VIEW_FRAME.origin;
                    translationStart = translation;
                }
            }
        }
        else if (state == _SNStackNavigationStateMLLRMR)
        {
            if (CGRectGetMinX(RIGHT_VIEW_FRAME) <= 0)
            {
                [CONTENT_VIEW setMoreLeftView:LEFT_VIEW];
                [CONTENT_VIEW setLeftView:RIGHT_VIEW];
                [CONTENT_VIEW setRightView:MORE_RIGHT_VIEW];

                if ([STACKED_VIEWS_CONCRETE lastObject] == MORE_RIGHT_VIEW)
                {
                    [CONTENT_VIEW setMoreRightView:nil];
                }
                else
                {
                    [CONTENT_VIEW setMoreRightView:[STACKED_VIEWS_CONCRETE objectAtIndex:[STACKED_VIEWS_CONCRETE indexOfObject:MORE_RIGHT_VIEW] + 1]];
                }

                startPointOfLeftView    = LEFT_VIEW_FRAME.origin;
                startPointOfRightView   = RIGHT_VIEW_FRAME.origin;
                translationStart        = translation;
            }
            else if (CGRectGetMaxX(MORE_LEFT_VIEW_FRAME) <= CGRectGetMinX(LEFT_VIEW_FRAME))
            {
                [CONTENT_VIEW setMoreRightView:RIGHT_VIEW];
                [CONTENT_VIEW setRightView:LEFT_VIEW];
                [CONTENT_VIEW setLeftView:MORE_LEFT_VIEW];

                if (IS_VIEW_ROOT_VIEW(MORE_LEFT_VIEW))
                {
                    [CONTENT_VIEW setMoreLeftView:nil];
                }
                else
                {
                    [CONTENT_VIEW setMoreLeftView:[STACKED_VIEWS_CONCRETE objectAtIndex:[STACKED_VIEWS_CONCRETE indexOfObject:MORE_LEFT_VIEW] - 1]];
                }

                startPointOfLeftView    = LEFT_VIEW_FRAME.origin;
                startPointOfRightView   = RIGHT_VIEW_FRAME.origin;
                translationStart        = translation;
            }
            else if (CGRectGetMinX(RIGHT_VIEW_FRAME) <= RIGHT_VIEW_FOLDED_X)
            {
                RIGHT_VIEW_SET_X(MAX(startPointOfRightView.x + translation.x, 0));
                MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
            }
            else if (RIGHT_VIEW_FOLDED_X < CGRectGetMinX(RIGHT_VIEW_FRAME) &&
                     CGRectGetMinX(RIGHT_VIEW_FRAME) < CGRectGetMaxX(LEFT_VIEW_FRAME))
            {
                if (dragDirection == _SNStackNavigationDragDirectionLeft)
                {
                    RIGHT_VIEW_SET_X(startPointOfRightView.x + (translation.x - translationStart.x));
                }
                else
                {
                    RIGHT_VIEW_SET_X(MIN(startPointOfRightView.x + (translation.x - translationStart.x), CGRectGetMaxX(LEFT_VIEW_FRAME)));
                }
            }
            else if (CGRectGetMaxX(LEFT_VIEW_FRAME) <= CGRectGetMinX(RIGHT_VIEW_FRAME))
            {
                RIGHT_VIEW_SET_X(startPointOfRightView.x + (translation.x - translationStart.x));

                if (CGRectGetMaxX(MORE_LEFT_VIEW_FRAME) <= CGRectGetMinX(RIGHT_VIEW_FRAME) - CGRectGetWidth(LEFT_VIEW_FRAME))
                {
                    LEFT_VIEW_SET_X(CGRectGetMaxX(MORE_LEFT_VIEW_FRAME));
                }
                else if (0 <= CGRectGetMinX(RIGHT_VIEW_FRAME) - CGRectGetWidth(LEFT_VIEW_FRAME))
                {
                    LEFT_VIEW_SET_X(CGRectGetMinX(RIGHT_VIEW_FRAME) - CGRectGetWidth(LEFT_VIEW_FRAME));
                }
                else
                {
                    LEFT_VIEW_SET_X(0);

                    startPointOfRightView = RIGHT_VIEW_FRAME.origin;
                    translationStart = translation;
                }
            }
        }
    }

    lastTouchLocation = location;

    if ([recognizer state] == UIGestureRecognizerStateEnded)
    {
        [self _moveToState:translation.x > 0 ? _SNStackNavigationDragDirectionRight : _SNStackNavigationDragDirectionLeft];
    }
}


- (void)_updateCornerRadius
{
    NSUInteger viewsCount;

    // the specification of removeFromSuperlayer is that Removes the receiver from the sublayers array or mask property of the receiver’s superlayer.
    [[CONTENT_VIEW leftMaskLayer] removeFromSuperlayer];
    [[CONTENT_VIEW rightMaskLayer] removeFromSuperlayer];

    viewsCount = [STACKED_VIEWS_CONCRETE count];
    if (viewsCount == 1)
    {
        [STACKED_VIEWS setClipsToBounds:NO];
        [[STACKED_VIEWS layer] setCornerRadius:0];
        [[STACKED_VIEWS layer] setMasksToBounds:NO];

        [[[[self rootViewController] view] layer] setCornerRadius:SNStackNavigationCornerRadius];
        [[[[self rootViewController] view] layer] setMasksToBounds:YES];
    }
    else if (viewsCount > 1)
    {
        CGRect              frame;
        UIViewController    *mostRightViewController;

        [STACKED_VIEWS setClipsToBounds:YES];
        [[STACKED_VIEWS layer] setCornerRadius:SNStackNavigationCornerRadius];
        [[STACKED_VIEWS layer] setMasksToBounds:YES];

        [[[[self rootViewController] view] layer] setCornerRadius:0];

        frame = [[[[self rootViewController] view] layer] bounds];
        frame.size.width += SNStackNavigationCornerRadius;

        [[CONTENT_VIEW leftMaskLayer] setFrame:frame];

        [[[[self rootViewController] view] layer] setMask:[CONTENT_VIEW leftMaskLayer]];

        mostRightViewController = [[self viewControllers] lastObject];

        frame = [[[mostRightViewController view] layer] bounds];
        frame.origin.x   = -SNStackNavigationCornerRadius;
        frame.size.width += SNStackNavigationCornerRadius;

        [[CONTENT_VIEW rightMaskLayer] setFrame:frame];

        [[[mostRightViewController view] layer] setMask:[CONTENT_VIEW rightMaskLayer]];
    }
}


- (void)pushViewController:(UIViewController *)viewController
        fromViewController:(UIViewController *)fromViewController
                  animated:(BOOL)animated
{
    CGFloat         viewWidth;
    __block CGRect  frame;
    NSUInteger      subviewsCount;
    void (^animationsBlock)(void);

    viewWidth = [viewController contentWidthForViewInStackNavigation];

    frame = CGRectMake(CGRectGetMaxX([[fromViewController view] frame]),
                       0,
                       viewWidth,
                       CGRectGetHeight([[self view] bounds]));

    [self set_willCuttingDown:NO];

    if (!fromViewController)
    {
        if ([_viewControllers count])
        {
            frame.origin.x = CGRectGetMinX(LEFT_VIEW_FRAME);
        }

        [_viewControllers enumerateObjectsWithOptions:NSEnumerationReverse
                                           usingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             UIViewController *removedViewController;

             removedViewController = obj;

             [self _unregisterViewController:removedViewController];
         }];
    }
    else if ([_viewControllers count])
    {
        NSUInteger  removedIndexFrom;

        removedIndexFrom = [_viewControllers indexOfObject:fromViewController];
        if (removedIndexFrom == NSNotFound)
        {
            return;
        }

        ++removedIndexFrom;

        [_viewControllers enumerateObjectsWithOptions:NSEnumerationReverse
                                           usingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             if (idx < removedIndexFrom)
             {
                 *stop = YES;
             }
             else
             {
                 UIViewController *removedViewController;

                 removedViewController = obj;

                 frame.origin.x = CGRectGetMinX([[removedViewController view] frame]);

                 [self _unregisterViewController:removedViewController];
             }
         }];
    }

    [self _registerViewController:viewController];

    [[viewController view] setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [[viewController view] setFrame:frame];

    [STACKED_VIEWS addSubview:[viewController view]];

    [self _updateCornerRadius];

    subviewsCount = [STACKED_VIEWS_CONCRETE count];

    if (subviewsCount == 1)
    {
        animationsBlock = ^(void)
        {
            switch ([viewController insertedPosition])
            {
                case SNStackNavigationInsertPositionDefault:
                {
                    LEFT_VIEW_SET_X(_tabEndX);
                    break;
                }

                case SNStackNavigationInsertPositionUnFolded:
                {
                    LEFT_VIEW_SET_X(CGRectGetWidth([STACKED_VIEWS bounds]) - CGRectGetWidth(LEFT_VIEW_FRAME));
                    break;
                }

                default:
                    break;
            }
        };

        [CONTENT_VIEW setMoreRightView:nil];
        [CONTENT_VIEW setRightView:nil];
        [CONTENT_VIEW setLeftView:[STACKED_VIEWS_CONCRETE objectAtIndex:subviewsCount - 1]];
        [CONTENT_VIEW setMoreLeftView:nil];

        if (animated)
        {
            [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration
                             animations:animationsBlock];
        }
        else
        {
            animationsBlock();
        }
    }
    else
    {
        animationsBlock = ^(void)
        {
            RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X);
            LEFT_VIEW_SET_X(0);
            MORE_LEFT_VIEW_SET_X(0);
        };

        if (subviewsCount == 2)
        {
            [CONTENT_VIEW setMoreRightView:nil];
            [CONTENT_VIEW setRightView:[STACKED_VIEWS_CONCRETE objectAtIndex:subviewsCount - 1]];
            [CONTENT_VIEW setLeftView:[STACKED_VIEWS_CONCRETE objectAtIndex:subviewsCount - 2]];
            [CONTENT_VIEW setMoreLeftView:nil];

            if (animated)
            {
                [UIView animateWithDuration:_SNStackNavigationAnimationDuration
                                 animations:animationsBlock];
            }
            else
            {
                animationsBlock();
            }
        }
        else
        {
            [CONTENT_VIEW setMoreRightView:nil];
            [CONTENT_VIEW setRightView:[STACKED_VIEWS_CONCRETE objectAtIndex:subviewsCount - 1]];
            [CONTENT_VIEW setLeftView:[STACKED_VIEWS_CONCRETE objectAtIndex:subviewsCount - 2]];
            [CONTENT_VIEW setMoreLeftView:[STACKED_VIEWS_CONCRETE objectAtIndex:subviewsCount - 3]];

            if (animated)
            {
                [UIView animateWithDuration:_SNStackNavigationAnimationDuration
                                 animations:animationsBlock];
            }
            else
            {
                animationsBlock();
            }
        }
    }
}


@end
