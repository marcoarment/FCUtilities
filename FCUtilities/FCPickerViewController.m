//
//  FCPickerViewController.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCPickerViewController.h"

#define kCellReuseIdentifier @"FCPickerCell"

@interface FCPickerViewController () {
    NSUInteger _currentSelection;
}
@property (nonatomic) NSArray *items;
@property (nonatomic, copy) NSString *(^itemLabelBlock)(id item);
@property (nonatomic, copy) void (^pickedBlock)(NSUInteger idx);
@end

@implementation FCPickerViewController

- (instancetype)initWithTitle:(NSString *)title items:(NSArray *)items itemLabelBlock:(NSString *(^)(id item))itemLabelBlock pickedBlock:(void (^)(NSUInteger idx))pickedBlock currentSelection:(NSUInteger)currentSelection
{
    if ( (self = [super initWithStyle:UITableViewStyleGrouped]) ) {
        self.title = title;
        self.items = items;
        self.itemLabelBlock = itemLabelBlock;
        self.pickedBlock = pickedBlock;
        _currentSelection = currentSelection;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kCellReuseIdentifier];
    [self configureTableView:self.tableView withCellReuseIdentifier:kCellReuseIdentifier];
}

// For subclass overriding
- (void)configureTableView:(UITableView *)tableView withCellReuseIdentifier:(NSString *)cellReuseIdentifier
{
}

// For subclass overriding
- (void)configureCell:(UITableViewCell *)cell withItem:(id)item
{
    cell.textLabel.text = self.itemLabelBlock ? self.itemLabelBlock(item) : ([item isKindOfClass:NSString.class] ? (NSString *) item : [item description]);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.items.count; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    [self configureCell:cell withItem:self.items[indexPath.row]];
    
    if (indexPath.row == _currentSelection) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == _currentSelection) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:_currentSelection inSection:0]].accessoryType = UITableViewCellAccessoryNone;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        self.pickedBlock(indexPath.row);
        [self.navigationController popViewControllerAnimated:YES];
    });
}

@end
