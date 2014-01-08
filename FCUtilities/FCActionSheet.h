//
//  FCActionSheet.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <UIKit/UIKit.h>

typedef void (^FCActionSheetBlock)(void);

@interface FCActionSheet : UIActionSheet <UIActionSheetDelegate>

- (instancetype)initWithTitle:(NSString *)title;
- (void)setDismissedAction:(FCActionSheetBlock)block;
- (void)addButtonWithTitle:(NSString *)title action:(FCActionSheetBlock)block;
- (void)addCancelButtonWithAction:(FCActionSheetBlock)block;
- (void)addCancelButtonWithTitle:(NSString *)title action:(FCActionSheetBlock)block;
- (void)addDestructiveButtonWithTitle:(NSString *)title action:(FCActionSheetBlock)block;

+ (void)dismissAll;

@end
