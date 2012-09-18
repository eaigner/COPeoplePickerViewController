//
//  COPerson.m
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Improvements by Jordi Aragones on 18.09.12
//  Copyright (c) 2011-2012. All rights reserved.
//

#import "COPerson.h"
#import "CORecordEmail.h"
#import "CORecordPhone.h"

@implementation COPerson {
@private
    ABRecordRef record_;
}

- (id)initWithABRecordRef:(ABRecordRef)record {
    self = [super init];
    if (self) {
        if (record != NULL) {
            record_ = CFRetain(record);
        }
    }
    return self;
}

- (void)dealloc {
    if (record_) {
        CFRelease(record_);
        record_ = NULL;
    }
}

- (NSString *)fullName {
    return CFBridgingRelease(ABRecordCopyCompositeName(record_));
}

- (NSString *)namePrefix {
    return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonPrefixProperty));
}

- (NSString *)firstName {
    return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonFirstNameProperty));
}

- (NSString *)middleName {
    return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonMiddleNameProperty));
}

- (NSString *)lastName {
    return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonLastNameProperty));
}

- (NSString *)nameSuffix {
    return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonSuffixProperty));
}

- (NSArray *)emailAddresses {
    NSMutableArray *addresses = [NSMutableArray new];
    ABMultiValueRef emails = ABRecordCopyValue(record_, kABPersonEmailProperty);
    CFIndex multiCount = ABMultiValueGetCount(emails);
    for (CFIndex i=0; i<multiCount; i++) {
        CORecordEmail *email = [[CORecordEmail alloc] initWithEmails:emails
                                                          identifier:ABMultiValueGetIdentifierAtIndex(emails, i)];
        [addresses addObject:email];
    }
    CFRelease(emails);
    return [NSArray arrayWithArray:addresses];
}

- (NSArray *)phoneNumbers {
    NSMutableArray *numbers = [NSMutableArray new];
    ABMultiValueRef phones = ABRecordCopyValue(record_, kABPersonPhoneProperty);
    CFIndex multiCount = ABMultiValueGetCount(phones);
    for (CFIndex i=0; i<multiCount; i++) {
        CORecordPhone *number = [[CORecordPhone alloc] initWithNumbers:phones
                                                            identifier:ABMultiValueGetIdentifierAtIndex(phones, i)];
        [numbers addObject:number];
    }
    CFRelease(phones);
    return [NSArray arrayWithArray:numbers];
}

- (ABRecordRef)record {
    return record_;
}

@end
