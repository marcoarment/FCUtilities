//
//  FCPickerViewController.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCPickerViewController.h"


@interface FCPickerViewSectionBreak ()
@property (nonatomic, copy) NSString *title;
@end
@implementation FCPickerViewSectionBreak
- (instancetype)initWithSectionTitle:(NSString *)title
{
    if ( (self = [super init]) ) {
        self.title = title;
    }
    return self;
}
@end


#define kCellReuseIdentifier @"FCPickerCell"

@interface FCPickerViewController () {
    NSUInteger _currentSelection;
    NSArray<NSArray *> *itemsBySection;
    NSArray *allItems;
    NSArray *sectionTitles;
    NSIndexPath *indexPathOfSelectedCell;
}
@property (nonatomic, copy) NSString *(^itemLabelBlock)(id item);
@property (nonatomic, copy) void (^pickedBlock)(NSUInteger idx);
@end

@implementation FCPickerViewController

- (instancetype)initWithTitle:(NSString *)title items:(NSArray *)items itemLabelBlock:(NSString *(^)(id item))itemLabelBlock pickedBlock:(void (^)(NSUInteger idx))pickedBlock currentSelection:(NSUInteger)currentSelection
{
    if ( (self = [super initWithStyle:UITableViewStyleInsetGrouped]) ) {
    
        NSMutableArray *filteredItems = [NSMutableArray array];
        NSMutableArray *sections = [NSMutableArray array];
        NSMutableArray *currentSection = [NSMutableArray array];
        NSMutableArray *titlesBySection = [NSMutableArray arrayWithObject:@""];
        [sections addObject:currentSection];
        for (id item in items) {
            if ([item isKindOfClass:FCPickerViewSectionBreak.class]) {
                currentSection = [NSMutableArray array];
                [sections addObject:currentSection];
                [titlesBySection addObject:((FCPickerViewSectionBreak *) item).title ?: @""];
            } else {
                [filteredItems addObject:item];
                [currentSection addObject:item];
            }
        }
        allItems = [filteredItems copy];
        itemsBySection = [sections copy];
        sectionTitles = [titlesBySection copy];

        self.title = title;
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

// For subclass overriding
- (UIView *)viewForSectionHeaderWithTitle:(NSString *)title width:(CGFloat)width
{
    return nil;
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self tableView:tableView viewForHeaderInSection:section].bounds.size.height ?: 36.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *titleStr = sectionTitles[section];
    if (! titleStr.length) return nil;
    
    CGFloat tableWidth = tableView.bounds.size.width;
    if (tableView.style == UITableViewStyleInsetGrouped) tableWidth -= 40.0f;
    
    return [self viewForSectionHeaderWithTitle:sectionTitles[section] width:tableWidth];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return itemsBySection.count; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return itemsBySection[section].count; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    id item = itemsBySection[indexPath.section][indexPath.row];
    [self configureCell:cell withItem:item];
    
    if ([allItems indexOfObject:item] == _currentSelection) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        indexPathOfSelectedCell = [indexPath copy];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath isEqual:indexPathOfSelectedCell]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    [tableView cellForRowAtIndexPath:indexPathOfSelectedCell].accessoryType = UITableViewCellAccessoryNone;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    indexPathOfSelectedCell = indexPath;
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        self.pickedBlock([allItems indexOfObject:itemsBySection[indexPath.section][indexPath.row]]);
        [self.navigationController popViewControllerAnimated:YES];
    });
}

@end
