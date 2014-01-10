//
//  COToken.m
//  COPeoplePickerViewController
//
//  Created by Maciej Trybiło on 17/06/2013.
//  Copyright (c) 2013 chocomoko.com. All rights reserved.
//

#import "COToken.h"
#import "COTokenField.h"

#import "UIFont+Blinkbox.h"

const CGFloat kTokenFieldFontSize = 14.0;
static const CGFloat kTokenFieldMaxTokenWidth = 260.0;
const CGFloat kTokenFieldTokenHeight = (kTokenFieldFontSize + 4.0);
const CGFloat kTokenFieldPaddingX = 6.0;
const CGFloat kTokenFieldPaddingY = 6.0;

@implementation COToken

@synthesize title = _title;
@synthesize associatedObject = _associatedObject;
@synthesize container = _container;

+ (COToken *)tokenWithTitle:(NSString *)title
           associatedObject:(id)obj
                  container:(COTokenField *)container
{
    COToken *token = [self buttonWithType:UIButtonTypeCustom];
    token.associatedObject = obj;
    token.container = container;
    token.backgroundColor = [UIColor clearColor];
    
    UIFont *font = [UIFont blinkboxBookFontOfSize:14];
    CGSize tokenSize = [title sizeWithFont:font];
    tokenSize.width = MIN((CGFloat)kTokenFieldMaxTokenWidth, tokenSize.width);
    tokenSize.width += kTokenFieldPaddingX * 2.0;
    
    tokenSize.height = MIN((CGFloat)kTokenFieldFontSize, tokenSize.height);
    tokenSize.height += kTokenFieldPaddingY * 2.0;
    
    token.frame = (CGRect){CGPointZero, tokenSize};
    token.titleLabel.font = font;
    token.title = title;
    token.accessibilityLabel = token.title;
    
    return token;
}

- (void)drawRect:(CGRect)rect
{
#pragma unused (rect)
    CGFloat radius = CGRectGetHeight(self.bounds) / 2.0f;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                    cornerRadius:radius];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextAddPath(ctx, path.CGPath);
    CGContextClip(ctx);
    
    NSArray *colors = nil;
    if (self.highlighted) {
        colors =
        @[(__bridge id)[UIColor colorWithRed:0.322 green:0.541 blue:0.976 alpha:1.0].CGColor,
          (__bridge id)[UIColor colorWithRed:0.235 green:0.329 blue:0.973 alpha:1.0].CGColor];
    }
    else {
        colors =
        @[(__bridge id)[UIColor colorWithRed:0.863 green:0.902 blue:0.969 alpha:1.0].CGColor,
          (__bridge id)[UIColor colorWithRed:0.741 green:0.808 blue:0.937 alpha:1.0].CGColor];
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient =
    CGGradientCreateWithColors(colorSpace, (__bridge CFTypeRef)colors, NULL);
    
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawLinearGradient(ctx, gradient,
                                CGPointZero,
                                CGPointMake(0, CGRectGetHeight(self.bounds)), 0);
    CGGradientRelease(gradient);
    CGContextRestoreGState(ctx);
    
    if (self.highlighted) {
        [[UIColor colorWithRed:0.275f green:0.478f blue:0.871f alpha:1.0f] set];
    }
    else {
        [[UIColor colorWithRed:0.667f green:0.757f blue:0.914f alpha:1.0f] set];
    }
    
    path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.5, 0.5)
                                      cornerRadius:radius];
    [path setLineWidth:1.0];
    [path stroke];
    
    if (self.highlighted) {
        [[UIColor whiteColor] set];
    }
    else {
        [[UIColor blackColor] set];
    }
    
    UIFont *titleFont = [UIFont blinkboxBookFontOfSize:14];
    CGSize titleSize = [self.title sizeWithFont:titleFont];
    CGRect titleFrame = CGRectMake((CGRectGetWidth(self.bounds) - titleSize.width) / 2.0f,
                                   (CGRectGetHeight(self.bounds) - titleSize.height) / 2.0f,
                                   titleSize.width,
                                   titleSize.height);
    
    [self.title drawInRect:titleFrame
                  withFont:titleFont
             lineBreakMode:NSLineBreakByTruncatingTail
                 alignment:NSTextAlignmentCenter];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ title: '%@'; associatedObj: '%@'>",
            NSStringFromClass([self class]), self.title, self.associatedObject];
}

@end

