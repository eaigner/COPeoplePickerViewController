//
//  CORecordEmail.m
//  COPeoplePickerViewController
//
//  Created by Maciej Trybiło on 17/06/2013.
//  Copyright (c) 2013 chocomoko.com. All rights reserved.
//

#import "CORecordEmail.h"

@implementation CORecordEmail

- (id)initWithEmails:(ABMultiValueRef)emails
          identifier:(ABMultiValueIdentifier)identifier
{
    self = [super init];
    if (self) {
        if (emails != NULL) {
            emails_ = CFRetain(emails);
        }
        identifier_ = identifier;
    }
    return self;
}

- (void)dealloc
{
    if (emails_ != NULL) {
        CFRelease(emails_);
        emails_ = NULL;
    }
}

- (NSString *)label
{
    CFStringRef label =
    ABMultiValueCopyLabelAtIndex(emails_, ABMultiValueGetIndexForIdentifier(emails_, identifier_));
    
    if (label != NULL) {
        CFStringRef localizedLabel = ABAddressBookCopyLocalizedLabel(label);
        CFRelease(label);
        return CFBridgingRelease(localizedLabel);
    }
    return @"email";
}

- (NSString *)address
{
    return CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails_,
                                                          ABMultiValueGetIndexForIdentifier(emails_, identifier_)));
}

@end
