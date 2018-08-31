//
//  FCWebViewLongPressActivityMenu.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <Foundation/Foundation.h>
@import WebKit;

@interface FCWebViewLongPressActivityMenu : NSObject

- (void)attachToWebView:(WKWebView *)webView inViewController:(UIViewController *)viewController;

@end


@interface FCWebViewWithLongPressActivityMenu : WKWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration viewController:(UIViewController *)viewController;

@property (nonatomic) BOOL allowsFirstResponderCapture;
@property (nonatomic, readonly) FCWebViewLongPressActivityMenu *longPressActivityMenu;
@end
