//
//  COPeoplePickerViewController.m
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Copyright (c) 2011 chocomoko.com. All rights reserved.
//

#import "COPeoplePickerViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <objc/runtime.h>


#pragma mark - COToken

@class COTokenField;

@interface COToken : UIButton
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) id associatedObject;
@property (nonatomic, strong) COTokenField *container;

+ (COToken *)tokenWithTitle:(NSString *)title associatedObject:(id)obj container:(COTokenField *)container;

@end

#pragma mark - COEmailTableCell

@interface COEmailTableCell : UITableViewCell
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *emailLabelLabel;
@property (nonatomic, strong) UILabel *emailAddressLabel;

- (void)adjustLabels;

@end

#pragma mark - COTokenField Interface & Delegate Protocol

@protocol COTokenFieldDelegate <NSObject>
@required

- (void)tokenFieldDidPressAddContactButton:(COTokenField *)tokenField;
- (ABAddressBookRef)addressBookForTokenField:(COTokenField *)tokenField;
- (void)tokenField:(COTokenField *)tokenField updateAddressBookSearchResults:(NSArray *)records;

@end

#define kTokenFieldFontSize 14.0
#define kTokenFieldPaddingX 6.0
#define kTokenFieldPaddingY 6.0
#define kTokenFieldTokenHeight (kTokenFieldFontSize + 4.0)
#define kTokenFieldMaxTokenWidth 260.0
#define kTokenFieldFrameKeyPath @"frame"
#define kTokenFieldShadowHeight 14.0

@interface COTokenField : UIView <UITextFieldDelegate>
@property (nonatomic, weak) id<COTokenFieldDelegate> tokenFieldDelegate;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *addContactButton;
@property (nonatomic, strong) NSMutableArray *tokens;
@property (nonatomic, strong) COToken *selectedToken;
@property (nonatomic, readonly) CGFloat computedRowHeight;
@property (nonatomic, readonly) NSString *textWithoutDetector;

- (CGFloat)heightForNumberOfRows:(NSUInteger)rows;
- (void)selectToken:(COToken *)token;
- (void)modifyToken:(COToken *)token;
- (void)modifySelectedToken;
- (void)processToken:(NSString *)tokenText;
- (void)tokenInputChanged:(id)sender;

@end

#pragma mark - Data Structures

@interface CORecord : NSObject {
@package
  ABRecordRef record_;
}
@property (nonatomic, readonly) NSString *fullName;
@property (nonatomic, readonly) NSString *namePrefix;
@property (nonatomic, readonly) NSString *firstName;
@property (nonatomic, readonly) NSString *middleName;
@property (nonatomic, readonly) NSString *lastName;
@property (nonatomic, readonly) NSString *nameSuffix;
@property (nonatomic, readonly) NSArray *emailAddresses;
@end

@interface CORecordEmail : NSObject {
@package
  ABMultiValueRef         emails_;
  ABMultiValueIdentifier  identifier_;
}
@property (nonatomic, readonly) NSString *label;
@property (nonatomic, readonly) NSString *address;
@end

#pragma mark - COPeoplePickerViewController

@interface COPeoplePickerViewController () <UITableViewDelegate, UITableViewDataSource, COTokenFieldDelegate, ABPeoplePickerNavigationControllerDelegate> {
@package
  ABAddressBookRef addressBook_;
  CGRect           keyboardFrame_;
}
@property (nonatomic, strong) COTokenField *tokenField;
@property (nonatomic, strong) UIScrollView *tokenFieldScrollView;
@property (nonatomic, strong) UITableView *searchTableView;
@property (nonatomic, strong) NSArray *discreteSearchResults;
@property (nonatomic, strong) CAGradientLayer *shadowLayer;
@end

@implementation COPeoplePickerViewController
@synthesize tokenField = tokenField_;
@synthesize tokenFieldScrollView = tokenFieldScrollView_;
@synthesize searchTableView = searchTableView_;
@synthesize displayedProperties = displayedProperties_;
@synthesize discreteSearchResults = discreteSearchResults_;
@synthesize shadowLayer = shadowLayer_;

- (id)init {
  self = [super init];
  if (self) {
    keyboardFrame_ = CGRectNull;
    // DEVNOTE: A workaround to force initialization of ABPropertyIDs.
    // If we don't create the address book here and try to set |displayedProperties| first
    // all ABPropertyIDs will default to '0'.
    //
    // Filed rdar://10526251
    //
    addressBook_ = ABAddressBookCreate();
  }
  return self;
}

- (void)dealloc {
  if (addressBook_ != NULL) {
    CFRelease(addressBook_);
    addressBook_ = NULL;
  }
}

- (void)viewDidLoad {  
  // Configure content view
  self.view.backgroundColor = [UIColor colorWithRed:0.859 green:0.886 blue:0.925 alpha:1.0];
  
  // Configure token field
  CGRect viewBounds = self.view.bounds;
  CGRect tokenFieldFrame = CGRectMake(0, 0, CGRectGetWidth(viewBounds), 44.0);
  
  self.tokenField = [[COTokenField alloc] initWithFrame:tokenFieldFrame];
  self.tokenField.tokenFieldDelegate = self;
  self.tokenField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
  [self.tokenField addObserver:self forKeyPath:kTokenFieldFrameKeyPath options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
  
  // Configure search table
  self.searchTableView = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                       CGRectGetMaxY(self.tokenField.bounds),
                                                                       CGRectGetWidth(viewBounds),
                                                                       CGRectGetHeight(viewBounds) - CGRectGetHeight(tokenFieldFrame))
                                                      style:UITableViewStylePlain];
  self.searchTableView.opaque = NO;
  self.searchTableView.backgroundColor = [UIColor whiteColor];
  self.searchTableView.dataSource = self;
  self.searchTableView.delegate = self;
  self.searchTableView.hidden = YES;
  self.searchTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
  
  // Create the scroll view
  self.tokenFieldScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(viewBounds), self.tokenField.computedRowHeight)];
  self.tokenFieldScrollView.backgroundColor = [UIColor whiteColor];
  
  [self.view addSubview:self.searchTableView];
  [self.view addSubview:self.tokenFieldScrollView];
  [self.tokenFieldScrollView addSubview:self.tokenField];
  
  // Shadow layer
  self.shadowLayer = [CAGradientLayer layer];
  self.shadowLayer.frame = CGRectMake(0, CGRectGetMaxY(self.tokenFieldScrollView.frame), CGRectGetWidth(self.view.bounds), kTokenFieldShadowHeight);
  self.shadowLayer.colors = [NSArray arrayWithObjects:
                             (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.3].CGColor,
                             (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.3].CGColor,
                             (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.1].CGColor,
                             (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor, nil];
  self.shadowLayer.locations = [NSArray arrayWithObjects:
                                [NSNumber numberWithDouble:0.0],
                                [NSNumber numberWithDouble:1.0/kTokenFieldShadowHeight],
                                [NSNumber numberWithDouble:1.0/kTokenFieldShadowHeight],
                                [NSNumber numberWithDouble:1.0], nil];
  
  [self.view.layer addSublayer:self.shadowLayer];
  
  // Subscribe to keyboard notifications
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
}

- (void)layoutTokenFieldAndSearchTable {
  CGRect bounds = self.view.bounds;
  CGRect tokenFieldBounds = self.tokenField.bounds;
  CGRect tokenScrollBounds = tokenFieldBounds;
  
  self.tokenFieldScrollView.contentSize = tokenFieldBounds.size;
  
  CGFloat maxHeight = [self.tokenField heightForNumberOfRows:5];
  if (!self.searchTableView.hidden) {
    tokenScrollBounds = CGRectMake(0, 0, CGRectGetWidth(bounds), [self.tokenField heightForNumberOfRows:1]);
  }
  else if (CGRectGetHeight(tokenScrollBounds) > maxHeight) {
    tokenScrollBounds = CGRectMake(0, 0, CGRectGetWidth(bounds), maxHeight);  
  }
  [UIView animateWithDuration:0.25 animations:^{
    self.tokenFieldScrollView.frame = tokenScrollBounds;
  }];
  
  if (!CGRectIsNull(keyboardFrame_)) {
    CGRect keyboardFrame = [self.view convertRect:keyboardFrame_ fromView:nil];
    CGRect tableFrame = CGRectMake(0,
                                   CGRectGetMaxY(self.tokenFieldScrollView.frame),
                                   CGRectGetWidth(bounds),
                                   CGRectGetMinY(keyboardFrame) - CGRectGetMaxY(self.tokenFieldScrollView.frame));
    [UIView animateWithDuration:0.25 animations:^{
      self.searchTableView.frame = tableFrame;
    }];
  }
  
  self.shadowLayer.frame = CGRectMake(0, CGRectGetMaxY(self.tokenFieldScrollView.frame), CGRectGetWidth(bounds), kTokenFieldShadowHeight);
  
  CGFloat contentOffset = MAX(0, CGRectGetHeight(tokenFieldBounds) - CGRectGetHeight(self.tokenFieldScrollView.bounds));
  [self.tokenFieldScrollView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:kTokenFieldFrameKeyPath]) {
    [self layoutTokenFieldAndSearchTable];
  }
}

- (void)viewDidUnload {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.tokenField removeObserver:self forKeyPath:kTokenFieldFrameKeyPath];
}

- (void)keyboardDidShow:(NSNotification *)note {
  keyboardFrame_ = [[[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  [self layoutTokenFieldAndSearchTable];
}

#pragma mark - COTokenFieldDelegate 

- (void)tokenFieldDidPressAddContactButton:(COTokenField *)tokenField {
  ABPeoplePickerNavigationController *picker = [ABPeoplePickerNavigationController new];
  picker.addressBook = addressBook_;
  picker.peoplePickerDelegate = self;
  picker.displayedProperties = self.displayedProperties;  
  [self presentModalViewController:picker animated:YES];
}

- (ABAddressBookRef)addressBookForTokenField:(COTokenField *)tokenField {
  return addressBook_;
}

static NSString *kCORecordFullName = @"fullName";
static NSString *kCORecordEmailLabel = @"emailLabel";
static NSString *kCORecordEmailAddress = @"emailAddress";

- (void)tokenField:(COTokenField *)tokenField updateAddressBookSearchResults:(NSArray *)records {
//  NSLog(@"matches:");
//  for (CORecord *record in records) {
//    NSLog(@"\t%@:", record.fullName);
//    for (CORecordEmail *email in record.emailAddresses) {
//      NSLog(@"\t\t-> %@: %@", email.label, email.address);
//    }
//  }
  
  // Split the search results into one email value per row
  NSMutableArray *results = [NSMutableArray new];
#if TARGET_IPHONE_SIMULATOR
  for (int i=0; i<4; i++) {
    NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSString stringWithFormat:@"Name %i", i], kCORecordFullName,
                           [NSString stringWithFormat:@"label%i", i], kCORecordEmailLabel,
                           [NSString stringWithFormat:@"fake%i@address.com", i], kCORecordEmailAddress,
                           nil];
    [results addObject:entry];
  }
#else
  for (CORecord *record in records) {
    for (CORecordEmail *email in record.emailAddresses) {
      NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                             [record.fullName length] != 0 ? record.fullName : email.address, kCORecordFullName,
                             email.label, kCORecordEmailLabel,
                             email.address, kCORecordEmailAddress,
                             nil];
      if (![results containsObject:entry]) {
        [results addObject:entry];
      }
    }
  }
#endif
  self.discreteSearchResults = [NSArray arrayWithArray:results];
  
  // Update the table
  [self.searchTableView reloadData];
  if (self.discreteSearchResults.count > 0) {
    self.searchTableView.hidden = NO;  
  }
  else {
    self.searchTableView.hidden = YES;
  }
  [self layoutTokenFieldAndSearchTable];
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
  return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
  ABMutableMultiValueRef multi = ABRecordCopyValue(person, property);
  NSString *email = CFBridgingRelease(ABMultiValueCopyValueAtIndex(multi, identifier));
  CFRelease(multi);
  
  [self.tokenField processToken:email];
  [self dismissModalViewControllerAnimated:YES];
  
  return NO;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.discreteSearchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSDictionary *result = [self.discreteSearchResults objectAtIndex:indexPath.row];
  
  static NSString *ridf = @"resultCell";
  COEmailTableCell *cell = [tableView dequeueReusableCellWithIdentifier:ridf];
  if (cell == nil) {
    cell = [[COEmailTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ridf];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  cell.nameLabel.text = [result objectForKey:kCORecordFullName];
  cell.emailLabelLabel.text = [result objectForKey:kCORecordEmailLabel];
  cell.emailAddressLabel.text = [result objectForKey:kCORecordEmailAddress];
  
  [cell adjustLabels];
  
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  COEmailTableCell *cell = (id)[tableView cellForRowAtIndexPath:indexPath];
  [self.tokenField processToken:cell.emailAddressLabel.text];
}

@end

#pragma mark - COTokenField Implementation

@implementation COTokenField
@synthesize tokenFieldDelegate = tokenFieldDelegate_;
@synthesize textField = textField_;
@synthesize addContactButton = addContactButton_;
@synthesize tokens = tokens_;
@synthesize selectedToken = selectedToken_;

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

- (void)modifyToken:(COToken *)token {
  if (token != nil) {
    if (token == self.selectedToken) {
      [token removeFromSuperview];
      [self.tokens removeObject:token];
      self.textField.hidden = NO;
      self.selectedToken = nil;
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

- (void)processToken:(NSString *)tokenText {
  COToken *token = [COToken tokenWithTitle:tokenText associatedObject:tokenText container:self];
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
        CORecord *record = [CORecord new];
        record->record_ = CFRetain(recordRef);
        [records addObject:record];
      }
      lastUpdated = [NSDate date];
    }
    
    NSIndexSet *resultSet = [records indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
      CORecord *record = (CORecord *)obj;
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
    [self processToken:[text substringFromIndex:1]];
  }
  return YES;
}

@end

#pragma mark - COToken

@implementation COToken
@synthesize title = title_;
@synthesize associatedObject = associatedObject_;
@synthesize container = container_;

+ (COToken *)tokenWithTitle:(NSString *)title associatedObject:(id)obj container:(COTokenField *)container {
  COToken *token = [self buttonWithType:UIButtonTypeCustom];
  token.associatedObject = obj;
  token.container = container;
  token.backgroundColor = [UIColor clearColor];
  
  UIFont *font = [UIFont systemFontOfSize:kTokenFieldFontSize];
  CGSize tokenSize = [title sizeWithFont:font];
  tokenSize.width = MIN(kTokenFieldMaxTokenWidth, tokenSize.width);
  tokenSize.width += kTokenFieldPaddingX * 2.0;
  
  tokenSize.height = MIN(kTokenFieldFontSize, tokenSize.height);
  tokenSize.height += kTokenFieldPaddingY * 2.0;
  
  token.frame = (CGRect){CGPointZero, tokenSize};
  token.titleLabel.font = font;
  token.title = title;
  
  return token;
}

- (void)drawRect:(CGRect)rect {
  CGFloat radius = CGRectGetHeight(self.bounds) / 2.0;
  
  UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:radius];
  
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextSaveGState(ctx);
  CGContextAddPath(ctx, path.CGPath);
  CGContextClip(ctx);
  
  NSArray *colors = nil;
  if (self.highlighted) {
    colors = [NSArray arrayWithObjects:
              (__bridge id)[UIColor colorWithRed:0.322 green:0.541 blue:0.976 alpha:1.0].CGColor,
              (__bridge id)[UIColor colorWithRed:0.235 green:0.329 blue:0.973 alpha:1.0].CGColor,
              nil];
  }
  else {
    colors = [NSArray arrayWithObjects:
              (__bridge id)[UIColor colorWithRed:0.863 green:0.902 blue:0.969 alpha:1.0].CGColor,
              (__bridge id)[UIColor colorWithRed:0.741 green:0.808 blue:0.937 alpha:1.0].CGColor,
              nil];
  }
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFTypeRef)colors, NULL);
  CGColorSpaceRelease(colorSpace);
  
  CGContextDrawLinearGradient(ctx, gradient, CGPointZero, CGPointMake(0, CGRectGetHeight(self.bounds)), 0);
  CGGradientRelease(gradient);
  CGContextRestoreGState(ctx);
  
  if (self.highlighted) {
    [[UIColor colorWithRed:0.275 green:0.478 blue:0.871 alpha:1.0] set];
  }
  else {
    [[UIColor colorWithRed:0.667 green:0.757 blue:0.914 alpha:1.0] set];
  }
  
  path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.5, 0.5) cornerRadius:radius];
  [path setLineWidth:1.0];
  [path stroke];
  
  if (self.highlighted) {
    [[UIColor whiteColor] set];
  }
  else {
    [[UIColor blackColor] set];
  }
  
  UIFont *titleFont = [UIFont systemFontOfSize:kTokenFieldFontSize];
  CGSize titleSize = [self.title sizeWithFont:titleFont];
  CGRect titleFrame = CGRectMake((CGRectGetWidth(self.bounds) - titleSize.width) / 2.0,
                                 (CGRectGetHeight(self.bounds) - titleSize.height) / 2.0,
                                 titleSize.width,
                                 titleSize.height);
  
  [self.title drawInRect:titleFrame withFont:titleFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentCenter];
}

@end

#pragma mark - CORecord

@implementation CORecord

- (void)dealloc {
  if (record_) {
    CFRelease(record_);
    record_ = NULL;
  }
}

- (NSString *)fullName {
  return CFBridgingRelease(ABRecordCopyCompositeName(record_));
}

- (NSString *)namePrefix {
  return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonPrefixProperty));
}

- (NSString *)firstName {
  return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonFirstNameProperty));
}

- (NSString *)middleName {
  return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonMiddleNameProperty));
}

- (NSString *)lastName {
  return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonLastNameProperty));
}

- (NSString *)nameSuffix {
  return CFBridgingRelease(ABRecordCopyValue(record_, kABPersonSuffixProperty));
}

- (NSArray *)emailAddresses {
  NSMutableArray *addresses = [NSMutableArray new];
  ABMultiValueRef multi = ABRecordCopyValue(record_, kABPersonEmailProperty);
  CFIndex multiCount = ABMultiValueGetCount(multi);
  for (CFIndex i=0; i<multiCount; i++) {
    CORecordEmail *email = [CORecordEmail new];
    email->emails_ = CFRetain(multi);
    email->identifier_ = ABMultiValueGetIdentifierAtIndex(multi, i);
    [addresses addObject:email];
  }
  CFRelease(multi);
  return [NSArray arrayWithArray:addresses];
}

@end

@implementation CORecordEmail

- (void)dealloc {
  if (emails_ != NULL) {
    CFRelease(emails_);
    emails_ = NULL;
  }
}

- (NSString *)label {
  CFStringRef label = ABMultiValueCopyLabelAtIndex(emails_, ABMultiValueGetIndexForIdentifier(emails_, identifier_));
  if (label != NULL) {
    CFStringRef localizedLabel = ABAddressBookCopyLocalizedLabel(label);
    CFRelease(label);
    return CFBridgingRelease(localizedLabel);
  }
  return @"email";
}

- (NSString *)address {
  return CFBridgingRelease(ABMultiValueCopyValueAtIndex(emails_, ABMultiValueGetIndexForIdentifier(emails_, identifier_)));
}

@end

#pragma mark - COEmailTableCell

@implementation COEmailTableCell
@synthesize nameLabel = nameLabel_;
@synthesize emailLabelLabel = emailLabelLabel_;
@synthesize emailAddressLabel = emailAddressLabel_;

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
