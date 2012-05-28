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

#import "SNShadowView.h"
#import "SNStackNavigationContentView.h"


static CGFloat const _SNStackNavigationDefaultToolbarWidth          = 292;
static CGFloat const _SNStackNavigationDefaultToolbarMinimumWidth   = 72;
static CGFloat const _SNStackNavigationCutDownWidth                 = 120;
static CGFloat const _SNStackNavigationMoveFrictionCoEfficient      = 0.5;
static CGFloat const _SNStackNavigationAnimationDuration            = 0.2;
static CGFloat const _SNStackNavigationBounceAnimationDuration      = 0.2;
static CGFloat const _SNStackNavigationMoveOffset                   = 10;
static CGFloat const _SNStackNavigationShadowWidth                  = 40;

typedef enum
{
    _SNStackNavigationDragDirectionNone,
    _SNStackNavigationDragDirectionLeft,
    _SNStackNavigationDragDirectionRight,
} _SNStackNavigationDragDirectionType;


#define CONTENT_VIEW (SNStackNavigationContentView *)[self view]
#define STACKED_VIEWS [CONTENT_VIEW stackedViews]
#define STACKED_VIEWS_FRAME [STACKED_VIEWS frame]
#define STACKED_VIEWS_CONCRETE [STACKED_VIEWS subviews]
#define IS_VIEW_ROOT_VIEW(_view) ([[STACKED_VIEWS subviews] indexOfObject:_view] == 0)

#define _VIEW(_viewName) [CONTENT_VIEW _viewName]
#define _VIEW_FRAME(_name) [_name frame]
#define _SET_VIEW_FRAME(_name, _x, _y, _width, _height) [_name setFrame:CGRectMake((_x), (_y), (_width), (_height))]
#define _SET_VIEW_X(_name, _x) _SET_VIEW_FRAME(_name, floorf(_x), 0, CGRectGetWidth([_name frame]), CGRectGetHeight([STACKED_VIEWS bounds]))

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

#define DEFAULT_ANIMATION(_animation, _completion) \
    [UIView animateWithDuration:_SNStackNavigationBounceAnimationDuration                                   \
                          delay:0                                                                           \
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone   \
                     animations:_animation                                                                  \
                     completion:_completion];


#pragma mark - SNStackNavigationController () Interface


@interface SNStackNavigationController ()

#pragma mark - Private Properties

@property (nonatomic)   CGFloat         _tabEndX;
@property (nonatomic)   NSMutableArray  *_viewControllers;
@property (nonatomic)   BOOL            _willCuttingDown;

#pragma mark - Private Methods

- (void)_initializeViewControllers;

- (void)_initializeContentView;
- (void)_initializePanGesture;

- (CGFloat)_tabFoldedWidth;

- (void)_registerViewController:(UIViewController *)viewController;
- (void)_unregisterViewController:(UIViewController *)viewController;

- (void)_onPanGesture:(UIPanGestureRecognizer *)recognizer;

- (void)_updateCornerRadius;

- (void)_cutDownViewControllersExceptRootViewController;

- (void)_moveToState:(_SNStackNavigationDragDirectionType)dragDirection
              bounce:(BOOL)bounce;

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


- (void)set_willCuttingDown:(BOOL)willCuttingDown
{
    if (_willCuttingDown != willCuttingDown)
    {
        _willCuttingDown = willCuttingDown;

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
        _willCuttingDown    = NO;

        [self _initializeViewControllers];
    }

    return self;
}


- (void)_initializeViewControllers
{
    [self set_viewControllers:[NSMutableArray array]];
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
    [contentView setShadowWidth:_SNStackNavigationShadowWidth];
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


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];

    [[CONTENT_VIEW leftMaskLayer] removeFromSuperlayer];
    [[CONTENT_VIEW rightMaskLayer] removeFromSuperlayer];

    [CATransaction commit];
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    for (UIViewController *viewController in _viewControllers)
    {
        CGRect frame;

        frame = [[viewController view] frame];
        frame.size.width = [viewController contentWidthForViewInStackNavigation];

        [[viewController view] setFrame:frame];
    }

    if (CGRectGetMaxX(RIGHT_VIEW_FRAME) < CGRectGetMaxX([STACKED_VIEWS bounds]))
    {
        [self _moveToState:_SNStackNavigationDragDirectionRight
                    bounce:NO];
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

    [self _updateCornerRadius];
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

    if ([_delegate respondsToSelector:@selector(stackNavigationControllerDidCuttingDown:)])
    {
        [_delegate stackNavigationControllerDidCuttingDown:self];
    }
}


- (void)_moveToState:(_SNStackNavigationDragDirectionType)dragDirection
              bounce:(BOOL)bounce
{
    void (^animationBlock)(void);
    void (^completionBlock)(BOOL);

    if (MORE_LEFT_VIEW)
    {
        if (RIGHT_VIEW_FOLDED_X <= CGRectGetMinX(RIGHT_VIEW_FRAME))
        {
            switch (dragDirection)
            {
                case _SNStackNavigationDragDirectionLeft:
                {
                    animationBlock = ^(void)
                    {
                        RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X - _SNStackNavigationMoveOffset);
                        MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                    };

                    completionBlock = ^(BOOL finished)
                    {
                        void (^bounceBlock)(void) = ^(void)
                        {
                            RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X);
                            MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                        };

                        DEFAULT_ANIMATION(bounceBlock, nil);
                    };

                    break;
                }

                case _SNStackNavigationDragDirectionRight:
                {
                    if (CGRectGetMinX(LEFT_VIEW_FRAME) > 0)
                    {
                        animationBlock = ^(void)
                        {
                            LEFT_VIEW_SET_X(CGRectGetMaxX(MORE_LEFT_VIEW_FRAME));
                            RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                        };

                        void (^exchangeBlock)(BOOL) = ^(BOOL finished)
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
                        };

                        if (bounce)
                        {
                            completionBlock = ^(BOOL finished)
                            {
                                void (^bounceBlock)(void) = ^(void)
                                {
                                    MORE_LEFT_VIEW_SET_X(_SNStackNavigationMoveOffset);
                                    LEFT_VIEW_SET_X(CGRectGetMaxX(MORE_LEFT_VIEW_FRAME));
                                    RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                };

                                void (^bounceCompletionBlock)(BOOL) = ^(BOOL finished)
                                {
                                    void (^bounceBackBlock)(void) = ^(void)
                                    {
                                        MORE_LEFT_VIEW_SET_X(0);
                                        LEFT_VIEW_SET_X(CGRectGetMaxX(MORE_LEFT_VIEW_FRAME));
                                        RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                    };

                                    DEFAULT_ANIMATION(bounceBackBlock, exchangeBlock);
                                };

                                DEFAULT_ANIMATION(bounceBlock, bounceCompletionBlock);
                            };
                        }
                        else
                        {
                            completionBlock = exchangeBlock;
                        }
                    }
                    else
                    {
                        animationBlock = ^(void)
                        {
                            RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                        };

                        if (bounce)
                        {
                            completionBlock = ^(BOOL finished)
                            {
                                void (^bounceBlock)(void) = ^(void)
                                {
                                    LEFT_VIEW_SET_X(_SNStackNavigationMoveOffset);
                                    RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                };

                                void (^bounceCompletionBlock)(BOOL) = ^(BOOL finished)
                                {
                                    void (^bounceBackBlock)(void) = ^(void)
                                    {
                                        LEFT_VIEW_SET_X(0);
                                        RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                    };

                                    DEFAULT_ANIMATION(bounceBackBlock, nil);
                                };

                                DEFAULT_ANIMATION(bounceBlock, bounceCompletionBlock);
                            };
                        }
                    }

                    break;
                }

                default:
                    break;
            }
        }
        else if (CGRectGetMinX(RIGHT_VIEW_FRAME) < RIGHT_VIEW_FOLDED_X)
        {
            if (MORE_RIGHT_VIEW)
            {
                switch (dragDirection)
                {
                    case _SNStackNavigationDragDirectionLeft:
                    {
                        [CONTENT_VIEW setMoreLeftView:LEFT_VIEW];
                        [CONTENT_VIEW setLeftView:RIGHT_VIEW];
                        [CONTENT_VIEW setRightView:MORE_RIGHT_VIEW];

                        if ([STACKED_VIEWS_CONCRETE indexOfObject:MORE_RIGHT_VIEW] == [STACKED_VIEWS_CONCRETE count] - 1)
                        {
                            [CONTENT_VIEW setMoreRightView:nil];
                        }
                        else
                        {
                            [CONTENT_VIEW setMoreRightView:[STACKED_VIEWS_CONCRETE objectAtIndex:[STACKED_VIEWS_CONCRETE indexOfObject:MORE_RIGHT_VIEW] + 1]];
                        }

                        animationBlock = ^(void)
                        {
                            LEFT_VIEW_SET_X(0);
                            RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X);
                            MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                        };

                        if (bounce)
                        {
                            completionBlock = ^(BOOL finished)
                            {
                                void (^bounceBlock)(void) = ^(void)
                                {
                                    LEFT_VIEW_SET_X(0);
                                    RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X - _SNStackNavigationMoveOffset);
                                    MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                };

                                void (^bounceCompletionBlock)(BOOL) = ^(BOOL finished)
                                {
                                    void (^bounceBackBlock)(void) = ^(void)
                                    {
                                        LEFT_VIEW_SET_X(0);
                                        RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X);
                                        MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                    };

                                    DEFAULT_ANIMATION(bounceBackBlock, nil);
                                };

                                DEFAULT_ANIMATION(bounceBlock, bounceCompletionBlock);
                            };
                        }

                        break;
                    }

                    case _SNStackNavigationDragDirectionRight:
                    {
                        animationBlock = ^(void)
                        {
                            RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                            MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                        };

                        if (bounce)
                        {
                            completionBlock = ^(BOOL finished)
                            {
                                void (^bounceBlock)(void) = ^(void)
                                {
                                    LEFT_VIEW_SET_X(_SNStackNavigationMoveOffset);
                                    RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                    MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                };

                                void (^bounceCompletionBlock)(BOOL) = ^(BOOL finished)
                                {
                                    void (^bounceBackBlock)(void) = ^(void)
                                    {
                                        LEFT_VIEW_SET_X(0);
                                        RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                        MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                    };

                                    DEFAULT_ANIMATION(bounceBackBlock, nil);
                                };

                                DEFAULT_ANIMATION(bounceBlock, bounceCompletionBlock);
                            };
                        }

                        break;
                    }

                    default:
                        break;
                }
            }
            else
            {
                animationBlock = ^(void)
                {
                    RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X);
                };

                if (bounce)
                {
                    completionBlock = ^(BOOL finished)
                    {
                        BOOL bounceLeftView;

                        bounceLeftView = CGRectGetMaxX(LEFT_VIEW_FRAME) <= RIGHT_VIEW_FOLDED_X;

                        void (^bounceBlock)(void) = ^(void)
                        {
                            RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X + _SNStackNavigationMoveOffset);
                            if (bounceLeftView)
                            {
                                LEFT_VIEW_SET_X(_SNStackNavigationMoveOffset);
                            }
                        };

                        void (^bounceCompletionBlock)(BOOL) = ^(BOOL finished)
                        {
                            void (^bounceBackBlock)(void) = ^(void)
                            {
                                RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X);
                                if (bounceLeftView)
                                {
                                    LEFT_VIEW_SET_X(0);
                                }
                            };

                            DEFAULT_ANIMATION(bounceBackBlock, nil);
                        };

                        DEFAULT_ANIMATION(bounceBlock, bounceCompletionBlock);
                    };
                }
            }
        }
    }
    else
    {
        if (RIGHT_VIEW)
        {
            if (CGRectGetMinX(LEFT_VIEW_FRAME) <= 0)
            {
                if (CGRectGetMinX(RIGHT_VIEW_FRAME) < RIGHT_VIEW_FOLDED_X)
                {
                    if (MORE_RIGHT_VIEW)
                    {
                        switch (dragDirection)
                        {
                            case _SNStackNavigationDragDirectionLeft:
                            {
                                [CONTENT_VIEW setMoreLeftView:LEFT_VIEW];
                                [CONTENT_VIEW setLeftView:RIGHT_VIEW];
                                [CONTENT_VIEW setRightView:MORE_RIGHT_VIEW];

                                if ([STACKED_VIEWS_CONCRETE indexOfObject:MORE_RIGHT_VIEW] == [STACKED_VIEWS_CONCRETE count] - 1)
                                {
                                    [CONTENT_VIEW setMoreRightView:nil];
                                }
                                else
                                {
                                    [CONTENT_VIEW setMoreRightView:[STACKED_VIEWS_CONCRETE objectAtIndex:[STACKED_VIEWS_CONCRETE indexOfObject:MORE_RIGHT_VIEW] + 1]];
                                }

                                animationBlock = ^(void)
                                {
                                    LEFT_VIEW_SET_X(0);
                                    RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X);
                                    MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                };

                                if (bounce)
                                {
                                    completionBlock = ^(BOOL finished)
                                    {
                                        void (^bounceBlock)(void) = ^(void)
                                        {
                                            LEFT_VIEW_SET_X(0);
                                            RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X - _SNStackNavigationMoveOffset);
                                            MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                        };

                                        void (^bounceCompletionBlock)(BOOL) = ^(BOOL finished)
                                        {
                                            void (^bounceBackBlock)(void) = ^(void)
                                            {
                                                LEFT_VIEW_SET_X(0);
                                                RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X);
                                                MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                            };

                                            DEFAULT_ANIMATION(bounceBackBlock, nil);
                                        };

                                        DEFAULT_ANIMATION(bounceBlock, bounceCompletionBlock);
                                    };
                                }

                                break;
                            }

                            case _SNStackNavigationDragDirectionRight:
                            {
                                BOOL bounceLeftView;

                                bounceLeftView = CGRectGetMaxX(LEFT_VIEW_FRAME) <= RIGHT_VIEW_FOLDED_X;

                                animationBlock = ^(void)
                                {
                                    LEFT_VIEW_SET_X(0);
                                    RIGHT_VIEW_SET_X(bounceLeftView ? RIGHT_VIEW_FOLDED_X : CGRectGetMaxX(LEFT_VIEW_FRAME));
                                    MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                };

                                if (bounce)
                                {
                                    completionBlock = ^(BOOL finished)
                                    {
                                        void (^bounceBlock)(void) = ^(void)
                                        {
                                            if (bounceLeftView)
                                            {
                                                LEFT_VIEW_SET_X(_SNStackNavigationMoveOffset);
                                                RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                                MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                            }
                                            else
                                            {
                                                RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X + _SNStackNavigationMoveOffset);
                                                MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                            }
                                        };

                                        void (^completionBlock)(BOOL) = ^(BOOL finished)
                                        {
                                            void (^bounceBackBlock)(void) = ^(void)
                                            {
                                                LEFT_VIEW_SET_X(0);
                                                RIGHT_VIEW_SET_X(bounceLeftView ? RIGHT_VIEW_FOLDED_X : CGRectGetMaxX(LEFT_VIEW_FRAME));
                                                MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                            };

                                            DEFAULT_ANIMATION(bounceBackBlock, nil);
                                        };

                                        DEFAULT_ANIMATION(bounceBlock, completionBlock);
                                    };
                                }

                                break;
                            }

                            default:
                                break;
                        }
                    }
                    else
                    {
                        switch (dragDirection)
                        {
                            case _SNStackNavigationDragDirectionLeft:
                            {
                                animationBlock = ^(void)
                                {
                                    LEFT_VIEW_SET_X(0);
                                    RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X);
                                };

                                if (bounce)
                                {
                                    completionBlock = ^(BOOL finished)
                                    {
                                        BOOL bounceLeftView;

                                        bounceLeftView = CGRectGetMaxX(LEFT_VIEW_FRAME) <= RIGHT_VIEW_FOLDED_X;

                                        void (^bounceBlock)(void) = ^(void)
                                        {
                                            if (bounceLeftView)
                                            {
                                                LEFT_VIEW_SET_X(_SNStackNavigationMoveOffset);
                                            }

                                            RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X + _SNStackNavigationMoveOffset);
                                        };

                                        void (^bounceCompletionBlock)(BOOL) = ^(BOOL finished)
                                        {
                                            void (^bounceBackBlock)(void) = ^(void)
                                            {
                                                RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X);

                                                if (bounceLeftView)
                                                {
                                                    LEFT_VIEW_SET_X(0);
                                                }
                                            };

                                            DEFAULT_ANIMATION(bounceBackBlock, nil);
                                        };

                                        DEFAULT_ANIMATION(bounceBlock, bounceCompletionBlock);
                                    };
                                }

                                break;
                            }

                            case _SNStackNavigationDragDirectionRight:
                            {
                                BOOL bounceLeftView;

                                bounceLeftView = CGRectGetMaxX(LEFT_VIEW_FRAME) <= RIGHT_VIEW_FOLDED_X;

                                animationBlock = ^(void)
                                {
                                    LEFT_VIEW_SET_X(0);
                                    RIGHT_VIEW_SET_X(bounceLeftView ? RIGHT_VIEW_FOLDED_X : CGRectGetMaxX(LEFT_VIEW_FRAME));
                                };

                                if (bounce)
                                {
                                    completionBlock = ^(BOOL finished)
                                    {
                                        void (^bounceBlock)(void) = ^(void)
                                        {
                                            if (bounceLeftView)
                                            {
                                                LEFT_VIEW_SET_X(_SNStackNavigationMoveOffset);
                                                RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                            }
                                            else
                                            {
                                                RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X + _SNStackNavigationMoveOffset);
                                            }
                                        };

                                        void (^completionBlock)(BOOL) = ^(BOOL finished)
                                        {
                                            void (^bounceBackBlock)(void) = ^(void)
                                            {
                                                LEFT_VIEW_SET_X(0);
                                                RIGHT_VIEW_SET_X(bounceLeftView ? RIGHT_VIEW_FOLDED_X : CGRectGetMaxX(LEFT_VIEW_FRAME));
                                            };

                                            DEFAULT_ANIMATION(bounceBackBlock, nil);
                                        };

                                        DEFAULT_ANIMATION(bounceBlock, completionBlock);
                                    };
                                }

                                break;
                            }

                            default:
                                break;
                        }
                    }
                }
                else if (CGRectGetMinX(RIGHT_VIEW_FRAME) < CGRectGetMaxX(LEFT_VIEW_FRAME))
                {
                    switch (dragDirection)
                    {
                        case _SNStackNavigationDragDirectionLeft:
                        {
                            if (bounce)
                            {
                                animationBlock = ^(void)
                                {
                                    LEFT_VIEW_SET_X(0);
                                    RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X - _SNStackNavigationMoveOffset);
                                    MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                };

                                completionBlock = ^(BOOL finished)
                                {
                                    void (^bounceBlock)(void) = ^(void)
                                    {
                                        LEFT_VIEW_SET_X(0);
                                        RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X);
                                        MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                    };

                                    DEFAULT_ANIMATION(bounceBlock, nil);
                                };
                            }
                            else
                            {
                                animationBlock = ^(void)
                                {
                                    LEFT_VIEW_SET_X(0);
                                    RIGHT_VIEW_SET_X(RIGHT_VIEW_FOLDED_X);
                                    MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                };
                            }

                            break;
                        }

                        case _SNStackNavigationDragDirectionRight:
                        {
                            animationBlock = ^(void)
                            {
                                LEFT_VIEW_SET_X(0);
                                RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                            };

                            if (bounce)
                            {
                                completionBlock = ^(BOOL finished)
                                {
                                    void (^bounceBlock)(void) = ^(void)
                                    {
                                        LEFT_VIEW_SET_X(_SNStackNavigationMoveOffset);
                                        RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                        MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                    };

                                    void (^bounceCompletionBlock)(BOOL) = ^(BOOL finished)
                                    {
                                        void (^bounceBackBlock)(void) = ^(void)
                                        {
                                            LEFT_VIEW_SET_X(0);
                                            RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                            MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                        };

                                        DEFAULT_ANIMATION(bounceBackBlock, nil);
                                    };

                                    DEFAULT_ANIMATION(bounceBlock, bounceCompletionBlock);
                                };
                            }

                            break;
                        }

                        default:
                            break;
                    }
                }
            }
            else if (CGRectGetMinX(LEFT_VIEW_FRAME) < _tabEndX)
            {
                switch (dragDirection)
                {
                    case _SNStackNavigationDragDirectionLeft:
                    {
                        animationBlock = ^(void)
                        {
                            LEFT_VIEW_SET_X(0);
                            RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                            MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                        };

                        if (bounce)
                        {
                            completionBlock = ^(BOOL finished)
                            {
                                void (^bounceBlock)(void) = ^(void)
                                {
                                    RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME) - _SNStackNavigationMoveOffset);
                                    MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                };

                                void (^bounceCompletionBlock)(BOOL) = ^(BOOL finished)
                                {
                                    void (^bounceBackBlock)(void) = ^(void)
                                    {
                                        RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                        MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                    };

                                    DEFAULT_ANIMATION(bounceBackBlock, nil);
                                };

                                DEFAULT_ANIMATION(bounceBlock, bounceCompletionBlock);
                            };
                        }

                        break;
                    }

                    case _SNStackNavigationDragDirectionRight:
                    {
                        if (bounce)
                        {
                            animationBlock = ^(void)
                            {
                                LEFT_VIEW_SET_X(_tabEndX + _SNStackNavigationMoveOffset);
                                RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                            };

                            completionBlock = ^(BOOL finished)
                            {
                                void (^bounceBlock)(void) = ^(void)
                                {
                                    LEFT_VIEW_SET_X(_tabEndX);
                                    RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                };

                                DEFAULT_ANIMATION(bounceBlock, nil);
                            };
                        }
                        else
                        {
                            animationBlock = ^(void)
                            {
                                LEFT_VIEW_SET_X(_tabEndX);
                                RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                            };
                        }

                        break;
                    }

                    default:
                        break;
                }
            }
            else
            {
                if (bounce)
                {
                    animationBlock = ^(void)
                    {
                        LEFT_VIEW_SET_X(_tabEndX - _SNStackNavigationMoveOffset);
                        RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                    };

                    completionBlock = ^(BOOL finished)
                    {
                        void (^bounceBlock)(void) = ^(void)
                        {
                            LEFT_VIEW_SET_X(_tabEndX);
                            RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                        };

                        DEFAULT_ANIMATION(bounceBlock, nil);
                    };
                }
                else
                {
                    animationBlock = ^(void)
                    {
                        LEFT_VIEW_SET_X(_tabEndX);
                        RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                    };
                }

                if (CGRectGetMinX(LEFT_VIEW_FRAME) > _tabEndX + _SNStackNavigationCutDownWidth)
                {
                    [self _cutDownViewControllersExceptRootViewController];
                }
            }
        }
        else
        {
            UIViewController    *rootViewController;
            CGFloat             endPosition;

            rootViewController = [self rootViewController];
            if ([rootViewController insertedPosition] == SNStackNavigationInsertPositionUnFolded &&
                [rootViewController contentWidthForViewInStackNavigation] > (CGRectGetWidth(STACKED_VIEWS_FRAME) - _tabWidth))
            {
                endPosition = CGRectGetWidth([STACKED_VIEWS bounds]) - CGRectGetWidth(LEFT_VIEW_FRAME);
            }
            else
            {
                endPosition = _tabEndX;
            }

            if (bounce)
            {
                int offsetDirection;

                offsetDirection = CGRectGetMinX(LEFT_VIEW_FRAME) < endPosition ? 1 : -1;

                animationBlock = ^(void)
                {
                    LEFT_VIEW_SET_X(endPosition + offsetDirection * _SNStackNavigationMoveOffset);
                };

                completionBlock = ^(BOOL finished)
                {
                    void (^bounceBackBlock)(void) = ^(void)
                    {
                        LEFT_VIEW_SET_X(endPosition);
                    };

                    DEFAULT_ANIMATION(bounceBackBlock, nil);
                };
            }
            else
            {
                animationBlock = ^(void)
                {
                    LEFT_VIEW_SET_X(endPosition);
                };

                DEFAULT_ANIMATION(animationBlock, nil);
            }
        }
    }

    DEFAULT_ANIMATION(animationBlock, completionBlock);
}



- (void)_onPanGesture:(UIPanGestureRecognizer *)recognizer
{
    static _SNStackNavigationDragDirectionType dragDirection;
    static CGFloat lastTouchLocation, lastTranslation, startPointOfRightView, startPointOfLeftView;
    CGFloat translation, location;

    translation = [recognizer translationInView:[self view]].x;
    location    = [recognizer locationInView:[self view]].x;

    [[MORE_LEFT_VIEW layer] removeAllAnimations];
    [[LEFT_VIEW layer] removeAllAnimations];
    [[RIGHT_VIEW layer] removeAllAnimations];
    [[MORE_RIGHT_VIEW layer] removeAllAnimations];

    if ([recognizer state] == UIGestureRecognizerStateBegan)
    {
        lastTranslation         = translation;
        startPointOfLeftView    = LEFT_VIEW.frame.origin.x;
        startPointOfRightView   = RIGHT_VIEW.frame.origin.x;
        dragDirection           = _SNStackNavigationDragDirectionNone;
    }
    else
    {
        if (location < lastTouchLocation)
        {
            dragDirection = _SNStackNavigationDragDirectionLeft;
        }
        else if (location > lastTouchLocation)
        {
            dragDirection = _SNStackNavigationDragDirectionRight;
        }

        if (!RIGHT_VIEW)
        {
            LEFT_VIEW_SET_X(startPointOfLeftView + translation * _SNStackNavigationMoveFrictionCoEfficient);
        }
        else
        {
            if (dragDirection == _SNStackNavigationDragDirectionLeft)
            {
                if (CGRectGetMinX(LEFT_VIEW_FRAME) > _tabEndX)
                {
                    if (MORE_LEFT_VIEW)
                    {
                        LEFT_VIEW_SET_X(startPointOfLeftView + translation - lastTranslation);
                        RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                        MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                    }
                    else
                    {
                        CGFloat leftViewX;

                        leftViewX = floorf(startPointOfLeftView + (translation - lastTranslation) * _SNStackNavigationMoveFrictionCoEfficient);
                        if (leftViewX <= _tabEndX)
                        {
                            startPointOfLeftView    = _tabEndX;
                            lastTranslation         = translation + (_tabEndX - leftViewX);
                        }

                        LEFT_VIEW_SET_X(leftViewX);
                        RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                    }
                }
                else if (CGRectGetMinX(LEFT_VIEW_FRAME) > 0)
                {
                    CGFloat leftViewX;

                    leftViewX = floorf(startPointOfLeftView + translation - lastTranslation);
                    if (leftViewX < 0)
                    {
                        LEFT_VIEW_SET_X(0);

                        startPointOfLeftView    = 0;
                        startPointOfRightView   = CGRectGetMaxX(LEFT_VIEW_FRAME);
                        lastTranslation         = translation - leftViewX;

                        if (MORE_RIGHT_VIEW)
                        {
                            RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                        }
                        else
                        {
                            CGFloat rightViewX;

                            rightViewX = floorf(startPointOfRightView + (translation - lastTranslation) * _SNStackNavigationMoveFrictionCoEfficient);

                            RIGHT_VIEW_SET_X(MIN(rightViewX, CGRectGetMaxX(LEFT_VIEW_FRAME)));
                        }
                    }
                    else
                    {
                        LEFT_VIEW_SET_X(leftViewX);
                        RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                        MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                    }
                }
                else
                {
                    if (MORE_RIGHT_VIEW)
                    {
                        CGFloat rightViewX;

                        rightViewX = floorf(startPointOfRightView + translation - lastTranslation);
                        if (rightViewX > 0)
                        {
                            RIGHT_VIEW_SET_X(rightViewX);
                            MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                        }
                        else
                        {
                            RIGHT_VIEW_SET_X(0);
                            MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME) + rightViewX);

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

                            startPointOfLeftView    = LEFT_VIEW_FRAME.origin.x;
                            startPointOfRightView   = RIGHT_VIEW_FRAME.origin.x;
                            lastTranslation         = translation - rightViewX;
                        }
                    }
                    else
                    {
                        if (CGRectGetMinX(RIGHT_VIEW_FRAME) > RIGHT_VIEW_FOLDED_X)
                        {
                            CGFloat rightViewX, difference;

                            rightViewX = floorf(startPointOfRightView + translation - lastTranslation);
                            difference = rightViewX - RIGHT_VIEW_FOLDED_X;

                            if (difference < 0)
                            {
                                startPointOfRightView   = RIGHT_VIEW_FOLDED_X;
                                lastTranslation         = translation - difference;
                            }

                            RIGHT_VIEW_SET_X(rightViewX);
                        }
                        else
                        {
                            CGFloat rightViewX;

                            rightViewX = floorf(startPointOfRightView + (translation - lastTranslation) * _SNStackNavigationMoveFrictionCoEfficient);
                            if (rightViewX > 0)
                            {
                                RIGHT_VIEW_SET_X(rightViewX);
                            }
                            else
                            {
                                RIGHT_VIEW_SET_X(0);
                            }
                        }
                    }
                }
            }
            else if (dragDirection == _SNStackNavigationDragDirectionRight)
            {
                if (CGRectGetMinX(LEFT_VIEW_FRAME) > _tabEndX)
                {
                    if (MORE_LEFT_VIEW)
                    {
                        CGFloat leftViewX, difference;

                        leftViewX   = startPointOfLeftView + translation - lastTranslation;
                        difference  = leftViewX - CGRectGetMaxX(MORE_LEFT_VIEW_FRAME);

                        if (difference > 0)
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

                            startPointOfLeftView    = LEFT_VIEW_FRAME.origin.x;
                            startPointOfRightView   = RIGHT_VIEW_FRAME.origin.x;
                            lastTranslation         = translation - difference;

                            MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                        }
                        else
                        {
                            LEFT_VIEW_SET_X(leftViewX);
                            RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                            MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                        }
                    }
                    else
                    {
                        LEFT_VIEW_SET_X(startPointOfLeftView + (translation - lastTranslation) * _SNStackNavigationMoveFrictionCoEfficient);
                        RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                        MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                    }
                }
                else
                {
                    if (CGRectGetMinX(RIGHT_VIEW_FRAME) < RIGHT_VIEW_FOLDED_X)
                    {
                        if (MORE_RIGHT_VIEW)
                        {
                            CGFloat rightViewX, difference;

                            rightViewX = floorf(startPointOfRightView + translation - lastTranslation);
                            difference = rightViewX - CGRectGetMaxX(LEFT_VIEW_FRAME);

                            if (difference < 0)
                            {
                                RIGHT_VIEW_SET_X(rightViewX);
                                MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                            }
                            else
                            {
                                startPointOfLeftView    = 0;
                                lastTranslation         = translation - difference;

                                LEFT_VIEW_SET_X(startPointOfLeftView + difference);
                                RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                            }
                        }
                        else
                        {
                            CGFloat rightViewX, difference;

                            rightViewX = startPointOfRightView + (translation - lastTranslation) * _SNStackNavigationMoveFrictionCoEfficient;

                            if (rightViewX > 0)
                            {
                                difference = rightViewX - RIGHT_VIEW_FOLDED_X;

                                if (difference > 0)
                                {
                                    lastTranslation = translation - difference;

                                    if (rightViewX < CGRectGetMaxX(LEFT_VIEW_FRAME))
                                    {
                                        startPointOfRightView = RIGHT_VIEW_FOLDED_X;

                                        RIGHT_VIEW_SET_X(startPointOfRightView + difference);
                                        MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                    }
                                    else
                                    {
                                        startPointOfLeftView = 0;

                                        LEFT_VIEW_SET_X(startPointOfLeftView + difference);
                                        RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                        MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                                    }
                                }
                                else
                                {
                                    RIGHT_VIEW_SET_X(rightViewX);
                                }
                            }
                        }
                    }
                    else if (CGRectGetMinX(RIGHT_VIEW_FRAME) < CGRectGetMaxX(LEFT_VIEW_FRAME))
                    {
                        CGFloat rightViewX, difference;

                        rightViewX  = floorf(startPointOfRightView + translation - lastTranslation);
                        difference  = rightViewX - CGRectGetMaxX(LEFT_VIEW_FRAME);

                        if (difference > 0)
                        {
                            startPointOfLeftView    = 0;
                            lastTranslation         = translation - difference;

                            LEFT_VIEW_SET_X(startPointOfLeftView + difference);
                            RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                            MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                        }
                        else
                        {
                            RIGHT_VIEW_SET_X(rightViewX);
                            MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                        }
                    }
                    else
                    {
                        if (MORE_LEFT_VIEW)
                        {
                            LEFT_VIEW_SET_X(startPointOfLeftView + translation - lastTranslation);
                            RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                            MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                        }
                        else
                        {
                            CGFloat leftViewX, difference;

                            leftViewX   = floorf(startPointOfLeftView + translation - lastTranslation);
                            difference  = leftViewX - _tabEndX;

                            if (difference > 0)
                            {
                                startPointOfLeftView    = _tabEndX;
                                lastTranslation         = translation - difference;

                                LEFT_VIEW_SET_X(startPointOfLeftView + (translation - lastTranslation) * _SNStackNavigationMoveFrictionCoEfficient);
                                RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                            }
                            else
                            {
                                LEFT_VIEW_SET_X(leftViewX);
                                RIGHT_VIEW_SET_X(CGRectGetMaxX(LEFT_VIEW_FRAME));
                                MORE_RIGHT_VIEW_SET_X(CGRectGetMaxX(RIGHT_VIEW_FRAME));
                            }
                        }
                    }
                }
            }

            if (!MORE_LEFT_VIEW &&
                CGRectGetMinX(LEFT_VIEW_FRAME) > _tabEndX + _SNStackNavigationCutDownWidth)
            {
                [self set_willCuttingDown:YES];
            }
            else
            {
                [self set_willCuttingDown:NO];
            }
        }
    }

    lastTouchLocation = location;

    if ([recognizer state] == UIGestureRecognizerStateEnded)
    {
        [self _moveToState:translation > 0 ? _SNStackNavigationDragDirectionRight : _SNStackNavigationDragDirectionLeft
                    bounce:YES];
    }
}


- (void)_updateCornerRadius
{
    NSUInteger viewsCount;

    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];

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
        frame.origin.x   = -(SNStackNavigationCornerRadius + _SNStackNavigationShadowWidth);
        frame.size.width += SNStackNavigationCornerRadius + _SNStackNavigationShadowWidth;

        [[CONTENT_VIEW rightMaskLayer] setFrame:frame];

        [[[mostRightViewController view] layer] setMask:[CONTENT_VIEW rightMaskLayer]];
    }

    [CATransaction commit];
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
            DEFAULT_ANIMATION(animationsBlock, nil);
        }
        else
        {
            animationsBlock();
        }
    }
    else
    {
        SNShadowView *shadowView;

        shadowView = [[SNShadowView alloc] initWithFrame:CGRectMake(-_SNStackNavigationShadowWidth, 0, _SNStackNavigationShadowWidth, CGRectGetHeight([[self view] bounds]))];

        [shadowView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [[viewController view] addSubview:shadowView];

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
                DEFAULT_ANIMATION(animationsBlock, nil);
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
                DEFAULT_ANIMATION(animationsBlock, nil);
            }
            else
            {
                animationsBlock();
            }
        }
    }
}


- (void)popToViewController:(UIViewController *)viewController
                   animated:(BOOL)animated
{
    if (animated)
    {

    }

    NSUInteger index;

    index = [[self viewControllers] indexOfObject:viewController];
    if (index == NSNotFound)
    {
        return;
    }

    [[self viewControllers] enumerateObjectsWithOptions:NSEnumerationReverse
                                             usingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         if (idx > index)
         {
             [self _unregisterViewController:obj];
         }
         else
         {
             *stop = YES;
         }
     }];

    if ([[self _viewControllers] count] == 1)
    {
        [CONTENT_VIEW setRightView:nil];
        [CONTENT_VIEW setLeftView:[viewController view]];
        [CONTENT_VIEW setMoreRightView:nil];
        [CONTENT_VIEW setMoreLeftView:nil];
    }
    else
    {
        [CONTENT_VIEW setRightView:[viewController view]];
        [CONTENT_VIEW setLeftView:[STACKED_VIEWS_CONCRETE objectAtIndex:[STACKED_VIEWS_CONCRETE indexOfObject:RIGHT_VIEW] - 1]];
        [CONTENT_VIEW setMoreRightView:nil];
        if (!IS_VIEW_ROOT_VIEW(LEFT_VIEW))
        {
            [CONTENT_VIEW setMoreLeftView:[STACKED_VIEWS_CONCRETE objectAtIndex:[STACKED_VIEWS_CONCRETE indexOfObject:LEFT_VIEW] - 1]];
        }
    }

    [self _moveToState:_SNStackNavigationDragDirectionRight
                bounce:NO];
    [self _updateCornerRadius];
}


@end
