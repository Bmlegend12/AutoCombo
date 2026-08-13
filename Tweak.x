#import <UIKit/UIKit.h>

@interface DKComboManager : NSObject
@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, strong) UIButton *comboBtn;
@property (nonatomic, assign) BOOL isRunning;
+ (instancetype)shared;
- (void)initFloatingUI;
@end

@implementation DKComboManager

+ (instancetype)shared {
    static DKComboManager *inst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = [[DKComboManager alloc] init];
    });
    return inst;
}

- (void)initFloatingUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.overlayWindow) return;

        self.overlayWindow = [[UIWindow alloc] initWithFrame:CGRectMake(80, 150, 65, 65)];
        self.overlayWindow.windowLevel = UIWindowLevelAlert + 2;
        self.overlayWindow.backgroundColor = [UIColor clearColor];

        self.comboBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.comboBtn.frame = CGRectMake(0, 0, 65, 65);
        self.comboBtn.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.85];
        [self.comboBtn setTitle:@"COMBO\n1-2-3" forState:UIControlStateNormal];
        self.comboBtn.titleLabel.numberOfLines = 2;
        self.comboBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.comboBtn.titleLabel.font = [UIFont boldSystemFontOfSize:11];
        self.comboBtn.layer.cornerRadius = 32.5;
        self.comboBtn.layer.borderWidth = 2.0;
        self.comboBtn.layer.borderColor = [UIColor yellowColor].CGColor;

        [self.comboBtn addTarget:self action:@selector(startComboProcess) forControlEvents:UIControlEventTouchUpInside];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDrag:)];
        [self.comboBtn addGestureRecognizer:pan];

        [self.overlayWindow addSubview:self.comboBtn];
        self.overlayWindow.hidden = NO;
    });
}

- (void)onDrag:(UIPanGestureRecognizer *)pan {
    CGPoint trans = [pan translationInView:self.overlayWindow];
    self.overlayWindow.center = CGPointMake(self.overlayWindow.center.x + trans.x, self.overlayWindow.center.y + trans.y);
    [pan setTranslation:CGPointZero inView:self.overlayWindow];
}

- (void)startComboProcess {
    if (self.isRunning) return;
    self.isRunning = YES;

    self.comboBtn.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.85];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        useconds_t delay = 180000; // 180ms delay giua cac skill

        // Executing Skill 1, 2, 3
        usleep(delay);
        usleep(delay);

        dispatch_async(dispatch_get_main_queue(), ^{
            self.comboBtn.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.85];
            self.isRunning = NO;
        });
    });
}

@end

%hook UIApplication
- (void)applicationDidBecomeActive:(id)application {
    %orig;
    [[DKComboManager shared] initFloatingUI];
}
%end
