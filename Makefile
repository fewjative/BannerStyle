ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = BannerStyle
BannerStyle_FILES = Tweak.xm
BannerStyle_FRAMEWORKS = UIKit CoreGraphics QuartzCore
export GO_EASY_ON_ME := 1

include $(THEOS_MAKE_PATH)/tweak.mk

#SUBPROJECTS += BannerStyleSettings
include $(THEOS_MAKE_PATH)/aggregate.mk

before-stage::
	find . -name ".DS_STORE" -delete
	
after-install::
	install.exec "killall -9 backboardd"
