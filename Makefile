export ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LockedLPM
LockedLPM_FILES = Tweak.xm
LockedLPM_PRIVATE_FRAMEWORKS = CoreDuet

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp LockedLPMPrefs.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/LockedLPMPrefs.plist$(ECHO_END)
	$(ECHO_NOTHING)cp -r Resources $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/LockedLPMPrefs.Resources$(ECHO_END)

after-install::
	install.exec "killall -9 SpringBoard"
