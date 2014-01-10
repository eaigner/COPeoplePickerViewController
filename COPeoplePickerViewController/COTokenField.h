//
//  COTokenField.h
//  COPeoplePickerViewController
//
//  Created by Maciej Trybiło on 17/06/2013.
//  Copyright (c) 2013 chocomoko.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

extern const CGFloat kTokenFieldShadowHeight;

@class COTokenField;
@class COToken;
@class COPerson;

@protocol COTokenFieldDelegate <NSObject>
@required

- (void)tokenFieldDidPressAddContactButton:(COTokenField *)tokenField;
- (ABAddressBookRef)addressBookForTokenField:(COTokenField *)tokenField;
- (void)tokenField:(COTokenField *)tokenField updateAddressBookSearchResults:(NSArray *)records;
- (void)tokenField:(COTokenField *)tokenField searchingModeChanged:(BOOL)isInSearchingMode;

@end

@interface COTokenField : UIView <UITextFieldDelegate>
@property (nonatomic, weak) id<COTokenFieldDelegate> tokenFieldDelegate;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) NSString *hint;
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
