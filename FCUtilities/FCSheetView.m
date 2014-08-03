//
//  FCSheetView.m
//  Part of FCUtilities by Marco Arment. See included LICENSE file for BSD license.
//

#define kSlideInAnimationDuration     0.40f
#define kSlideOutAnimationDuration    0.25f
#define kExtraHeightForBottomOverlap  40

#import "FCSheetView.h"

#define FCSheetViewForceDismissNotification @"FCSheetViewForceDismissNotification"

@interface FCSheetView ()
@property (nonatomic) UIButton *dismissButton;
@property (nonatomic) UIView *contentContainer;
@property (nonatomic) UIToolbar *blurToolbar;
@property (nonatomic) CALayer *blurLayer;
@property (nonatomic) UIView *blurView;
@property (nonatomic, copy) void (^dismissAnimations)();
@property (nonatomic) BOOL presented;
@end

@implementation FCSheetView

+ (void)dismissAllAnimated:(BOOL)animated
{
    [NSNotificationCenter.defaultCenter postNotificationName:FCSheetViewForceDismissNotification object:@(animated)];
}

- (instancetype)initWithContentView:(UIView *)contentView
{
    if ( (self = [super init]) ) {
        self.presented = NO;
        self.accessibilityViewIsModal = YES;

        CGRect contentContainerFrame = contentView.bounds;
        contentContainerFrame.size.height += kExtraHeightForBottomOverlap;
        self.contentContainer = [[UIView alloc] initWithFrame:contentContainerFrame];
        self.contentContainer.backgroundColor = UIColor.clearColor;
        self.contentContainer.autoresizesSubviews = YES;
        self.contentContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        contentContainerFrame.origin = CGPointZero;
        self.blurToolbar = [[UIToolbar alloc] initWithFrame:contentContainerFrame];
        self.blurLayer = self.blurToolbar.layer;
        self.blurView = [UIView new];
        self.blurView.userInteractionEnabled = NO;
        self.contentContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_blurView.layer addSublayer:_blurLayer];
        [self.contentContainer addSubview:_blurView];
        
        CGRect innerContentFrame = contentView.bounds;
        innerContentFrame.origin = CGPointZero;
        contentView.frame = innerContentFrame;
        [self.contentContainer addSubview:contentView];

        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.autoresizesSubviews = YES;
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        self.dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchDown];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(dismissByNotification:) name:FCSheetViewForceDismissNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:FCSheetViewForceDismissNotification object:nil];
}

- (void)dismissByNotification:(NSNotification *)n
{
    if (self.presented) [self dismissAnimated:((NSNumber *) n.object).boolValue completion:NULL];
}

- (void)dismissAnimated:(BOOL)animated completion:(void (^)())completionBlock
{
    if (animated) {
        [UIView animateWithDuration:kSlideOutAnimationDuration animations:^{
            CGRect contentFrame = _contentContainer.bounds;
            contentFrame.origin.y = self.bounds.size.height;
            _contentContainer.frame = contentFrame;
            self.backgroundColor = [UIColor clearColor];
            
            if (self.dismissAnimations) self.dismissAnimations();
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
            if (self.dismissAction) self.dismissAction();
            if (completionBlock) completionBlock();
        }];
    } else {
        [self removeFromSuperview];
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
        if (self.dismissAction) self.dismissAction();
        if (completionBlock) completionBlock();
    }
}

- (void)dismiss
{
    [self dismissAnimated:YES completion:NULL];
}

- (BOOL)accessibilityPerformEscape
{
    [self dismiss];
    return YES;
}

- (void)presentInView:(UIView *)view
{
    self.presented = YES;
    [self presentInView:view extraAnimations:nil extraDismissAnimations:nil];
}

- (void)presentInView:(UIView *)view extraAnimations:(void (^)())animations extraDismissAnimations:(void (^)())dismissAnimations
{
    if (! view.window) [[NSException exceptionWithName:NSInvalidArgumentException reason:@"FCSheetView host view must be in a window" userInfo:nil] raise];
    
    self.presented = YES;
    self.dismissAnimations = dismissAnimations;

    CGRect masterFrame = view.window.bounds;
    self.frame = masterFrame;
    [view.window addSubview:self];
    
    CGRect dismissFrame = masterFrame;
    dismissFrame.size.height = masterFrame.size.height - (_contentContainer.bounds.size.height - kExtraHeightForBottomOverlap);
    
    self.dismissButton.frame = dismissFrame;
    self.dismissButton.accessibilityLabel = NSLocalizedString(@"Back", @"FCSheetView dismiss-button accessibility label");
    [self addSubview:self.dismissButton];
    
    __block CGRect contentFrame = masterFrame;
    contentFrame.size.height = _contentContainer.bounds.size.height;
    contentFrame.origin.y = masterFrame.size.height;
    _contentContainer.frame = contentFrame;
    [self addSubview:_contentContainer];
    self.tintColor = view.window.tintColor;
    
    [UIView animateWithDuration:kSlideInAnimationDuration delay:0
        usingSpringWithDamping:0.66f initialSpringVelocity:0.9f
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
            contentFrame.origin.y = masterFrame.size.height - (_contentContainer.bounds.size.height - kExtraHeightForBottomOverlap);
            _contentContainer.frame = contentFrame;
            self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.25f];
            if (animations) animations();
        }
        completion:^(BOOL finished) {
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
        }
    ];
}


@end
