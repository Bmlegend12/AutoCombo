#import <mach-o/dyld.h>
#import <substrate.h>
#import <UIKit/UIKit.h>

// ==========================================
// 1. HOOK LOGIC GAME (DK AUTO COMBO)
// ==========================================

void (*orig_ProcessAttack)(long param_1);

// Mặc định BẬT
BOOL isComboEnabled = YES;

// Danh sách ID skill chuẩn của DK MU (Ví dụ các chiêu DK phổ biến: 19, 20, 21, 22, 23, 41, 42, 43, 44)
// Nếu muốn test xoay chiêu đơn giản, ta xoay giữa các skill chuẩn này
int dk_combo_chain[] = {19, 20, 21, 22, 23}; 
int combo_step = 0;

void hook_ProcessAttack(long param_1) {
    if (isComboEnabled && param_1 != 0) {
        // Lấy ID skill người dùng vừa bấm trên màn hình (đang nằm ở offset 0x24)
        int current_pressed_skill = *(int *)(param_1 + 0x24);
        
        // Nếu người dùng đang bấm 1 skill hợp lệ (ID > 0)
        if (current_pressed_skill > 0) {
            // In log để debug nếu cần, hoặc tự động đổi ID skill theo chuỗi
            // Bạn có thể chỉnh danh sách ID bên trên cho đúng với bộ Skill bạn đang xếp trên màn hình
            *(int *)(param_1 + 0x24) = dk_combo_chain[combo_step];
            combo_step = (combo_step + 1) % (sizeof(dk_combo_chain) / sizeof(int));
        }
    }
    
    // Gọi hàm gốc
    orig_ProcessAttack(param_1);
}

// ==========================================
// 2. TẠO GIAO DIỆN NÚT NỔI
// ==========================================

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
        // MẶC ĐỊNH BẬT = MÀU XANH
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
    self.overlayWindow.center = CGPointMake(self.overlayWindow.center.x + translation.x, 
                                          self.overlayWindow.center.y + translation.y);
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

// ==========================================
// 3. KHỞI TẠO HOOK
// ==========================================

%ctor {
    // Lấy Slide ASLR chuẩn của Main Executable
    uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
    
    // Offset chuẩn trong Ghidra (0x100233c58 - 0x100000000)
    uintptr_t target_offset = 0x233c58;
    uintptr_t absolute_address = slide + target_offset;

    // Thực hiện MSHook
    MSHookFunction((void *)absolute_address, 
                   (void *)hook_ProcessAttack, 
                   (void **)&orig_ProcessAttack);

    // Bật UI sau 3 giây
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[DKComboManager sharedInstance] setupUI];
    });
}
