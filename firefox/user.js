// happybar rice: prefs the userChrome.css relies on (symlinked into the profile)
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.theme.toolbar-theme", 2);          // follow the system light/dark scheme
user_pref("browser.tabs.inTitlebar", 1);               // tabs in the titlebar, no menu bar
user_pref("widget.wayland.opaque-region.enabled", false); // let the window be transparent
