//
//  COEmailTableCellCell.m
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Improvements by Jordi Aragones on 18.09.12
//  Copyright (c) 2011-2012. All rights reserved.
//

#import "COEmailTableCellCell.h"
#import "Constants.h"

@implementation COEmailTableCell

COSynth(nameLabel)
COSynth(emailLabelLabel)
COSynth(emailAddressLabel)
COSynth(associatedRecord)

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.nameLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.nameLabel.font = [UIFont boldSystemFontOfSize:16];
        self.nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.emailLabelLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.emailLabelLabel.font = [UIFont boldSystemFontOfSize:14];
        self.emailLabelLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        self.emailLabelLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        self.emailAddressLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.emailAddressLabel.font = [UIFont systemFontOfSize:14];
        self.emailAddressLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        self.emailAddressLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self addSubview:self.nameLabel];
        [self addSubview:self.emailLabelLabel];
        [self addSubview:self.emailAddressLabel];
        
        [self adjustLabels];
    }
    return self;
}

- (void)adjustLabels {
    CGSize emailLabelSize = [self.emailLabelLabel.text sizeWithFont:self.emailLabelLabel.font];
    CGFloat leftInset = 8;
    CGFloat yInset = 4;
    CGFloat labelWidth = emailLabelSize.width;
    self.nameLabel.frame = CGRectMake(leftInset, yInset, CGRectGetWidth(self.bounds) - leftInset * 2, CGRectGetHeight(self.bounds) / 2.0 - yInset);
    self.emailLabelLabel.frame = CGRectMake(leftInset, CGRectGetMaxY(self.nameLabel.frame), labelWidth, CGRectGetHeight(self.bounds) / 2.0 - yInset);
    self.emailAddressLabel.frame = CGRectMake(labelWidth + leftInset * 2, CGRectGetMaxY(self.nameLabel.frame), CGRectGetWidth(self.bounds) - labelWidth - leftInset * 3, CGRectGetHeight(self.bounds) / 2.0 - yInset);
}

@end
