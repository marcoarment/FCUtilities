//
//  FCAlertView.m
//  Pods
//
//  Created by Marco Arment on 4/6/14.
//
//

#import "FCAlertView.h"

@interface FCAlertView ()
@property (nonatomic, copy) FCAlertViewBlock cancelButtonBlock;
@property (nonatomic) NSMutableDictionary *otherButtonBlocks;
@end

@implementation FCAlertView

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(FCAlertViewBlock)cancelBlock
{
    if ( (self = [super initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil]) ) {
        self.cancelButtonBlock = cancelBlock;
        self.otherButtonBlocks = [NSMutableDictionary dictionary];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)addButtonWithTitle:(NSString *)title action:(FCAlertViewBlock)block
{
    self.otherButtonBlocks[@(self.numberOfButtons)] = block;
    [self addButtonWithTitle:title];
}

- (void)show
{
    if ([NSThread isMainThread]) [super show];
    else dispatch_async(dispatch_get_main_queue(), ^{ [super show]; });
}

- (void)applicationDidEnterBackground:(id)sender
{
    [self dismissWithClickedButtonIndex:self.cancelButtonIndex animated:NO];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == self.cancelButtonIndex || buttonIndex == -1) {
        if (self.cancelButtonBlock) self.cancelButtonBlock();
    } else {
        FCAlertViewBlock buttonBlock = self.otherButtonBlocks[@(buttonIndex)];
        if (buttonBlock) buttonBlock();
    }
}

@end
