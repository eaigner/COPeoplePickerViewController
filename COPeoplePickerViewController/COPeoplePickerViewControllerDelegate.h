//
//  COPeoplePickerViewControllerDelegate.h
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Improvements by Jordi Aragones on 18.09.12
//  Copyright (c) 2011-2012. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "COPeoplePickerViewController.h"

@protocol COPeoplePickerViewControllerDelegate <NSObject>
@optional

- (void)peoplePickerViewControllerDidFinishPicking:(COPeoplePickerViewController *)controller;

@end

@interface COPeoplePickerViewControllerDelegate : NSObject

@end