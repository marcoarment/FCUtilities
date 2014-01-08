//
//  FCPickerViewController.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <UIKit/UIKit.h>

@interface FCPickerViewController : UITableViewController

- (instancetype)initWithTitle:(NSString *)title items:(NSArray *)items itemLabelBlock:(NSString *(^)(id item))itemLabelBlock pickedBlock:(void (^)(NSUInteger idx))pickedBlock currentSelection:(NSUInteger)currentSelection;

// Subclasses may override these to e.g. customize appearance or register a different cell class
- (void)configureTableView:(UITableView *)tableView withCellReuseIdentifier:(NSString *)cellReuseIdentifier;
- (void)configureCell:(UITableViewCell *)cell withItem:(id)item;

@end
