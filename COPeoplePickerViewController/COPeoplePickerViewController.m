//
//  COPeoplePickerViewController.m
//  COPeoplePickerViewController
//
//  Created by Erik Aigner on 08.10.11.
//  Copyright (c) 2011 chocomoko.com. All rights reserved.
//

#import "COPeoplePickerViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <AddressBookUI/AddressBookUI.h>
#import <objc/runtime.h>

#import "COTokenField.h"
#import "COToken.h"
#import "CORecord.h"
#import "COPerson.h"
#import "COEmailTableCell.h"
#import "CORecordEmail.h"

#import "UIDevice+We7.h"
#import "UIFont+Blinkbox.h"
#import "UIColor+Blinkbox.h"

#define kTokenFieldFrameKeyPath @"frame"

NSString *const COPeoplePickerViewControllerVisibleHeightChanged =
@"COPeoplePickerViewControllerVisibleHeightChanged";

@interface COPeoplePickerViewController ()
<UITableViewDelegate,
UITableViewDataSource,
COTokenFieldDelegate,
ABPeoplePickerNavigationControllerDelegate> {
    
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

@synthesize delegate = _delegate;
@synthesize tokenField = _tokenField;
@synthesize tokenFieldScrollView = _tokenFieldScrollView;
@synthesize searchTableView = _searchTableView;
@synthesize displayedProperties = _displayedProperties;
@synthesize discreteSearchResults = _discreteSearchResults;
@synthesize shadowLayer = _shadowLayer;

- (void)initialiseAddressBook
{
    keyboardFrame_ = CGRectNull;

    if (ABAddressBookCreateWithOptions != NULL) {
        
        CFErrorRef error = NULL;
        addressBook_ = ABAddressBookCreateWithOptions(NULL, &error);
        if (error != NULL) {
            [[[UIAlertView alloc] initWithTitle:@"Oups!"
                                        message:NSLocalizedString(@"Cannot access the address book. Please allow the app to access your contact book to easily pick your contacts.", nil)
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        } else {
            ABAddressBookRequestAccessWithCompletion(addressBook_, nil);
        }
        
    } else { // remove this case when requiring iOS 6
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
        addressBook_ = ABAddressBookCreate();
#endif
        
        if (addressBook_ == NULL) {
            [[[UIAlertView alloc] initWithTitle:@"Oups!"
                                        message:NSLocalizedString(@"Cannot access the address book. Please allow the app to access your contact book to easily pick your contacts.", nil)
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
        
    }

}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.tokenField removeObserver:self forKeyPath:kTokenFieldFrameKeyPath];
    
    if (addressBook_ != NULL) {
        CFRelease(addressBook_);
        addressBook_ = NULL;
    }
}

- (ABAddressBookRef)addressBookRef
{
    return addressBook_;
}

- (void)done:(id)sender
{
#pragma unused (sender)
    id<COPeoplePickerViewControllerDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(peoplePickerViewControllerDidFinishPicking:)]) {
        [delegate peoplePickerViewControllerDidFinishPicking:self];
    }
}

- (void)loadView
{
    [super loadView];
    
    UIBarButtonItem *rightItem =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                     style:UIBarButtonItemStyleDone
                                    target:self
                                    action:@selector(done:)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)viewDidLoad
{
    [self initialiseAddressBook];
    
    // Configure content view
    self.view.backgroundColor = [UIColor colorWithRed:0.859
                                                green:0.886
                                                 blue:0.925
                                                alpha:1.0];
    
    // Configure token field
    CGRect viewBounds = self.view.bounds;
    CGRect tokenFieldFrame = CGRectMake(0, 0, CGRectGetWidth(viewBounds), 44.0);
    
    self.tokenField = [[COTokenField alloc] initWithFrame:tokenFieldFrame];
    self.tokenField.tokenFieldDelegate = self;
    self.tokenField.autoresizingMask =
    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    
    // Configure search table
    self.searchTableView =
    [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                  CGRectGetMaxY(self.tokenField.bounds),
                                                  CGRectGetWidth(viewBounds),
                                                  CGRectGetHeight(viewBounds) - CGRectGetHeight(tokenFieldFrame))
                                 style:UITableViewStylePlain];
    
    self.searchTableView.opaque = NO;
    self.searchTableView.backgroundColor = [UIColor whiteColor];
    self.searchTableView.dataSource = self;
    self.searchTableView.delegate = self;
    self.searchTableView.hidden = YES;
    self.searchTableView.autoresizingMask =
    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    // Create the scroll view
    self.tokenFieldScrollView =
    [[UIScrollView alloc] initWithFrame:CGRectMake(0,
                                                   0,
                                                   CGRectGetWidth(viewBounds),
                                                   self.tokenField.computedRowHeight)];
    self.tokenFieldScrollView.backgroundColor = [UIColor whiteColor];
    self.tokenFieldScrollView.autoresizingMask =
    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    
    [self.view addSubview:self.searchTableView];
    [self.view addSubview:self.tokenFieldScrollView];
    [self.tokenFieldScrollView addSubview:self.tokenField];
    
    // Shadow layer
    self.shadowLayer = [CAGradientLayer layer];
    self.shadowLayer.frame = CGRectMake(0,
                                        CGRectGetMaxY(self.tokenFieldScrollView.frame),
                                        CGRectGetWidth(self.view.bounds),
                                        kTokenFieldShadowHeight);
    
    self.shadowLayer.colors = @[(__bridge id)[UIColor colorWithWhite:0.0 alpha:0.3].CGColor,
                                (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.3].CGColor,
                                (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.1].CGColor,
                                (__bridge id)[UIColor colorWithWhite:0.0 alpha:0.0].CGColor];
    
    self.shadowLayer.locations = @[@0.0,
                                   @(1.0/kTokenFieldShadowHeight),
                                   @(1.0/kTokenFieldShadowHeight),
                                   @1.0];
    
    [self.view.layer addSublayer:self.shadowLayer];
    
    [self.tokenField addObserver:self
                      forKeyPath:kTokenFieldFrameKeyPath
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:nil];
    
    // Subscribe to keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
}

- (void)setHint:(NSString *)hint
{
    UILabel *hintLabel = self.tokenField.hintLabel;
    hintLabel.text = hint;
    hintLabel.font = [UIFont blinkboxBookFontOfSize:15];
    hintLabel.textColor = [UIColor blinkboxDarkGrey];
    [hintLabel sizeToFit];
    
    CGRect frame = hintLabel.frame;
    frame.origin = CGPointMake(kTokenFieldPaddingX, kTokenFieldPaddingY);
    frame.size.height = self.tokenField.textField.frame.size.height - 1;
    frame.size.width += 5;
    hintLabel.frame = frame;
    [self.tokenField layoutSubviews];
}

- (NSString *)hint
{
    return self.tokenField.hintLabel.text;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tokenField.textField becomeFirstResponder];
    if ([UIDevice isRunningiOS7OrAbove]) {
        self.tokenField.textField.tintColor = [UIColor blinkboxDarkGrey];
        self.tokenField.textField.font = [UIFont blinkboxBookFontOfSize:15];
        self.tokenField.textField.textColor = [UIColor blinkboxDarkGrey];
    }
}

- (void)layoutTokenFieldAndSearchTable
{
    CGRect bounds = self.view.bounds;
    CGRect tokenFieldBounds = self.tokenField.bounds;
    CGRect tokenScrollBounds = tokenFieldBounds;
    
    self.tokenFieldScrollView.contentSize = tokenFieldBounds.size;
    
    CGFloat maxHeight = [self.tokenField heightForNumberOfRows:5];
    if (!self.searchTableView.hidden) {
        tokenScrollBounds = CGRectMake(0, 0,
                                       CGRectGetWidth(bounds),
                                       [self.tokenField heightForNumberOfRows:1]);
    }
    else if (CGRectGetHeight(tokenScrollBounds) > maxHeight) {
        tokenScrollBounds = CGRectMake(0, 0,
                                       CGRectGetWidth(bounds), maxHeight);
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
        self.searchTableView.frame = tableFrame;
    }
    
    self.shadowLayer.frame = CGRectMake(0, CGRectGetMaxY(self.tokenFieldScrollView.frame), CGRectGetWidth(bounds), kTokenFieldShadowHeight);
    
    CGFloat contentOffset = MAX(0, CGRectGetHeight(tokenFieldBounds) - CGRectGetHeight(self.tokenFieldScrollView.bounds));
    [self.tokenFieldScrollView setContentOffset:CGPointMake(0, contentOffset) animated:YES];
    
    CGFloat height = [self visibleHeight];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:COPeoplePickerViewControllerVisibleHeightChanged
     object:self
     userInfo:@{@"height" : @(height)}];
}

- (CGFloat)visibleHeight
{
    CGFloat height = self.tokenField.frame.size.height;
    
    if (!self.searchTableView.hidden) {
        height += self.searchTableView.frame.size.height;
    }
    
    return height;
}

- (void)hideSearchTableView:(BOOL)hidden
{
    self.searchTableView.hidden = hidden;
    
    CGFloat height = [self visibleHeight];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:COPeoplePickerViewControllerVisibleHeightChanged
     object:self
     userInfo:@{@"height" : @(height)}];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
#pragma unused (object, change, context)
    if ([keyPath isEqualToString:kTokenFieldFrameKeyPath]) {
        [self layoutTokenFieldAndSearchTable];
    }
}

- (NSArray *)selectedRecords
{
    NSMutableArray *map = [NSMutableArray new];
    for (COToken *token in self.tokenField.tokens) {
        CORecord *record = [CORecord new];
        record.title = token.title;
        record.person = token.associatedObject;
        [map addObject:record];
    }
    return [NSArray arrayWithArray:map];
}

- (void)resetTokenFieldWithRecords:(NSArray *)records
{
    [self.tokenField removeAllTokens];
    for (CORecord *record in records) {
        [self.tokenField processToken:record.title associatedRecord:record.person];
    }
}

- (void)keyboardDidShow:(NSNotification *)note
{
    keyboardFrame_ = [[note userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self layoutTokenFieldAndSearchTable];
}

#pragma mark - COTokenFieldDelegate

- (void)tokenFieldDidPressAddContactButton:(COTokenField *)tokenField
{
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
    
    [self presentViewController:picker
                       animated:YES
                     completion:nil];
}

- (ABAddressBookRef)addressBookForTokenField:(COTokenField *)tokenField
{
#pragma unused (tokenField)
    return self.addressBookRef;
}

static NSString *kCORecordFullName = @"fullName";
static NSString *kCORecordEmailLabel = @"emailLabel";
static NSString *kCORecordEmailAddress = @"emailAddress";
static NSString *kCORecordRef = @"record";

- (void)tokenField:(COTokenField *)tokenField updateAddressBookSearchResults:(NSArray *)records
{
#pragma unused (tokenField, records)
    // Split the search results into one email value per row
    NSMutableArray *results = [NSMutableArray new];
#if TARGET_IPHONE_SIMULATOR
    for (int i=0; i<4; i++) {
        NSDictionary *entry = @{kCORecordFullName: [NSString stringWithFormat:@"Name %i", i],
                               kCORecordEmailLabel: [NSString stringWithFormat:@"label%i", i],
                               kCORecordEmailAddress: [NSString stringWithFormat:@"fake%i@address.com", i]};
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
    [self layoutTokenFieldAndSearchTable];
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
#pragma unused (peoplePicker, person)
    return YES;
}

- (void)tokenField:(COTokenField *)tokenField searchingModeChanged:(BOOL)isInSearchingMode
{
#pragma unused (tokenField)
    self.searchTableView.hidden = !isInSearchingMode;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
#pragma unused (peoplePicker)
    ABMutableMultiValueRef multi = ABRecordCopyValue(person, property);
    NSString *email = CFBridgingRelease(ABMultiValueCopyValueAtIndex(multi, identifier));
    CFRelease(multi);
    
    COPerson *record = [[COPerson alloc] initWithABRecordRef:person];
    
    [self.tokenField processToken:email associatedRecord:record];
    [self dismissViewControllerAnimated:YES
                             completion:nil];
    return NO;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
#pragma unused (peoplePicker)
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#pragma unused (tableView, section)
    return (NSInteger)self.discreteSearchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *result = (self.discreteSearchResults)[(NSUInteger)indexPath.row];
    
    static NSString *ridf = @"resultCell";
    COEmailTableCell *cell = [tableView dequeueReusableCellWithIdentifier:ridf];
    if (cell == nil) {
        cell = [[COEmailTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ridf];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.nameLabel.text = result[kCORecordFullName];
    cell.emailLabelLabel.text = result[kCORecordEmailLabel];
    cell.emailAddressLabel.text = result[kCORecordEmailAddress];
    cell.associatedRecord = result[kCORecordRef];
    
    [cell adjustLabels];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    COEmailTableCell *cell = (id)[tableView cellForRowAtIndexPath:indexPath];
    [self.tokenField processToken:cell.emailAddressLabel.text associatedRecord:cell.associatedRecord];
    [self hideSearchTableView:YES];
}

@end


