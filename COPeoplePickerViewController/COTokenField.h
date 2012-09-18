//
//  COTokenField.h
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Improvements by Jordi Aragones on 18.09.12
//  Copyright (c) 2011-2012. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COToken.h"
#import "COPerson.h"

#import "COTokenFieldDelegate.h"

@interface COTokenField : UIView <UITextFieldDelegate>

@property (nonatomic, weak) id<COTokenFieldDelegate> tokenFieldDelegate;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *addContactButton;
@property (nonatomic, strong) NSMutableArray *tokens;
@property (nonatomic, strong) COToken *selectedToken;
@property (nonatomic, readonly) CGFloat computedRowHeight;
@property (nonatomic, readonly) NSString *textWithoutDetector;

- (CGFloat)heightForNumberOfRows:(NSUInteger)rows;
- (void)selectToken:(COToken *)token;
- (void)removeAllTokens;
- (void)removeToken:(COToken *)token;
- (void)modifyToken:(COToken *)token;
- (void)modifySelectedToken;
- (void)processToken:(NSString *)tokenText associatedRecord:(COPerson *)record;
- (void)tokenInputChanged:(id)sender;

@end
