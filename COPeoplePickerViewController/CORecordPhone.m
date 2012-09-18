//
//  CORecordPhone.m
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Improvements by Jordi Aragones on 18.09.12
//  Copyright (c) 2011-2012. All rights reserved.
//

#import "CORecordPhone.h"

@implementation CORecordPhone

- (id)initWithNumbers:(ABMultiValueRef)phones identifier:(ABMultiValueIdentifier)identifier {
    self = [super init];
    if (self) {
        if (phones != NULL) {
            phones_ = CFRetain(phones);
        }
        identifier_ = identifier;
    }
    return self;
}

- (void)dealloc {
    if (phones_ != NULL) {
        CFRelease(phones_);
        phones_ = NULL;
    }
}

- (NSString *)label {
    CFStringRef label = ABMultiValueCopyLabelAtIndex(phones_, ABMultiValueGetIndexForIdentifier(phones_, identifier_));
    if (label != NULL) {
        CFStringRef localizedLabel = ABAddressBookCopyLocalizedLabel(label);
        CFRelease(label);
        return CFBridgingRelease(localizedLabel);
    }
    return @"phone";
}

- (NSString *)number {
    return CFBridgingRelease(ABMultiValueCopyValueAtIndex(phones_, ABMultiValueGetIndexForIdentifier(phones_, identifier_)));
}

@end