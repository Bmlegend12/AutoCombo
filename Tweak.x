#import <substrate.h>

// Khai báo lại hàm gốc
void (*orig_FUN_100233c58)(long param_1);

// Biến đếm thứ tự Combo DK (Skill 1 -> 2 -> 3)
int combo_step = 0;
int dk_skills[] = {19, 20, 22}; // Thay ID Skill chuẩn của DK vào đây

void hook_FUN_100233c58(long param_1) {
    // Nếu bật Auto Combo
    if (param_1 != 0 && *(int *)(param_1 + 0x20) != -1) { 
        
        // Ghi đè Skill ID mong muốn vào offset 0x24
        *(int *)(param_1 + 0x24) = dk_skills[combo_step];
        
        // Chuyển bước combo tiếp theo
        combo_step = (combo_step + 1) % 3;
    }

    // Gọi lại hàm gốc để game xử lý đánh
    orig_FUN_100233c58(param_1);
}

%ctor {
    // Hook vào địa chỉ hàm FUN_100233c58 (Address: 0x100233c58)
    MSHookFunction((void *)(0x100233c58 + _dyld_get_image_vmaddr_slide(0)), 
                   (void *)hook_FUN_100233c58, 
                   (void **)&orig_FUN_100233c58);
}
