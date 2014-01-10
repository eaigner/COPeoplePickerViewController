//
//  COEmailTableCell.h
//  COPeoplePickerViewController
//
//  Created by Maciej Trybiło on 17/06/2013.
//  Copyright (c) 2013 chocomoko.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class COPerson;

@interface COEmailTableCell : UITableViewCell

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *emailLabelLabel;
@property (nonatomic, strong) UILabel *emailAddressLabel;
@property (nonatomic, strong) COPerson *associatedRecord;

- (void)adjustLabels;

@end
