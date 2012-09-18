//
//  COPeoplePickerViewController.m
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Improvements by Jordi Aragones on 18.09.12
//  Copyright (c) 2011-2012. All rights reserved.
//

#import "COPeoplePickerViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import "COEmailTableCellCell.h"
#import "COPerson.h"
#import "CORecord.h"
#import "CORecordEmail.h"
#import "CORecordPhone.h"

#import "COToken.h"
#import "COTokenField.h"

#import "Constants.h"

#import "COPeoplePickerViewControllerDelegate.h"

@implementation COPeoplePickerViewController
COSynth(delegate)
COSynth(tokenField)
COSynth(tokenFieldScrollView)
COSynth(searchTableView)
COSynth(displayedProperties)
COSynth(discreteSearchResults)
COSynth(shadowLayer)
COSynth(property)

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
  return self.addressBookRef;
}

static NSString *kCORecordFullName = @"fullName";
static NSString *kCORecordEmailLabel = @"emailLabel";
static NSString *kCORecordEmailAddress = @"emailAddress";
static NSString *kCORecordRef = @"record";

- (void)tokenField:(COTokenField *)tokenField updateAddressBookSearchResults:(NSArray *)records {
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
      if ([self.property isEqualToNumber:[NSNumber numberWithInt:kPropertyPhone]]) {
          for (CORecordPhone *phone in record.phoneNumbers) {
              NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
                             [record.fullName length] != 0 ? record.fullName : phone.number, kCORecordFullName,
                             phone.label, kCORecordEmailLabel,
                             phone.number, kCORecordEmailAddress,
                             record, kCORecordRef,
                             nil];
              if (![results containsObject:entry]) {
                  [results addObject:entry];
              }
          }
      } else {
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
  
  COPerson *record = [[COPerson alloc] initWithABRecordRef:person];

  [self.tokenField processToken:record.fullName associatedRecord:record];
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
  cell.associatedRecord = [result objectForKey:kCORecordRef];
  
  [cell adjustLabels];
  
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  COEmailTableCell *cell = (id)[tableView cellForRowAtIndexPath:indexPath];

  NSString *str = [[NSString alloc] initWithFormat:@"%@", cell.nameLabel.text];
      
  [self.tokenField processToken:str associatedRecord:cell.associatedRecord];
}

@end
