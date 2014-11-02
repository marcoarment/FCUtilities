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
@property (nonatomic, weak) UIWebView *uiWebView;
@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) UIViewController *viewController;
@end

@implementation FCWebViewLongPressActivityMenu

- (void)attachToUIWebView:(UIWebView *)webView inViewController:(UIViewController *)viewController
{
    self.uiWebView = webView;
    self.viewController = viewController;
    [self attachGestureRecognizer];
}

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
    [(self.webView ?: self.uiWebView) addGestureRecognizer:lpgr];
}

#pragma mark - UIGestureRecognizerDelegate for long-press link interception

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer { return YES; }

- (void)longPressed:(UILongPressGestureRecognizer *)gr
{
    if (gr.state == UIGestureRecognizerStateBegan) {
        UIView *targetWebView = self.uiWebView ? self.uiWebView : self.webView;
        UIScrollView *scrollView = self.uiWebView ? self.uiWebView.scrollView : self.webView.scrollView;
        CGPoint location = [gr locationInView:targetWebView];
        CGFloat scale = scrollView.zoomScale;
        location.x -= scrollView.contentInset.left;
        location.y -= scrollView.contentInset.top;
        location.x /= scale;
        location.y /= scale;
        
        NSString *js = [NSString stringWithFormat:
            @"(function () { var e = document.elementFromPoint(%d, %d); while (e && ! e.href) e = e.parentNode; if (! e || ! e.href) return ''; "
            @"var r = e.getClientRects()[0]; return '{{' + r.left + ',' + r.top + '},{' + r.width + ',' + r.height + '}} ' + e.href; })()",
            (int) location.x, (int) location.y
        ];
        
        void (^processJSResult)(NSString *) = ^(NSString *result) {
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
            linkRect.origin.x += scrollView.contentInset.left;
            linkRect.origin.y += scrollView.contentInset.top;
            
            NSMutableArray *disabledGestureRecognizers = [NSMutableArray array];
            onViewAndSubviewsRecursive(targetWebView, ^(UIView *view) {
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
                avc.popoverPresentationController.sourceView = targetWebView;
                avc.popoverPresentationController.sourceRect = linkRect;
                avc.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
                [self.viewController presentViewController:avc animated:YES completion:nil];
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                for (UIGestureRecognizer *g in disabledGestureRecognizers) g.enabled = YES;
            });
        };
        
        if (self.uiWebView) {
            processJSResult([self.uiWebView stringByEvaluatingJavaScriptFromString:js]);
        } else {
            [self.webView evaluateJavaScript:js completionHandler:^(NSString *href, NSError *error) { processJSResult(href); }];
        }
    }
}

@end


@interface FCUIWebViewWithLongPressActivityMenu ()
@property (nonatomic) FCWebViewLongPressActivityMenu *longPressActivityMenu;
@end

@interface FCWKWebViewWithLongPressActivityMenu ()
@property (nonatomic) FCWebViewLongPressActivityMenu *longPressActivityMenu;
@end

@implementation FCUIWebViewWithLongPressActivityMenu
- (instancetype)initWithFrame:(CGRect)frame viewController:(UIViewController *)viewController
{
    if ( (self = [super initWithFrame:frame]) ) {
        self.longPressActivityMenu = [FCWebViewLongPressActivityMenu new];
        [self.longPressActivityMenu attachToUIWebView:self inViewController:viewController];
    }
    return self;
}
@end

@implementation FCWKWebViewWithLongPressActivityMenu
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration viewController:(UIViewController *)viewController
{
    if ( (self = [super initWithFrame:frame configuration:configuration]) ) {
        self.longPressActivityMenu = [FCWebViewLongPressActivityMenu new];
        [self.longPressActivityMenu attachToWebView:self inViewController:viewController];
    }
    return self;
}
@end

