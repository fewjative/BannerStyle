ARCHS = armv7 arm64
include theos/makefiles/common.mk

BUNDLE_NAME = BannerStyleSettings
BannerStyleSettings_FILES = BannerStyleSettings.mm
BannerStyleSettings_INSTALL_PATH = /Library/PreferenceBundles
BannerStyleSettings_FRAMEWORKS = UIKit Social
BannerStyleSettings_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/BannerStyleSettings.plist$(ECHO_END)

include $(THEOS_MAKE_PATH)/aggregate.mk
