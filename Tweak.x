#import <mach-o/dyld.h>
#import <substrate.h>
#import <UIKit/UIKit.h>

// --- HOOK GAME LOGIC ---
void (*orig_ProcessAttack)(long param_1);

int combo_skills[] = {1, 2, 3}; // ID các skill Combo
int current_combo_idx = 0;
BOOL isComboEnabled = YES;

void hook_ProcessAttack(long param_1) {
    if (isComboEnabled && param_1 != 0 && *(int *)(param_1 + 0x20) != -1) {
        // Ghi đè ID skill tiếp theo vào offset 0x24
        *(int *)(param_1 + 0x24) = combo_skills[current_combo_idx];
        current_combo_idx = (current_combo_idx + 1) % 3;
    }
    orig_ProcessAttack(param_1);
}

// --- OVERLAY UI (NÚT NỔI) ---
@interface DKComboManager : NSObject
@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, strong) UIButton *comboButton;
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

        self.overlayWindow.frame = CGRectMake(80, 100, 65, 65);
        self.overlayWindow.windowLevel = UIWindowLevelStatusBar + 1000;
        self.overlayWindow.backgroundColor = [UIColor clearColor];
        self.overlayWindow.hidden = NO;

        self.comboButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.comboButton.frame = CGRectMake(0, 0, 65, 65);
        self.comboButton.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.85];
        [self.comboButton setTitle:@"COMBO\nON" forState:UIControlStateNormal];
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
    self.overlayWindow.center = CGPointMake(self.overlayWindow.center.x + translation.x, self.overlayWindow.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:self.overlayWindow];
}

- (void)toggleCombo {
    isComboEnabled = !isComboEnabled;
    if (isComboEnabled) {
        [self.comboButton setTitle:@"COMBO\nON" forState:UIControlStateNormal];
        self.comboButton.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.85];
    } else {
        [self.comboButton setTitle:@"COMBO\nOFF" forState:UIControlStateNormal];
        self.comboButton.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.85];
    }
}
@end

%ctor {
    // 1. Hook hàm game
    uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
    MSHookFunction((void *)(0x100233c58 + slide), 
                   (void *)hook_ProcessAttack, 
                   (void **)&orig_ProcessAttack);

    // 2. Chờ 4 giây cho Game tải xong rồi vẽ Nút Nổi
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[DKComboManager sharedInstance] setupUI];
    });
}
