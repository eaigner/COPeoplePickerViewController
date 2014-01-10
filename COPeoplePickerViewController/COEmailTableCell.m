//
//  COEmailTableCell.m
//  COPeoplePickerViewController
//
//  Created by Maciej Trybiło on 17/06/2013.
//  Copyright (c) 2013 chocomoko.com. All rights reserved.
//

#import "COEmailTableCell.h"

#import "UIFont+Blinkbox.h"
#import "UIColor+Blinkbox.h"
#import "UIView+Shifting.h"

@implementation COEmailTableCell

@synthesize nameLabel = _nameLabel;
@synthesize emailLabelLabel = _emailLabelLabel;
@synthesize emailAddressLabel = _emailAddressLabel;
@synthesize associatedRecord = _associatedRecord;

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.nameLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.nameLabel.font = [UIFont blinkboxMediumFontOfSize:16];
        self.nameLabel.textColor = [UIColor blinkboxDarkGrey];
        self.nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.emailLabelLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.emailLabelLabel.font = [UIFont blinkboxMediumFontOfSize:14];
        self.emailLabelLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        self.emailLabelLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        
        self.emailAddressLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.emailAddressLabel.font = [UIFont blinkboxBookFontOfSize:14];
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
    
    self.nameLabel.frame =
    CGRectMake(leftInset,
               yInset + 1,
               CGRectGetWidth(self.bounds) - leftInset * 2,
               CGRectGetHeight(self.bounds) / 2.0 - yInset);
    
    self.emailLabelLabel.frame =
    CGRectMake(leftInset,
               CGRectGetMaxY(self.nameLabel.frame),
               labelWidth,
               CGRectGetHeight(self.bounds) / 2.0 - yInset);
    
    self.emailAddressLabel.frame =
    CGRectMake(labelWidth + leftInset * 2,
               CGRectGetMaxY(self.nameLabel.frame),
               CGRectGetWidth(self.bounds) - labelWidth - leftInset * 3,
               CGRectGetHeight(self.bounds) / 2.0 - yInset);
}

@end
