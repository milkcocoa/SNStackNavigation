//
//  SNStackNavigationContentView.m
//  StackNavigationSample
//
//  Created by Shu MASUDA on 2011/12/28.
//

#import "SNStackNavigationContentView.h"

#import <QuartzCore/QuartzCore.h>


#pragma mark - SNStackNavigationContentView () Interface


@interface SNStackNavigationContentView ()

#pragma mark - Private Properties

@property (nonatomic, readwrite)    UIView  *stackedViews;

#pragma mark - Private methods

- (void)_initializeStackedViews;

@end


#pragma mark - SNStackNavigationContentView


@implementation SNStackNavigationContentView


#pragma mark - Properties


@synthesize leftView;
@synthesize minimumTabWidth;
@synthesize moreLeftView;
@synthesize moreRightView;
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
    }

    return self;
}


- (void)_initializeStackedViews
{
    [self setStackedViews:[[UIView alloc] initWithFrame:[self bounds]]];
    [self addSubview:stackedViews];

    [stackedViews setAutoresizesSubviews:YES];
}


- (void)layoutSubviews
{
    [stackedViews setFrame:CGRectMake(tabWidth, 0, CGRectGetWidth([self bounds]) - tabWidth, CGRectGetHeight([self bounds]))];
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
