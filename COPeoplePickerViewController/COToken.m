//
//  COToken.m
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Improvements by Jordi Aragones on 18.09.12
//  Copyright (c) 2011-2012. All rights reserved.
//

#import "COToken.h"
#import "Constants.h"

@implementation COToken
COSynth(title)
COSynth(associatedObject)
COSynth(container)

+ (COToken *)tokenWithTitle:(NSString *)title associatedObject:(id)obj container:(COTokenField *)container {
COToken *token = [self buttonWithType:UIButtonTypeCustom];
token.associatedObject = obj;
token.container = container;
token.backgroundColor = [UIColor clearColor];

UIFont *font = [UIFont systemFontOfSize:kTokenFieldFontSize];
CGSize tokenSize = [title sizeWithFont:font];
tokenSize.width = MIN(kTokenFieldMaxTokenWidth, tokenSize.width);
tokenSize.width += kTokenFieldPaddingX * 2.0;

tokenSize.height = MIN(kTokenFieldFontSize, tokenSize.height);
tokenSize.height += kTokenFieldPaddingY * 2.0;

token.frame = (CGRect){CGPointZero, tokenSize};
token.titleLabel.font = font;
token.title = title;

return token;

}

- (void)drawRect:(CGRect)rect {
    CGFloat radius = CGRectGetHeight(self.bounds) / 2.0;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:radius];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextAddPath(ctx, path.CGPath);
    CGContextClip(ctx);
    
    NSArray *colors = nil;
    if (self.highlighted) {
        colors = [NSArray arrayWithObjects:
                  (__bridge id)[UIColor colorWithRed:0.322 green:0.541 blue:0.976 alpha:1.0].CGColor,
                  (__bridge id)[UIColor colorWithRed:0.235 green:0.329 blue:0.973 alpha:1.0].CGColor,
                  nil];
    }
    else {
        colors = [NSArray arrayWithObjects:
                  (__bridge id)[UIColor colorWithRed:0.863 green:0.902 blue:0.969 alpha:1.0].CGColor,
                  (__bridge id)[UIColor colorWithRed:0.741 green:0.808 blue:0.937 alpha:1.0].CGColor,
                  nil];
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFTypeRef)colors, NULL);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawLinearGradient(ctx, gradient, CGPointZero, CGPointMake(0, CGRectGetHeight(self.bounds)), 0);
    CGGradientRelease(gradient);
    CGContextRestoreGState(ctx);
    
    if (self.highlighted) {
        [[UIColor colorWithRed:0.275 green:0.478 blue:0.871 alpha:1.0] set];
    }
    else {
        [[UIColor colorWithRed:0.667 green:0.757 blue:0.914 alpha:1.0] set];
    }
    
    path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.5, 0.5) cornerRadius:radius];
    [path setLineWidth:1.0];
    [path stroke];
    
    if (self.highlighted) {
        [[UIColor whiteColor] set];
    }
    else {
        [[UIColor blackColor] set];
    }
    
    UIFont *titleFont = [UIFont systemFontOfSize:kTokenFieldFontSize];
    CGSize titleSize = [self.title sizeWithFont:titleFont];
    CGRect titleFrame = CGRectMake((CGRectGetWidth(self.bounds) - titleSize.width) / 2.0,
                                   (CGRectGetHeight(self.bounds) - titleSize.height) / 2.0,
                                   titleSize.width,
                                   titleSize.height);
    
    [self.title drawInRect:titleFrame withFont:titleFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentCenter];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ title: '%@'; associatedObj: '%@'>",
            NSStringFromClass(isa), self.title, self.associatedObject];
}

@end
