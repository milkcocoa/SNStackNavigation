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


@synthesize leftMaskLayer;
@synthesize leftView;
@synthesize minimumTabWidth;
@synthesize moreLeftView;
@synthesize moreRightView;
@synthesize rightMaskLayer;
@synthesize rightView;
@synthesize stackedViews;
@synthesize tabWidth;


- (void)setMinimumTabWidth:(CGFloat)aMinimumTabWidth
{
    if (minimumTabWidth != aMinimumTabWidth)
    {
        minimumTabWidth = aMinimumTabWidth;

        [self setNeedsLayout];
    }
}


- (void)setTabWidth:(CGFloat)aTabWidth
{
    if (tabWidth != aTabWidth)
    {
        tabWidth = aTabWidth;

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
    stackedViews = [[UIView alloc] initWithFrame:[self bounds]];
    [self addSubview:stackedViews];

    [stackedViews setAutoresizesSubviews:YES];
}


- (void)_initializeMaskLayers
{
    leftMaskLayer = [CALayer layer];

    [leftMaskLayer setCornerRadius:SNStackNavigationCornerRadius];
    [leftMaskLayer setBackgroundColor:[[UIColor whiteColor] CGColor]];

    rightMaskLayer = [CALayer layer];
    [rightMaskLayer setCornerRadius:SNStackNavigationCornerRadius];
    [rightMaskLayer setBackgroundColor:[[UIColor whiteColor] CGColor]];
}


- (void)layoutSubviews
{
    CGFloat height;

    height = CGRectGetHeight([self bounds]);

    [stackedViews setFrame:CGRectMake(minimumTabWidth, 0, CGRectGetWidth([self bounds]) - minimumTabWidth, height)];

    [leftMaskLayer setFrame:CGRectMake(0, 0, CGRectGetWidth([leftMaskLayer frame]), height)];
    [rightMaskLayer setFrame:CGRectMake(-SNStackNavigationCornerRadius, 0, CGRectGetWidth([rightMaskLayer frame]), height)];
}


- (UIView *)hitTest:(CGPoint)point
          withEvent:(UIEvent *)event
{
    __block UIView  *result;
    __block CGPoint resultPoint;

    [[stackedViews subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
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
