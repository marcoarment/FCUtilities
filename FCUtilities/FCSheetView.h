//
//  FCSheetView.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <UIKit/UIKit.h>


@interface FCSheetView : UIView

- (instancetype)initWithContentView:(UIView *)contentView;
- (void)presentInView:(UIView *)view;

@end
