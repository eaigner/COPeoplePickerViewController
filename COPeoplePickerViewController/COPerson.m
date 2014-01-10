//
//  COPerson.m
//  COPeoplePickerViewController
//
//  Created by Maciej Trybiło on 17/06/2013.
//  Copyright (c) 2013 chocomoko.com. All rights reserved.
//

#import "COPerson.h"
#import "CORecordEmail.h"

@implementation COPerson {
@private
    ABRecordRef record_;
}

- (id)initWithABRecordRef:(ABRecordRef)record
{
    self = [super init];
    if (self) {
        if (record != NULL) {
            record_ = CFRetain(record);
        }
    }
    return self;
}

- (void)dealloc
{
    if (record_) {
        CFRelease(record_);
        record_ = NULL;
    }
}

- (NSString *)fullName
{
    return CFBridgingRelease(ABRecordCopyCompositeName(record_));
}

- (NSString *)namePrefix
{
    return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonPrefixProperty));
}

- (NSString *)firstName
{
    return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonFirstNameProperty));
}

- (NSString *)middleName
{
    return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonMiddleNameProperty));
}

- (NSString *)lastName
{
    return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonLastNameProperty));
}

- (NSString *)nameSuffix
{
    return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonSuffixProperty));
}

- (NSArray *)emailAddresses
{
    NSMutableArray *addresses = [NSMutableArray new];
    ABMultiValueRef emails = ABRecordCopyValue(record_, kABPersonEmailProperty);
    CFIndex multiCount = ABMultiValueGetCount(emails);
    for (CFIndex i=0; i<multiCount; i++) {
        
        CORecordEmail *email =
        [[CORecordEmail alloc] initWithEmails:emails
                                   identifier:ABMultiValueGetIdentifierAtIndex(emails, i)];
        [addresses addObject:email];
    }
    
    if (emails != NULL) {
        CFRelease(emails);
    }
    
    return [NSArray arrayWithArray:addresses];
}

- (ABRecordRef)record
{
    return record_;
}

@end
