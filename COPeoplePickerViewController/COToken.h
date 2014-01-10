//
//  COToken.h
//  COPeoplePickerViewController
//
//  Created by Maciej Trybiło on 17/06/2013.
//  Copyright (c) 2013 chocomoko.com. All rights reserved.
//

#import <UIKit/UIKit.h>

extern const CGFloat kTokenFieldFontSize;
extern const CGFloat kTokenFieldTokenHeight;
extern const CGFloat kTokenFieldPaddingX;
extern const CGFloat kTokenFieldPaddingY;

@class COTokenField;

@interface COToken : UIButton
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) id associatedObject;
@property (nonatomic, strong) COTokenField *container;

+ (COToken *)tokenWithTitle:(NSString *)title
           associatedObject:(id)obj
                  container:(COTokenField *)container;

@end
