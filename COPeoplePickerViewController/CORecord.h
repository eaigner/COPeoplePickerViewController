//
//  CORecord.h
//  COPeoplePickerViewController
//
//  Created by Maciej Trybiło on 17/06/2013.
//  Copyright (c) 2013 chocomoko.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class COPerson;

@interface CORecord : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) COPerson *person;

- (id)initWithTitle:(NSString *)title person:(COPerson *)person;

@end
