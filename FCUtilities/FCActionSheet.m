//
//  FCActionSheet.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCActionSheet.h"

#define FCActionSheetDefaultCancelButtonTitle   @"Cancel"

#define FCActionSheetDismissAllNotification     @"FCActionSheetDismissAllNotification"

@interface FCActionSheet ()
@property (nonatomic, copy) FCActionSheetBlock cancelButtonBlock;
@property (nonatomic, copy) FCActionSheetBlock destructiveButtonBlock;
@property (nonatomic, copy) FCActionSheetBlock dismissalBlock;
@property (nonatomic) NSMutableArray *otherButtonBlocks;
@property (nonatomic) NSMutableArray *otherButtonIndexes;
@end

@implementation FCActionSheet

+ (void)dismissAll
{
    [[NSNotificationCenter defaultCenter] postNotificationName:FCActionSheetDismissAllNotification object:nil];
}

- (instancetype)initWithTitle:(NSString *)title
{
	if ( (self = [super initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil]) ) {
		self.otherButtonBlocks = [NSMutableArray array];
		self.otherButtonIndexes = [NSMutableArray array];
	}
	return self;
}

- (void)setDismissedAction:(FCActionSheetBlock)block
{
    self.dismissalBlock = block;
}

- (void)addButtonWithTitle:(NSString *)title action:(FCActionSheetBlock)block
{
    [self.otherButtonBlocks addObject:[block copy]];
    [self.otherButtonIndexes addObject:@([self addButtonWithTitle:title])];
}

- (void)addCancelButtonWithAction:(FCActionSheetBlock)block { [self addCancelButtonWithTitle:FCActionSheetDefaultCancelButtonTitle action:block]; }

- (void)addCancelButtonWithTitle:(NSString *)title action:(FCActionSheetBlock)block
{
    if (self.cancelButtonIndex >= 0) {
		[[NSException exceptionWithName:@"IPActionSheetDuplicateSpecialButtonException" 
			reason:@"This IPActionSheet has already defined a cancel button" userInfo:nil
		] raise];
    }

    self.cancelButtonBlock = block;
	self.cancelButtonIndex = [self addButtonWithTitle:title];
}

- (void)addDestructiveButtonWithTitle:(NSString *)title action:(FCActionSheetBlock)block
{
    if (self.destructiveButtonIndex >= 0) {
		[[NSException exceptionWithName:@"IPActionSheetDuplicateSpecialButtonException" 
			reason:@"This IPActionSheet has already defined a destructive button" userInfo:nil
		] raise];
    }
    
    self.destructiveButtonBlock = block;
	self.destructiveButtonIndex = [self addButtonWithTitle:title];
}

#pragma mark - UIActionSheetDelegate

- (void)callDismissBlock:(NSNotification *)n { [self dismissWithClickedButtonIndex:self.cancelButtonIndex animated:YES]; }

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    // Only ever show one action sheet at a time
    [self.class dismissAll];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callDismissBlock:) name:FCActionSheetDismissAllNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callDismissBlock:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callDismissBlock:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FCActionSheetDismissAllNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
	if (buttonIndex == self.cancelButtonIndex) {
        if (self.cancelButtonBlock) self.cancelButtonBlock();
	} else if (buttonIndex == self.destructiveButtonIndex) {
        if (self.destructiveButtonBlock) self.destructiveButtonBlock();
	} else {
        [self.otherButtonIndexes enumerateObjectsUsingBlock:^(NSNumber *otherButtonIndex, NSUInteger idx, BOOL *stop) {
            if (buttonIndex == otherButtonIndex.intValue) {
                *stop = YES;
                ((FCActionSheetBlock) self.otherButtonBlocks[idx])();
            }
        }];
	}
	
    if (self.dismissalBlock) self.dismissalBlock();
}

@end
