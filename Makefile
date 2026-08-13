TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DKAutoCombo

DKAutoCombo_FILES = Tweak.x
DKAutoCombo_FRAMEWORKS = UIKit CoreGraphics QuartzCore
DKAutoCombo_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
