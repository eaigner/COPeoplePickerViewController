//
//  COTokenField.m
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Improvements by Jordi Aragones on 18.09.12
//  Copyright (c) 2011-2012. All rights reserved.
//

#import "COTokenField.h"
#import "Constants.h"

#import "COToken.h"
#import "COPerson.h"
#import "CORecordPhone.h"
#import "CORecordEmail.h"

@implementation COTokenField

COSynth(tokenFieldDelegate)
COSynth(textField)
COSynth(addContactButton)
COSynth(tokens)
COSynth(selectedToken)

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
        
        [self addSubview:self.addContactButton];
        
        // Setup text field
        CGFloat textFieldHeight = self.computedRowHeight;
        self.textField = [[UITextField alloc] initWithFrame:CGRectMake(kTokenFieldPaddingX,
                                                                       (CGRectGetHeight(self.bounds) - textFieldHeight) / 2.0,
                                                                       CGRectGetWidth(self.bounds) - CGRectGetWidth(buttonFrame) - kTokenFieldPaddingX * 3.0,
                                                                       textFieldHeight)];
        self.textField.opaque = NO;
        self.textField.backgroundColor = [UIColor clearColor];
        self.textField.font = [UIFont systemFontOfSize:kTokenFieldFontSize];
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.textField.text = kCOTokenFieldDetectorString;
        self.textField.delegate = self;
        
        [self.textField addTarget:self action:@selector(tokenInputChanged:) forControlEvents:UIControlEventEditingChanged];
        
        [self addSubview:self.textField];
        
        [self setNeedsLayout];
    }
    return self;
}

- (void)addContact:(id)sender {
    [self.tokenFieldDelegate tokenFieldDidPressAddContactButton:self];
}

- (CGFloat)computedRowHeight {
    CGFloat buttonHeight = CGRectGetHeight(self.addContactButton.frame);
    return MAX(buttonHeight, (kTokenFieldPaddingY * 2.0 + kTokenFieldTokenHeight));
}

- (CGFloat)heightForNumberOfRows:(NSUInteger)rows {
    return (CGFloat)rows * self.computedRowHeight + kTokenFieldPaddingY * 2.0;
}

- (void)layoutSubviews {
    NSUInteger row = 0;
    NSInteger tokenCount = self.tokens.count;
    
    CGFloat left = kTokenFieldPaddingX;
    CGFloat maxLeft = CGRectGetWidth(self.bounds) - kTokenFieldPaddingX;
    CGFloat rowHeight = self.computedRowHeight;
    
    for (NSInteger i=0; i<tokenCount; i++) {
        COToken *token = [self.tokens objectAtIndex:i];
        CGFloat right = left + CGRectGetWidth(token.bounds);
        if (right > maxLeft) {
            row++;
            left = kTokenFieldPaddingX;
        }
        
        // Adjust token frame
        CGRect tokenFrame = token.frame;
        tokenFrame.origin = CGPointMake(left, (CGFloat)row * rowHeight + (rowHeight - CGRectGetHeight(tokenFrame)) / 2.0 + kTokenFieldPaddingY);
        token.frame = tokenFrame;
        
        left += CGRectGetWidth(tokenFrame) + kTokenFieldPaddingX;
        
        [self addSubview:token];
    }
    
    CGFloat maxLeftWithButton = maxLeft - kTokenFieldPaddingX - CGRectGetWidth(self.addContactButton.frame);
    if (maxLeftWithButton - left < 50) {
        row++;
        left = kTokenFieldPaddingX;
    }
    
    CGRect textFieldFrame = self.textField.frame;
    textFieldFrame.origin = CGPointMake(left, (CGFloat)row * rowHeight + (rowHeight - CGRectGetHeight(textFieldFrame)) / 2.0 + kTokenFieldPaddingY);
    textFieldFrame.size = CGSizeMake(maxLeftWithButton - left, CGRectGetHeight(textFieldFrame));
    self.textField.frame = textFieldFrame;
    
    CGRect tokenFieldFrame = self.frame;
    CGFloat minHeight = MAX(rowHeight, CGRectGetHeight(self.addContactButton.frame) + kTokenFieldPaddingY * 2.0);
    tokenFieldFrame.size.height = MAX(minHeight, CGRectGetMaxY(textFieldFrame) + kTokenFieldPaddingY);
    
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
    [self setNeedsLayout];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
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
    NSString *searchText = self.textWithoutDetector;
    NSArray *matchedRecords = [NSArray array];
    if (searchText.length > 2) {
        // Generate new search dict only after a certain delay
        static NSDate *lastUpdated = nil;;
        static NSMutableArray *records = nil;
        if (records == nil || [lastUpdated timeIntervalSinceDate:[NSDate date]] < -10) {
            ABAddressBookRef ab = [self.tokenFieldDelegate addressBookForTokenField:self];
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
            COPerson *record = (COPerson *)obj;
            if ([record.fullName length] != 0 && containsString(record.fullName, searchText)) {
                return YES;
            }
            for (CORecordPhone *phone in record.phoneNumbers) {
                if (containsString(phone.number, searchText)) {
                    return YES;
                }
            }
            return NO;
        }];
        
        // Generate results to pass to the delegate
        matchedRecords = [records objectsAtIndexes:resultSet];
    }
    [self.tokenFieldDelegate tokenField:self updateAddressBookSearchResults:matchedRecords];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
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

