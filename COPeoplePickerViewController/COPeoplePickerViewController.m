//
//  COPeoplePickerViewController.m
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Copyright (c) 2011 chocomoko.com. All rights reserved.
//

#import "COPeoplePickerViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#define COSynth(x) @synthesize x = x##_;

// =============================================================================

@class COTokenField;

@interface COToken : UIButton
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) id associatedObject;
@property (nonatomic, strong) COTokenField *container;

+ (COToken *)tokenWithTitle:(NSString *)title associatedObject:(id)obj container:(COTokenField *)container;

@end

// =============================================================================

@interface COEmailTableCell : UITableViewCell
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *emailLabelLabel;
@property (nonatomic, strong) UILabel *emailAddressLabel;
@property (nonatomic, strong) COPerson *associatedRecord;

- (void)adjustLabels;

@end

// =============================================================================

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
- (void)removeAllTokens;
- (void)removeToken:(COToken *)token;
- (void)modifyToken:(COToken *)token;
- (void)modifySelectedToken;
- (void)processToken:(NSString *)tokenText associatedRecord:(COPerson *)record;
- (void)tokenInputChanged:(id)sender;

@end

// =============================================================================

@interface CORecord ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) COPerson *person;
@end

@implementation CORecord
COSynth(title)
COSynth(person)

- (id)initWithTitle:(NSString *)title person:(COPerson *)person {
  self = [super init];
  if (self) {
    self.title = title;
    self.person = person;
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ title: '%@'; person: '%@'>",
          NSStringFromClass(isa), self.title, self.person];
}

@end

@interface CORecordEmail : NSObject {
@private
  ABMultiValueRef         emails_;
  ABMultiValueIdentifier  identifier_;
}
@property (nonatomic, readonly) NSString *label;
@property (nonatomic, readonly) NSString *address;

- (id)initWithEmails:(ABMultiValueRef)emails identifier:(ABMultiValueIdentifier)identifier;

@end

// =============================================================================

@interface COPeoplePickerViewController () <UITableViewDelegate, UITableViewDataSource, COTokenFieldDelegate, ABPeoplePickerNavigationControllerDelegate> {
@private
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
COSynth(delegate)
COSynth(tokenField)
COSynth(tokenFieldScrollView)
COSynth(searchTableView)
COSynth(displayedProperties)
COSynth(discreteSearchResults)
COSynth(shadowLayer)

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

- (ABAddressBookRef)addressBookRef {
  return addressBook_;
}

- (void)done:(id)sender {
#pragma unused (sender)
  if ([self.delegate respondsToSelector:@selector(peoplePickerViewControllerDidFinishPicking:)]) {
    [self.delegate peoplePickerViewControllerDidFinishPicking:self];
  }
}

- (void)loadView {
  [super loadView];
  UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                                                style:UIBarButtonItemStyleDone
                                                               target:self
                                                               action:@selector(done:)];
  self.navigationItem.rightBarButtonItem = rightItem;
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

- (void)viewWillAppear:(BOOL)animated {
#pragma unused (animated)
  [self.tokenField.textField becomeFirstResponder];
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
#pragma unused (object, change, context)
  if ([keyPath isEqualToString:kTokenFieldFrameKeyPath]) {
    [self layoutTokenFieldAndSearchTable];
  }
}

- (void)viewDidUnload {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.tokenField removeObserver:self forKeyPath:kTokenFieldFrameKeyPath];
}

- (NSArray *)selectedRecords {
  NSMutableArray *map = [NSMutableArray new];
  for (COToken *token in self.tokenField.tokens) {
    CORecord *record = [CORecord new];
    record.title = token.title;
    record.person = token.associatedObject;
    [map addObject:record];
  }
  return [NSArray arrayWithArray:map];
}

- (void)resetTokenFieldWithRecords:(NSArray *)records {
  [self.tokenField removeAllTokens];
  for (CORecord *record in records) {
    [self.tokenField processToken:record.title associatedRecord:record.person];
  }
}

- (void)keyboardDidShow:(NSNotification *)note {
  keyboardFrame_ = [[[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  [self layoutTokenFieldAndSearchTable];
}

#pragma mark - COTokenFieldDelegate 

- (void)tokenFieldDidPressAddContactButton:(COTokenField *)tokenField {
#pragma unused (tokenField)
  ABPeoplePickerNavigationController *picker = [ABPeoplePickerNavigationController new];
  picker.addressBook = self.addressBookRef;
  picker.peoplePickerDelegate = self;
  picker.displayedProperties = self.displayedProperties;
  
  // Set same tint color on picker navigation bar
  UIColor *tintColor = self.navigationController.navigationBar.tintColor;
  if (tintColor != nil) {
    picker.navigationBar.tintColor = tintColor;
  }
  
  [self presentModalViewController:picker animated:YES];
}

- (ABAddressBookRef)addressBookForTokenField:(COTokenField *)tokenField {
#pragma unused (tokenField)
  return self.addressBookRef;
}

static NSString *kCORecordFullName = @"fullName";
static NSString *kCORecordEmailLabel = @"emailLabel";
static NSString *kCORecordEmailAddress = @"emailAddress";
static NSString *kCORecordRef = @"record";

- (void)tokenField:(COTokenField *)tokenField updateAddressBookSearchResults:(NSArray *)records {
#pragma unused (tokenField)
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
  for (COPerson *record in records) {
    for (CORecordEmail *email in record.emailAddresses) {
      NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                             [record.fullName length] != 0 ? record.fullName : email.address, kCORecordFullName,
                             email.label, kCORecordEmailLabel,
                             email.address, kCORecordEmailAddress,
                             record, kCORecordRef,
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
#pragma unused (peoplePicker, person)
  return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
#pragma unused (peoplePicker)
  ABMutableMultiValueRef multi = ABRecordCopyValue(person, property);
  NSString *email = CFBridgingRelease(ABMultiValueCopyValueAtIndex(multi, identifier));
  CFRelease(multi);
  
  COPerson *record = [[COPerson alloc] initWithABRecordRef:person];
  
  [self.tokenField processToken:email associatedRecord:record];
  [self dismissModalViewControllerAnimated:YES];
  
  return NO;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
#pragma unused (peoplePicker)
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#pragma unused (tableView, section)
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
  cell.associatedRecord = [result objectForKey:kCORecordRef];
  
  [cell adjustLabels];
  
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  COEmailTableCell *cell = (id)[tableView cellForRowAtIndexPath:indexPath];
  [self.tokenField processToken:cell.emailAddressLabel.text associatedRecord:cell.associatedRecord];
}

@end

// =============================================================================

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
#pragma unused (sender)
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
  [self.tokenFieldDelegate tokenField:self updateAddressBookSearchResults:matchedRecords];
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

// =============================================================================

@implementation COToken
COSynth(title)
COSynth(associatedObject)
COSynth(container)

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
#pragma unused (rect)
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

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ title: '%@'; associatedObj: '%@'>",
          NSStringFromClass(isa), self.title, self.associatedObject];
}

@end

// =============================================================================

@implementation COPerson {
@private
  ABRecordRef record_;
}

- (id)initWithABRecordRef:(ABRecordRef)record {
  self = [super init];
  if (self) {
    if (record != NULL) {
      record_ = CFRetain(record);
    }
  }
  return self;
}

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
  ABMultiValueRef emails = ABRecordCopyValue(record_, kABPersonEmailProperty);
  CFIndex multiCount = ABMultiValueGetCount(emails);
  for (CFIndex i=0; i<multiCount; i++) {
    CORecordEmail *email = [[CORecordEmail alloc] initWithEmails:emails
                                                      identifier:ABMultiValueGetIdentifierAtIndex(emails, i)];
    [addresses addObject:email];
  }
  CFRelease(emails);
  return [NSArray arrayWithArray:addresses];
}

- (ABRecordRef)record {
  return record_;
}

@end

// =============================================================================

@implementation CORecordEmail

- (id)initWithEmails:(ABMultiValueRef)emails identifier:(ABMultiValueIdentifier)identifier {
  self = [super init];
  if (self) {
    if (emails != NULL) {
      emails_ = CFRetain(emails);
    }
    identifier_ = identifier;
  }
  return self;
}

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

// =============================================================================

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
