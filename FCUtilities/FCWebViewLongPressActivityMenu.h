//
//  FCWebViewLongPressActivityMenu.h
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import <Foundation/Foundation.h>
@import WebKit;

@interface FCWebViewLongPressActivityMenu : NSObject

- (void)attachToUIWebView:(UIWebView *)webView inViewController:(UIViewController *)viewController;
- (void)attachToWebView:(WKWebView *)webView inViewController:(UIViewController *)viewController;

@end


@interface FCUIWebViewWithLongPressActivityMenu : UIWebView

- (instancetype)initWithFrame:(CGRect)frame viewController:(UIViewController *)viewController;

@property (nonatomic, readonly) FCWebViewLongPressActivityMenu *longPressActivityMenu;
@end


@interface FCWKWebViewWithLongPressActivityMenu : WKWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration viewController:(UIViewController *)viewController;

@property (nonatomic, readonly) FCWebViewLongPressActivityMenu *longPressActivityMenu;
@end
