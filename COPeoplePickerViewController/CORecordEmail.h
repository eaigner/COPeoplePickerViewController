//
//  CORecordEmail.h
//  COPeoplePickerViewController
//
//  Created by Maciej Trybiło on 17/06/2013.
//  Copyright (c) 2013 chocomoko.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

@interface CORecordEmail : NSObject {
@private
    ABMultiValueRef         emails_;
    ABMultiValueIdentifier  identifier_;
}

@property (nonatomic, readonly) NSString *label;
@property (nonatomic, readonly) NSString *address;

- (id)initWithEmails:(ABMultiValueRef)emails
          identifier:(ABMultiValueIdentifier)identifier;

@end
