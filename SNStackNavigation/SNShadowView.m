//
//  SNShadowView.m
//  SNStackNavigationSample
//
//  Created by Shu MASUDA on 2012/05/10.
//  Copyright (c) 2012 Shu MASUDA. All rights reserved.
//

#import "SNShadowView.h"

#import <QuartzCore/QuartzCore.h>


#pragma mark - SNShadowView () Interface


@interface SNShadowView ()

#pragma mark - Private Methods

- (void)_drawGradient:(CGContextRef)context;
- (void)_drawLine:(CGContextRef)context;

@end


#pragma mark - SNShadowView Implementation


@implementation SNShadowView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        [self setBackgroundColor:[UIColor clearColor]];
        [self setOpaque:NO];
    }

    return self;
}


- (void)_drawGradient:(CGContextRef)context
{
    const CGFloat locations[2]  = { 0.0, 1.0 };
    const CGFloat components[8] =
    {
        .66, .66, .66, 0,
        0, 0, 0, .3
    };

    CGColorSpaceRef colorSpace;
    CGGradientRef   gradient;

    colorSpace = CGColorSpaceCreateDeviceRGB();
    gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 2);

    CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(CGRectGetWidth([self bounds]), 0), 0);

    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
}


- (void)_drawLine:(CGContextRef)context
{
    CGFloat lineWidth, offset, lineX;

    [[UIColor lightGrayColor] set];

    if ([[UIScreen mainScreen] scale] == 2.0)
    {
        lineWidth = 1;
        lineWidth = 2;
    }
    else
    {
        offset = 0.5;
        offset = 1;
    }

    lineX = CGRectGetWidth([self bounds]) - offset;

    CGContextSetLineWidth(context, lineWidth);

    CGContextMoveToPoint(context, lineX, 0);
    CGContextAddLineToPoint(context, lineX, CGRectGetHeight([self bounds]));
    CGContextStrokePath(context);
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context;

    context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);

    [self _drawGradient:context];
    [self _drawLine:context];

    CGContextRestoreGState(context);
}


@end
