//
//  CORecordEmail.h
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Improvements by Jordi Aragones on 18.09.12
//  Copyright (c) 2011-2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface CORecordEmail : NSObject {
@private
    ABMultiValueRef         emails_;
    ABMultiValueIdentifier  identifier_;
}
@property (nonatomic, readonly) NSString *label;
@property (nonatomic, readonly) NSString *address;

- (id)initWithEmails:(ABMultiValueRef)emails identifier:(ABMultiValueIdentifier)identifier;

@end
