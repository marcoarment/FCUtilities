//
//  FCWebViewLongPressActivityMenu.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#import "FCWebViewLongPressActivityMenu.h"
#import "FCOpenInSafariActivity.h"

static void onViewAndSubviewsRecursive(UIView *startingView, void (^block)(UIView *view))
{
    block(startingView);
    for (UIView *v in startingView.subviews) onViewAndSubviewsRecursive(v, block);
}

@interface FCWebViewLongPressActivityMenu () <UIGestureRecognizerDelegate>
@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) UIViewController *viewController;
@end

@implementation FCWebViewLongPressActivityMenu

- (void)attachToWebView:(WKWebView *)webView inViewController:(UIViewController *)viewController
{
    self.webView = webView;
    self.viewController = viewController;
    [self attachGestureRecognizer];
}

- (void)attachGestureRecognizer
{
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    lpgr.minimumPressDuration *= 0.9;
    lpgr.delegate = self;
    [self.webView addGestureRecognizer:lpgr];
}

#pragma mark - UIGestureRecognizerDelegate for long-press link interception

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer { return YES; }

- (void)longPressed:(UILongPressGestureRecognizer *)gr
{
    if (gr.state == UIGestureRecognizerStateBegan) {
        if (_viewController.presentedViewController) return;
        
        CGPoint location = [gr locationInView:self.webView];
        CGFloat scale = self.webView.scrollView.zoomScale;
        location.x -= self.webView.scrollView.contentInset.left;
        location.y -= self.webView.scrollView.contentInset.top;
        location.x /= scale;
        location.y /= scale;
        
        NSString *js = [NSString stringWithFormat:
            @"(function () { var e = document.elementFromPoint(%d, %d); while (e && ! e.href) e = e.parentNode; if (! e || ! e.href) return ''; "
            @"var r = e.getClientRects()[0]; return '{{' + r.left + ',' + r.top + '},{' + r.width + ',' + r.height + '}} ' + e.href; })()",
            (int) location.x, (int) location.y
        ];
        
        [self.webView evaluateJavaScript:js completionHandler:^(NSString *result, NSError *error) {
            if (! result || ! [result isKindOfClass:NSString.class] || ! result.length) return;
            NSUInteger firstSpaceIndex = [result rangeOfString:@" "].location;
            if (firstSpaceIndex == NSNotFound) return;

            CGRect linkRect = CGRectFromString([result substringToIndex:firstSpaceIndex]);
            NSURL *url = [NSURL URLWithString:[result substringFromIndex:firstSpaceIndex + 1]];
            NSSet *permittedSchemes = [NSSet setWithObjects:@"http", @"https", nil];
            if (! url || ! url.scheme || ! [permittedSchemes containsObject:url.scheme.lowercaseString]) return;

            linkRect.origin.x *= scale;
            linkRect.origin.y *= scale;
            linkRect.size.width *= scale;
            linkRect.size.height *= scale;
            linkRect.origin.x += self.webView.scrollView.contentInset.left;
            linkRect.origin.y += self.webView.scrollView.contentInset.top;
            
            NSMutableArray *disabledGestureRecognizers = [NSMutableArray array];
            onViewAndSubviewsRecursive(self.webView, ^(UIView *view) {
                for (UIGestureRecognizer *g in view.gestureRecognizers) {
                    if (g != gr && g.enabled) {
                        g.enabled = NO;
                        [disabledGestureRecognizers addObject:g];
                    }
                }
            });

            UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[ url ] applicationActivities:@[ [[FCOpenInSafariActivity alloc] init] ]];
            
            UIPopoverPresentationController *existingPPC = self.viewController.popoverPresentationController;
            if (existingPPC && (existingPPC.sourceView || existingPPC.barButtonItem)) {
                avc.popoverPresentationController.sourceView = existingPPC.sourceView;
                avc.popoverPresentationController.barButtonItem = existingPPC.barButtonItem;
                avc.popoverPresentationController.sourceRect = existingPPC.sourceRect;
                avc.popoverPresentationController.permittedArrowDirections = existingPPC.permittedArrowDirections;
                UIViewController *presentingVC = self.viewController.presentingViewController;
            
                [presentingVC dismissViewControllerAnimated:NO completion:^{
                    [presentingVC presentViewController:avc animated:YES completion:nil];
                }];
            } else {
                avc.popoverPresentationController.sourceView = self.webView;
                avc.popoverPresentationController.sourceRect = linkRect;
                avc.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
                [self.viewController presentViewController:avc animated:YES completion:nil];
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                for (UIGestureRecognizer *g in disabledGestureRecognizers) g.enabled = YES;
            });
        }];
    }
}

@end


@interface FCWebViewWithLongPressActivityMenu () <UIGestureRecognizerDelegate>
@property (nonatomic) FCWebViewLongPressActivityMenu *longPressActivityMenu;
@end

@implementation FCWebViewWithLongPressActivityMenu
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration viewController:(UIViewController *)viewController
{
    if ( (self = [super initWithFrame:frame configuration:configuration]) ) {
        self.longPressActivityMenu = [FCWebViewLongPressActivityMenu new];
        [self.longPressActivityMenu attachToWebView:self inViewController:viewController];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(menuDidHide) name:UIMenuControllerDidHideMenuNotification object:nil];
        
        UIGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(responderTapGestureFired:)];
        tapGR.delegate = self;
        [self addGestureRecognizer:tapGR];
    }
    return self;
}

// By default, selecting text in a WKWebView makes the webview first responder.
// This blocks many modifier-less UIKeyCommands from working afterward (spacebar, arrow keys).
// Resigning first responder when the UIMenuController is done fixes this.

- (void)resignFirstResponderIfNotNeeded
{
    if (UIMenuController.sharedMenuController.isMenuVisible) return;
    
    [self evaluateJavaScript:@"window.getSelection().toString()" completionHandler:^(NSString *selection, NSError *error) {
        if (! selection.length) [self resignFirstResponder];
    }];
}

- (void)menuDidHide
{
    if (! _allowsFirstResponderCapture) [self resignFirstResponderIfNotNeeded];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer { return YES; }

- (void)responderTapGestureFired:(UITapGestureRecognizer *)gr
{
    if (! _allowsFirstResponderCapture) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self resignFirstResponderIfNotNeeded];
    });
}

@end

