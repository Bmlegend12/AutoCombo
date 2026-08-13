TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DKAutoCombo

DKAutoCombo_FILES = Tweak.x
DKAutoCombo_CFLAGS = -fobjc-arc
DKAutoCombo_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
