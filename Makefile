ARCHS = armv7 arm64
include theos/makefiles/common.mk

export GO_EASY_ON_ME := 1

TWEAK_NAME = BannerStyle
BannerStyle_CFLAGS = -fobjc-arc
BannerStyle_FILES = Tweak.xm MGFashionMenuView.m
BannerStyle_FRAMEWORKS = UIKit CoreGraphics QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += BannerStyleSettings
include $(THEOS_MAKE_PATH)/aggregate.mk

before-stage::
	find . -name ".DS_STORE" -delete
	
after-install::
	install.exec "killall -9 backboardd"
