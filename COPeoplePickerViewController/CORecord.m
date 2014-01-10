//
//  CORecord.m
//  COPeoplePickerViewController
//
//  Created by Maciej Trybiło on 17/06/2013.
//  Copyright (c) 2013 chocomoko.com. All rights reserved.
//

#import "CORecord.h"
#import "COPerson.h"

@implementation CORecord

@synthesize title = _title;
@synthesize person = _person;

- (id)initWithTitle:(NSString *)title person:(COPerson *)person {
    self = [super init];
    if (self) {
        self.title = title;
        self.person = person;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ title: '%@'; person: '%@'>",
            NSStringFromClass([self class]), self.title, self.person];
}

@end
