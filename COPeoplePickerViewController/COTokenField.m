//
//  COTokenField.m
//  COPeoplePickerViewController
//
//  Created by Maciej Trybiło on 17/06/2013.
//  Copyright (c) 2013 chocomoko.com. All rights reserved.
//

#import "COTokenField.h"
#import "COToken.h"
#import "COPerson.h"
#import "CORecordEmail.h"

#import "UIFont+Blinkbox.h"

const CGFloat kTokenFieldShadowHeight = 14.0;

@implementation COTokenField

static NSString *kCOTokenFieldDetectorString = @"\u200B";

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.tokens = [NSMutableArray new];
        self.opaque = NO;
        self.backgroundColor = [UIColor whiteColor];
        
        // Setup contact add button
        self.addContactButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        self.addContactButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        
        [self.addContactButton addTarget:self action:@selector(addContact:) forControlEvents:UIControlEventTouchUpInside];
        
        CGRect buttonFrame = self.addContactButton.frame;
        self.addContactButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - CGRectGetWidth(buttonFrame) - kTokenFieldPaddingX,
                                                 CGRectGetHeight(self.bounds) - CGRectGetHeight(buttonFrame) - kTokenFieldPaddingY,
                                                 buttonFrame.size.height,
                                                 buttonFrame.size.width);
        
        // LC: In iOS 7, this guy is seriously messed up. This button pops open the user's
        // contact list and allows them to select one, it's a stock Apple control and we have
        // no customisable control over it. It's unusable as is, so it will need to be
        // revisited and fixed up for iOS7 at a later date. It in no way makes the share via
        // email option unusable, it just means the user has to type the first couple of
        // characters of the recipient's name or email address instead of browsing the whole list.
        //[self addSubview:self.addContactButton];
        
        // Setup text field
        CGFloat textFieldHeight = self.computedRowHeight;
        self.textField = [[UITextField alloc] initWithFrame:CGRectMake(kTokenFieldPaddingX,
                                                                       (CGRectGetHeight(self.bounds) - textFieldHeight) / 2.0,
                                                                       CGRectGetWidth(self.bounds) - CGRectGetWidth(buttonFrame) - kTokenFieldPaddingX * 3.0,
                                                                       textFieldHeight)];
        self.textField.opaque = NO;
        self.textField.backgroundColor = [UIColor clearColor];
        self.textField.font = [UIFont blinkboxBookFontOfSize:kTokenFieldFontSize];
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.textField.text = kCOTokenFieldDetectorString;
        self.textField.delegate = self;
        
        UILabel *hintLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        hintLabel.font = self.textField.font;
        hintLabel.textColor = [UIColor grayColor];
        
        self.hintLabel = hintLabel;
        [self addSubview:hintLabel];
        
        [self.textField addTarget:self action:@selector(tokenInputChanged:) forControlEvents:UIControlEventEditingChanged];
        
        [self addSubview:self.textField];
        
        [self setNeedsLayout];
    }
    return self;
}

- (void)setHint:(NSString *)hint
{
    UILabel *hintLabel = self.hintLabel;
    hintLabel.text = hint;
    [hintLabel sizeToFit];
    
    CGRect frame = hintLabel.frame;
    frame.origin = CGPointMake(kTokenFieldPaddingX, kTokenFieldPaddingY);
    frame.size.height = self.textField.frame.size.height;
    frame.size.width += 5;
    hintLabel.frame = frame;
}

- (NSString *)hint
{
    return self.hintLabel.text;
}

- (void)addContact:(id)sender {
#pragma unused (sender)
    id<COTokenFieldDelegate> tokenFieldDelegate = self.tokenFieldDelegate;
    [tokenFieldDelegate tokenFieldDidPressAddContactButton:self];
}

- (CGFloat)computedRowHeight {
    CGFloat buttonHeight = CGRectGetHeight(self.addContactButton.frame);
    return MAX(buttonHeight, (CGFloat)(kTokenFieldPaddingY * 2.0 + kTokenFieldTokenHeight));
}

- (CGFloat)heightForNumberOfRows:(NSUInteger)rows {
    return (CGFloat)rows * self.computedRowHeight + (CGFloat)kTokenFieldPaddingY * 2.0f;
}

- (void)layoutSubviews {
    NSUInteger row = 0;
    
    // span of the free space in the last row
    CGFloat left = self.hintLabel.frame.size.width + self.hintLabel.frame.origin.x;
    CGFloat right =
    self.frame.size.width -
    CGRectGetWidth(self.addContactButton.frame) -
    kTokenFieldPaddingX;
    
    CGFloat rowHeight = self.computedRowHeight;
    
    for (COToken *token in self.tokens) {
        
        CGFloat tokenRight = left + CGRectGetWidth(token.bounds);
        if (tokenRight > right) {
            row++;
            left = kTokenFieldPaddingX;
        }
        
        // Adjust token frame
        CGRect tokenFrame = token.frame;
        tokenFrame.origin.x = left;
        tokenFrame.origin.y =
        row * rowHeight +
        (rowHeight - CGRectGetHeight(tokenFrame)) / 2.0f +
        kTokenFieldPaddingY;
        
        token.frame = tokenFrame;
        
        left += CGRectGetWidth(tokenFrame) + kTokenFieldPaddingX;
        
        [self addSubview:token];
    }
    
    if (right - left < 50) {
        row++;
        left = kTokenFieldPaddingX;
    }
    
    // adjust the text field frame
    CGRect textFieldFrame = self.textField.frame;
    
    textFieldFrame.origin.x = left;
    textFieldFrame.origin.y =
    row * rowHeight +
    (rowHeight - CGRectGetHeight(textFieldFrame)) / 2.0f +
    kTokenFieldPaddingY;
    
    textFieldFrame.size = CGSizeMake(right - left,
                                     CGRectGetHeight(textFieldFrame));
    
    self.textField.frame = textFieldFrame;
    
    // adjust the height of the self
    CGRect tokenFieldFrame = self.frame;
    CGFloat minHeight = MAX(rowHeight,
                            CGRectGetHeight(self.addContactButton.frame) + kTokenFieldPaddingY * 2.0f);
    
    tokenFieldFrame.size.height = MAX(minHeight,
                                      CGRectGetMaxY(textFieldFrame) + kTokenFieldPaddingY);
    
    self.frame = tokenFieldFrame;
}

- (void)selectToken:(COToken *)token {
    @synchronized (self) {
        if (token != nil) {
            self.textField.hidden = YES;
        }
        else {
            self.textField.hidden = NO;
            [self.textField becomeFirstResponder];
        }
        self.selectedToken = token;
        for (COToken *t in self.tokens) {
            t.highlighted = (t == token);
            [t setNeedsDisplay];
        }
    }
}

- (void)removeAllTokens {
    for (COToken *token in self.tokens) {
        [token removeFromSuperview];
    }
    [self.tokens removeAllObjects];
    self.textField.hidden = NO;
    self.selectedToken = nil;
    [self setNeedsLayout];
}

- (void)removeToken:(COToken *)token {
    [token removeFromSuperview];
    [self.tokens removeObject:token];
    self.textField.hidden = NO;
    self.selectedToken = nil;
    [self setNeedsLayout];
}

- (void)modifyToken:(COToken *)token {
    if (token != nil) {
        if (token == self.selectedToken) {
            [self removeToken:token];
        }
        else {
            [self selectToken:token];
        }
        [self setNeedsLayout];
    }
}

- (void)modifySelectedToken {
    COToken *token = self.selectedToken;
    if (token == nil) {
        token = [self.tokens lastObject];
    }
    [self modifyToken:token];
}

- (void)processToken:(NSString *)tokenText associatedRecord:(COPerson *)record {
    COToken *token = [COToken tokenWithTitle:tokenText associatedObject:record container:self];
    [token addTarget:self action:@selector(selectToken:) forControlEvents:UIControlEventTouchUpInside];
    [self.tokens addObject:token];
    self.textField.text = kCOTokenFieldDetectorString;
    id<COTokenFieldDelegate> tokenFieldDelegate = self.tokenFieldDelegate;
    [tokenFieldDelegate tokenField:self searchingModeChanged:NO];
    [self setNeedsLayout];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
#pragma unused (touches, event)
    [self selectToken:nil];
}

- (NSString *)textWithoutDetector {
    NSString *text = self.textField.text;
    if (text.length > 0) {
        return [text substringFromIndex:1];
    }
    return text;
}

static BOOL containsString(NSString *haystack, NSString *needle) {
    return ([haystack rangeOfString:needle options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location != NSNotFound);
}

- (void)tokenInputChanged:(id)sender {
#pragma unused (sender)
    NSString *searchText = self.textWithoutDetector;
    NSArray *matchedRecords = @[];
    id<COTokenFieldDelegate> tokenFieldDelegate = self.tokenFieldDelegate;
    if (searchText.length > 2) {
        // Generate new search dict only after a certain delay
        static NSDate *lastUpdated = nil;;
        static NSMutableArray *records = nil;
        if (records == nil || [lastUpdated timeIntervalSinceDate:[NSDate date]] < -10) {
            ABAddressBookRef ab = [tokenFieldDelegate addressBookForTokenField:self];
            NSArray *people = CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(ab));
            records = [NSMutableArray new];
            for (id obj in people) {
                ABRecordRef recordRef = (__bridge CFTypeRef)obj;
                COPerson *record = [[COPerson alloc] initWithABRecordRef:recordRef];
                [records addObject:record];
            }
            lastUpdated = [NSDate date];
        }
        
        NSIndexSet *resultSet = [records indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
#pragma unused (idx, stop)
            COPerson *record = (COPerson *)obj;
            if ([record.fullName length] != 0 && containsString(record.fullName, searchText)) {
                return YES;
            }
            for (CORecordEmail *email in record.emailAddresses) {
                if (containsString(email.address, searchText)) {
                    return YES;
                }
            }
            return NO;
        }];
        
        // Generate results to pass to the delegate
        matchedRecords = [records objectsAtIndexes:resultSet];
    }
    
    [tokenFieldDelegate tokenField:self
              searchingModeChanged:[self.textField.text length] > 1];
    
    [tokenFieldDelegate tokenField:self updateAddressBookSearchResults:matchedRecords];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
#pragma unused (range)
    if (string.length == 0 && [textField.text isEqualToString:kCOTokenFieldDetectorString]) {
        [self modifySelectedToken];
        return NO;
    }
    else if (textField.hidden) {
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.hidden) {
        return NO;
    }
    NSString *text = self.textField.text;
    if ([text length] > 1) {
        [self processToken:[text substringFromIndex:1] associatedRecord:nil];
    }
    else {
        return [textField resignFirstResponder];
    }
    return YES;
}

@end

