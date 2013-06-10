//
//  COPeoplePickerViewController.h
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Copyright (c) 2011 chocomoko.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

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

/*!
 @method resetTokenFieldWithRecords:
 @abstract Resets the token field if controller was initialized previously.
 */
- (void)resetTokenFieldWithRecords:(NSArray *)records;

@end

@interface COPerson : NSObject
@property (nonatomic, readonly) NSString *fullName;
@property (nonatomic, readonly) NSString *namePrefix;
@property (nonatomic, readonly) NSString *firstName;
@property (nonatomic, readonly) NSString *middleName;
@property (nonatomic, readonly) NSString *lastName;
@property (nonatomic, readonly) NSString *nameSuffix;
@property (nonatomic, readonly) NSArray *emailAddresses;
@property (nonatomic, readonly) ABRecordRef record;

- (id)initWithABRecordRef:(ABRecordRef)record;

@end

@interface CORecord : NSObject
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, strong, readonly) COPerson *person;

- (id)initWithTitle:(NSString *)title person:(COPerson *)person;

@end

@protocol COPeoplePickerViewControllerDelegate <NSObject>
@optional

- (void)peoplePickerViewControllerDidFinishPicking:(COPeoplePickerViewController *)controller;

@end
