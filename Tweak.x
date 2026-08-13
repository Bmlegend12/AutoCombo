#import <mach-o/dyld.h>
#import <substrate.h>
#import <UIKit/UIKit.h>

// Các đoạn code Hook phía dưới của bạn...
void (*orig_ProcessAttack)(long param_1);

int combo_skills[] = {1, 2, 3}; 
int current_combo_idx = 0;

void hook_ProcessAttack(long param_1) {
    if (param_1 != 0 && *(int *)(param_1 + 0x20) != -1) {
        *(int *)(param_1 + 0x24) = combo_skills[current_combo_idx];
        current_combo_idx = (current_combo_idx + 1) % 3;
    }
    orig_ProcessAttack(param_1);
}

%ctor {
    // Lúc này hàm _dyld_get_image_vmaddr_slide đã có header nên sẽ không bị lỗi nữa
    uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
    MSHookFunction((void *)(0x100233c58 + slide), 
                   (void *)hook_ProcessAttack, 
                   (void **)&orig_ProcessAttack);
}
// Mã Hook trực tiếp hàm FUN_100233c58 trong Tweak.x
#import <substrate.h>

void (*orig_ProcessAttack)(long param_1);

// Danh sách ID Skill Combo của DK (Ví dụ: Chém Băng -> Xoay Xoáy -> Đâm Gió)
int combo_skills[] = {1, 2, 3}; 
int current_combo_idx = 0;
bool is_auto_combo_enabled = true;

void hook_ProcessAttack(long param_1) {
    if (is_auto_combo_enabled && param_1 != 0) {
        // Kiểm tra nếu có mục tiêu (param_1 + 0x20 != -1)
        if (*(int *)(param_1 + 0x20) != -1) {
            
            // Ép ID Skill tại offset 0x24 thành Skill tiếp theo trong chuỗi Combo
            *(int *)(param_1 + 0x24) = combo_skills[current_combo_idx];
            
            // Chuyển sang Skill tiếp theo cho lần bấm sau
            current_combo_idx = (current_combo_idx + 1) % 3;
        }
    }
    
    // Gọi lại hàm gốc để game tự gửi gói tin và chạy Animation
    orig_ProcessAttack(param_1);
}

%ctor {
    // Hook thẳng vào địa chỉ hàm FUN_100233c58
    unsigned long long slide = _dyld_get_image_vmaddr_slide(0);
    MSHookFunction((void *)(0x100233c58 + slide), 
                   (void *)hook_ProcessAttack, 
                   (void **)&orig_ProcessAttack);
}
