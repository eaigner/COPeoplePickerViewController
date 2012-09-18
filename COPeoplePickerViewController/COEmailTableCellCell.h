//
//  COEmailTableCellCell.h
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Improvements by Jordi Aragones on 18.09.12
//  Copyright (c) 2011-2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "COPerson.h"

@interface COEmailTableCell : UITableViewCell

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *emailLabelLabel;
@property (nonatomic, strong) UILabel *emailAddressLabel;
@property (nonatomic, strong) COPerson *associatedRecord;

- (void)adjustLabels;

@end