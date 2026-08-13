#import <mach-o/dyld.h>
#import <substrate.h>
#import <UIKit/UIKit.h>

// ==========================================
// 1. HOOK LOGIC GAME (DK AUTO COMBO)
// ==========================================

void (*orig_ProcessAttack)(long param_1);

// Danh sách ID Skill trong chuỗi Combo của DK
int combo_skills[] = {1, 2, 3}; 
int current_combo_idx = 0;
BOOL isComboEnabled = YES; // Mặc định bật Combo

void hook_ProcessAttack(long param_1) {
    if (isComboEnabled && param_1 != 0) {
        // Kiểm tra nếu nhân vật đang có mục tiêu (param_1 + 0x20 != -1)
        if (*(int *)(param_1 + 0x20) != -1) {
            
            // Ghi đè ID Skill tiếp theo vào offset 0x24
            *(int *)(param_1 + 0x24) = combo_skills[current_combo_idx];
            
            // Xoay vòng bước Combo (0 -> 1 -> 2 -> 0)
            current_combo_idx = (current_combo_idx + 1) % 3;
        }
    }
    // Gọi lại hàm gốc của game để gửi gói tin và diễn hoạt hoạt ảnh
    orig_ProcessAttack(param_1);
}


// ==========================================
// 2. TẠO GIAO DIỆN NÚT NỔI (OVERLAY UI)
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
        if (self.overlayWindow) return; // Tránh tạo trùng lặp Window

        // Tìm UIWindowScene đang hoạt động trên iOS 13+
        UIWindowScene *currentScene = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && 
                [scene isKindOfClass:[UIWindowScene class]]) {
                currentScene = (UIWindowScene *)scene;
                break;
            }
        }

        // Khởi tạo Window nổi đè lên trên cùng của Game
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
        self.overlayWindow.windowLevel = UIWindowLevelStatusBar + 1000; // Mức độ ưu tiên hiển thị cao nhất
        self.overlayWindow.backgroundColor = [UIColor clearColor];
        self.overlayWindow.hidden = NO;

        // Tạo Nút bấm tròn
        self.comboButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.comboButton.frame = CGRectMake(0, 0, 65, 65);
        self.comboButton.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.85];
        [self.comboButton setTitle:@"COMBO\nON" forState:UIControlStateNormal];
        self.comboButton.titleLabel.font = [UIFont boldSystemFontOfSize:11];
        self.comboButton.titleLabel.numberOfLines = 2;
        self.comboButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.comboButton.layer.cornerRadius = 32.5;
        self.comboButton.clipsToBounds = YES;

        // Sự kiện Bấm để BẬT / TẮT
        [self.comboButton addTarget:self action:@selector(toggleCombo) forControlEvents:UIControlEventTouchUpInside];

        // Sự kiện Kéo thả di chuyển vị trí Nút Nổi
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
// 3. THỰC THI HOOK KHỦNG KHI TẢI TWEAK
// ==========================================

%ctor {
    // 1. Lấy slide ASLR của tiến trình game
    uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
    
    // 2. Offset chính xác của hàm FUN_100233c58 (0x100233c58 - 0x100000000 = 0x233c58)
    uintptr_t target_offset = 0x233c58;
    uintptr_t absolute_address = slide + target_offset;

    // 3. Thực hiện Hook hàm ProcessAttack
    MSHookFunction((void *)absolute_address, 
                   (void *)hook_ProcessAttack, 
                   (void **)&orig_ProcessAttack);

    // 4. Trì hoãn 4 giây chờ game load xong rồi tạo Nút Nổi
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[DKComboManager sharedInstance] setupUI];
    });
}
