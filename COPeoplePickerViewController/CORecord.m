//
//  CORecord.m
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Improvements by Jordi Aragones on 18.09.12
//  Copyright (c) 2011-2012. All rights reserved.
//

#import "CORecord.h"
#import "COPerson.h"

#define COSynth(x) @synthesize x = x##_;

@implementation CORecord
COSynth(title)
COSynth(person)

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
            NSStringFromClass(isa), self.title, self.person];
}

@end