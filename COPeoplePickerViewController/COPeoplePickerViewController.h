//
//  COPeoplePickerViewController.h
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Copyright (c) 2011 chocomoko.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>


extern NSString *const COPeoplePickerViewControllerVisibleHeightChanged;

@protocol COPeoplePickerViewControllerDelegate;

@interface COPeoplePickerViewController : UIViewController
@property (nonatomic, weak) id<COPeoplePickerViewControllerDelegate> delegate;

/*!
 @property
 @abstract Returns the address book used by the view controller
 */
@property (nonatomic, readonly) ABAddressBookRef addressBookRef;

/*!
 @property displayedProperties
 @discussion An array of ABPropertyID listing the properties that should be visible when viewing a person.
 If you are interested in one particular type of data (for example a phone number), displayedProperties
 should be an array with a single NSNumber instance (representing kABPersonPhoneProperty).
 Note that name information will always be shown if available.
 
 DEVNOTE: currently only supports email (extend if you need more)
 */
@property (nonatomic, copy) NSArray *displayedProperties;

/*!
 @property selectedRecords
 @abstract Returns an array of CORecord.
 */
@property (nonatomic, readonly) NSArray *selectedRecords;

@property (nonatomic) NSString *hint;

/*!
 @method resetTokenFieldWithRecords:
 @abstract Resets the token field if controller was initialized previously.
 */
- (void)resetTokenFieldWithRecords:(NSArray *)records;

@end

@protocol COPeoplePickerViewControllerDelegate <NSObject>
@optional

- (void)peoplePickerViewControllerDidFinishPicking:(COPeoplePickerViewController *)controller;

@end
