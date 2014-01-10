//
//  COPerson.h
//  COPeoplePickerViewController
//
//  Created by Maciej Trybiło on 17/06/2013.
//  Copyright (c) 2013 chocomoko.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

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
