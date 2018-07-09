#include <notify.h>

@interface _CDBatterySaver : NSObject
+(id)batterySaver;
-(long long)setMode:(long long)arg1;
-(long long)getPowerMode;
@end

@interface SBUserAgent : NSObject
- (_Bool)deviceIsLocked;
@end

@interface SpringBoard : NSObject
@property(readonly, nonatomic) SBUserAgent *pluginUserAgent;
@end

// global variable
static BOOL _isEnabled;
static BOOL _isUserEnabledLPM;

static void loadPrefs(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSDictionary *prefs = NULL;

	CFStringRef appID = CFSTR("pw.ssnull.lockedlpm");
	CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

	if (keyList) {
		prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		CFRelease(keyList);
	}

	_isEnabled = (prefs && [prefs objectForKey:@"enabled"]) ? [[prefs objectForKey:@"enabled"] boolValue] : YES;
}

%hook SBLockScreenManager
- (void)_setUILocked:(_Bool)locked {
	%orig;

	if (!_isEnabled) {
		return;
	}

	if (locked) {
		_isUserEnabledLPM = [[_CDBatterySaver batterySaver] getPowerMode] == 1;

		if (!_isUserEnabledLPM) {
			[[_CDBatterySaver batterySaver] setMode: 1];
		}
	}
	else {
		if (!_isUserEnabledLPM) {
			[[_CDBatterySaver batterySaver] setMode: 0];
		}
	}
}
%end

%hook SBUIController
- (void)updateBatteryState:(id)arg1 {
	%orig;

	if (!_isEnabled) {
		return;
	}

	if ([((SpringBoard*)[UIApplication sharedApplication]).pluginUserAgent deviceIsLocked]) {
		[[_CDBatterySaver batterySaver] setMode: 1];
	}
}
%end

%hook SpringBoard
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    %orig;

	if (!_isEnabled) {
		return;
	}

	// enable LPM after respring
    [[_CDBatterySaver batterySaver] setMode: 1];
	_isUserEnabledLPM = NO;
}
%end

%ctor {
	loadPrefs(NULL, NULL, NULL, NULL, NULL);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, loadPrefs, CFSTR("pw.ssnull.lockedlpm/preferences.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

	%init
}