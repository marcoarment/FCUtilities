//
//  FCAlertView.h
//  Pods
//
//  Created by Marco Arment on 4/6/14.
//
//

#import <UIKit/UIKit.h>

typedef void (^FCAlertViewBlock)(void);

@interface FCAlertView : UIAlertView <UIAlertViewDelegate>

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle cancelBlock:(FCAlertViewBlock)cancelBlock;
- (void)addButtonWithTitle:(NSString *)title action:(FCAlertViewBlock)block;

@end
