//
//  CORecord.h
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Improvements by Jordi Aragones on 18.09.12
//  Copyright (c) 2011-2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "COPerson.h"

@interface CORecord : NSObject
    @property (nonatomic, copy, readwrite) NSString *title;
    @property (nonatomic, strong, readwrite) COPerson *person;
@end