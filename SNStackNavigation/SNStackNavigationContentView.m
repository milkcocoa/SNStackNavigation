//
//  SNStackNavigationContentView.m
//  StackNavigationSample
//
//  Created by Shu MASUDA on 2011/12/28.
//

#import "SNStackNavigationContentView.h"

#import <QuartzCore/QuartzCore.h>

#import "SNStackNavigationControllerConstants.h"


#pragma mark - SNStackNavigationContentView () Interface


@interface SNStackNavigationContentView ()

#pragma mark - Private Properties

@property (nonatomic, readwrite)    CALayer *leftMaskLayer;
@property (nonatomic, readwrite)    CALayer *rightMaskLayer;
@property (nonatomic, readwrite)    UIView  *stackedViews;

#pragma mark - Private methods

- (void)_initializeStackedViews;
- (void)_initializeMaskLayers;

@end


#pragma mark - SNStackNavigationContentView


@implementation SNStackNavigationContentView


#pragma mark - Properties


@synthesize leftMaskLayer = _leftMaskLayer;
@synthesize leftView = _leftView;
@synthesize minimumTabWidth = _minimumTabWidth;
@synthesize moreLeftView = _moreLeftView;
@synthesize moreRightView = _moreRightView;
@synthesize rightMaskLayer = _rightMaskLayer;
@synthesize rightView = _rightView;
@synthesize shadowWidth = _shadowWidth;
@synthesize stackedViews = _stackedViews;
@synthesize tabWidth = _tabWidth;


- (void)setMinimumTabWidth:(CGFloat)minimumTabWidth
{
    if (_minimumTabWidth != minimumTabWidth)
    {
        _minimumTabWidth = minimumTabWidth;

        [self setNeedsLayout];
    }
}


- (void)setShadowWidth:(CGFloat)shadowWidth
{
    if (_shadowWidth != shadowWidth)
    {
        _shadowWidth = shadowWidth;

        [self setNeedsLayout];
    }
}


- (void)setTabWidth:(CGFloat)tabWidth
{
    if (_tabWidth != tabWidth)
    {
        _tabWidth = tabWidth;

        [self setNeedsLayout];
    }
}


#pragma mark -


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self _initializeStackedViews];
        [self _initializeMaskLayers];
    }

    return self;
}


- (void)_initializeStackedViews
{
    _stackedViews = [[UIView alloc] initWithFrame:[self bounds]];
    [self addSubview:_stackedViews];

    [_stackedViews setAutoresizesSubviews:YES];
}


- (void)_initializeMaskLayers
{
    _leftMaskLayer = [CALayer layer];

    [_leftMaskLayer setAnchorPoint:CGPointZero];
    [_leftMaskLayer setBackgroundColor:[[UIColor whiteColor] CGColor]];
    [_leftMaskLayer setCornerRadius:SNStackNavigationCornerRadius];

    _rightMaskLayer = [CALayer layer];
    [_rightMaskLayer setAnchorPoint:CGPointZero];
    [_rightMaskLayer setBackgroundColor:[[UIColor whiteColor] CGColor]];
    [_rightMaskLayer setCornerRadius:SNStackNavigationCornerRadius];
}


- (void)layoutSubviews
{
    CGFloat height;

    height = CGRectGetHeight([self bounds]);
    if (height < CGRectGetHeight([_stackedViews frame]))
    {
        // workaround: not to show background, when the rotation (portrait to landscape) occurs
        [CATransaction begin];
        [CATransaction setAnimationDuration:.8];
        [_leftMaskLayer setPosition:CGPointMake(0, 0)];
        [_leftMaskLayer setBounds:CGRectMake(0, 0, CGRectGetWidth([_leftMaskLayer frame]), height)];
        [_rightMaskLayer setPosition:CGPointMake(-(_shadowWidth + SNStackNavigationCornerRadius), 0)];
        [_rightMaskLayer setBounds:CGRectMake(0, 0, CGRectGetWidth([_rightMaskLayer frame]), height)];
        [CATransaction commit];
    }
    else
    {
        [_leftMaskLayer setPosition:CGPointMake(0, 0)];
        [_leftMaskLayer setBounds:CGRectMake(0, 0, CGRectGetWidth([_leftMaskLayer frame]), height)];
        [_rightMaskLayer setPosition:CGPointMake(-(_shadowWidth + SNStackNavigationCornerRadius), 0)];
        [_rightMaskLayer setBounds:CGRectMake(0, 0, CGRectGetWidth([_rightMaskLayer frame]), height)];
    }

    [_stackedViews setFrame:CGRectMake(_minimumTabWidth, 0, CGRectGetWidth([self bounds]) - _minimumTabWidth, height)];
}


- (UIView *)hitTest:(CGPoint)point
          withEvent:(UIEvent *)event
{
    __block UIView  *result;
    __block CGPoint resultPoint;

    [[_stackedViews subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         UIView     *stackedView;
         CGPoint    convertedPoint;

         stackedView    = obj;
         convertedPoint = [stackedView convertPoint:point fromView:self];

         if ([stackedView pointInside:convertedPoint withEvent:event])
         {
             result         = stackedView;
             resultPoint    = convertedPoint;
         }
     }];

    if (result)
    {
        return [result hitTest:resultPoint withEvent:event];
    }
    else
    {
        return nil;
    }
}


@end
