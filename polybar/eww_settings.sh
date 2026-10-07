eww open a_setting_closer
WIN_ID=$(xdotool search --name "Eww - a_setting_closer" | head -n 1)
xdotool set_window --classname "eww_settings_closer" "$WIN_ID"
eww open settings
WIN_ID_MAIN=$(xdotool search --name "Eww - settings" | head -n 1)
xdotool set_window --classname "eww_settings_main" "$WIN_ID_MAIN"
xdotool windowraise "$WIN_ID_MAIN"