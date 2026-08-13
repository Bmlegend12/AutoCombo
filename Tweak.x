#import <UIKit/UIKit.h>

// ==========================================
// 1. HELPER GIẢ LẬP THAO TÁC BẤM MÀN HÌNH
// ==========================================

@interface UITouch (Synthetic)
- (id)initAtPoint:(CGPoint)point inWindow:(UIWindow *)window;
- (void)setPhase:(UITouchPhase)phase;
@end

void SimulateTouchAtPoint(CGPoint point) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *targetWindow = nil;
        
        // Tìm UIWindowScene và Window đang active chuẩn iOS 13+
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && 
                [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow || window.isVisible) {
                        targetWindow = window;
                        break;
                    }
                }
            }
        }
        
        if (!targetWindow) return;

        // Bắn sự kiện chạm vào UIView ở tọa độ chỉ định
        UIView *hitView = [targetWindow hitTest:point withEvent:nil];
        if (hitView) {
            [hitView touchesBegan:[NSSet setWithObject:[[UITouch alloc] init]] withEvent:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [hitView touchesEnded:[NSSet setWithObject:[[UITouch alloc] init]] withEvent:nil];
            });
        }
    });
}

// ==========================================
// 2. QUẢN LÝ OVERLAY UI & VÒNG LẶP COMBO
// ==========================================

@interface DKComboManager : NSObject
@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, strong) UIButton *comboButton;
@property (nonatomic, strong) NSTimer *comboTimer;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, assign) int currentStep;
@end

@implementation DKComboManager

+ (instancetype)sharedInstance {
    static DKComboManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DKComboManager alloc] init];
    });
    return instance;
}

- (void)setupUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.overlayWindow) return;

        UIWindowScene *currentScene = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && 
                [scene isKindOfClass:[UIWindowScene class]]) {
                currentScene = (UIWindowScene *)scene;
                break;
            }
        }

        if (@available(iOS 13.0, *)) {
            if (currentScene) {
                self.overlayWindow = [[UIWindow alloc] initWithWindowScene:currentScene];
            } else {
                self.overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            }
        } else {
            self.overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }

        self.overlayWindow.frame = CGRectMake(80, 80, 65, 65);
        self.overlayWindow.windowLevel = UIWindowLevelStatusBar + 1000;
        self.overlayWindow.backgroundColor = [UIColor clearColor];
        self.overlayWindow.hidden = NO;

        self.comboButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.comboButton.frame = CGRectMake(0, 0, 65, 65);
        self.comboButton.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.85];
        [self.comboButton setTitle:@"COMBO\nOFF" forState:UIControlStateNormal];
        self.comboButton.titleLabel.font = [UIFont boldSystemFontOfSize:11];
        self.comboButton.titleLabel.numberOfLines = 2;
        self.comboButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.comboButton.layer.cornerRadius = 32.5;
        self.comboButton.clipsToBounds = YES;

        [self.comboButton addTarget:self action:@selector(toggleCombo) forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.comboButton addGestureRecognizer:pan];

        [self.overlayWindow addSubview:self.comboButton];
        [self.overlayWindow makeKeyAndVisible];
    });
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.overlayWindow];
    self.overlayWindow.center = CGPointMake(self.overlayWindow.center.x + translation.x, 
                                          self.overlayWindow.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:self.overlayWindow];
}

- (void)toggleCombo {
    self.isRunning = !self.isRunning;
    if (self.isRunning) {
        [self.comboButton setTitle:@"COMBO\nON" forState:UIControlStateNormal];
        self.comboButton.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.85];
        [self startAutoCombo];
    } else {
        [self.comboButton setTitle:@"COMBO\nOFF" forState:UIControlStateNormal];
        self.comboButton.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.85];
        [self stopAutoCombo];
    }
}

- (void)startAutoCombo {
    self.currentStep = 0;
    self.comboTimer = [NSTimer scheduledTimerWithTimeInterval:0.18 
                                                        target:self 
                                                      selector:@selector(executeComboStep) 
                                                      userInfo:nil 
                                                       repeats:YES];
}

- (void)stopAutoCombo {
    if (self.comboTimer) {
        [self.comboTimer invalidate];
        self.comboTimer = nil;
    }
}

- (void)executeComboStep {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat width = screenBounds.size.width;
    CGFloat height = screenBounds.size.height;

    // Tọa độ tương đối của 3 phím Skill cụm dưới bên phải
    CGPoint skill1 = CGPointMake(width * 0.82, height * 0.85);
    CGPoint skill2 = CGPointMake(width * 0.88, height * 0.72);
    CGPoint skill3 = CGPointMake(width * 0.94, height * 0.58);

    CGPoint targetPoint;
    switch (self.currentStep) {
        case 0:
            targetPoint = skill1;
            break;
        case 1:
            targetPoint = skill2;
            break;
        case 2:
            targetPoint = skill3;
            break;
        default:
            targetPoint = skill1;
            break;
    }

    SimulateTouchAtPoint(targetPoint);
    self.currentStep = (self.currentStep + 1) % 3;
}

@end

// ==========================================
// 3. THỰC THI KHỞI TẠO TWEAK
// ==========================================

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[DKComboManager sharedInstance] setupUI];
    });
}
