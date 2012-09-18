//
//  COPeoplePickerViewController.h
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Improvements by Jordi Aragones on 18.09.12
//  Copyright (c) 2011-2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

#import "COPerson.h"
#import "COTokenField.h"

@protocol COPeoplePickerViewControllerDelegate;

@interface COPeoplePickerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, COTokenFieldDelegate, ABPeoplePickerNavigationControllerDelegate> {
@private
    ABAddressBookRef addressBook_;
    CGRect           keyboardFrame_;
}

@property (nonatomic, weak) id<COPeoplePickerViewControllerDelegate> delegate;
@property (nonatomic, readonly) ABAddressBookRef addressBookRef;
@property (nonatomic, copy) NSArray *displayedProperties;
@property (nonatomic, strong) NSNumber *property;
@property (nonatomic, readonly) NSArray *selectedRecords;

@property (nonatomic, strong) COTokenField *tokenField;
@property (nonatomic, strong) UIScrollView *tokenFieldScrollView;
@property (nonatomic, strong) UITableView *searchTableView;
@property (nonatomic, strong) NSArray *discreteSearchResults;
@property (nonatomic, strong) CAGradientLayer *shadowLayer;

- (void)resetTokenFieldWithRecords:(NSArray *)records;

@end