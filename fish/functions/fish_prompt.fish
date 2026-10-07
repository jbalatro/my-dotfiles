# Pill-style prompt matching the bar: monochrome pills that invert with the
# light/dark mode (mango's wallpaper.sh writes the mode to happybar_theme).
#
#   (sdf) (~/dotfiles) (main ±)
#   ❯

function __pill --argument-names bg fg text
    # rounded caps in the pill color, text inside
    set_color $bg
    echo -n 
    set_color -b $bg $fg
    echo -n $text
    set_color normal
    set_color $bg
    echo -n 
    set_color normal
end

function fish_prompt
    set -l last_status $status

    set -l mode light
    set -l f $XDG_RUNTIME_DIR/happybar_theme
    test -r $f; and set mode (string trim < $f)

    # palette: strong pill = the bar's pill color, muted pill = a quieter tone
    if test "$mode" = dark
        set strong_bg d3cfcf; set strong_fg 101014
        set muted_bg 2a2a31;  set muted_fg b5b0ab
        set ok c9ae78;        set bad c47a72
    else
        set strong_bg 101014; set strong_fg e9e6df
        set muted_bg d3cfcf;  set muted_fg 4a4a50
        set ok 8f7430;        set bad a8473f
    end

    # user, then directory
    __pill $muted_bg $muted_fg " $USER "
    echo -n ' '
    __pill $strong_bg $strong_fg " "(prompt_pwd)" "

    # git branch, with a marker when the tree has uncommitted changes
    set -l branch (command git branch --show-current 2>/dev/null)
    if test -n "$branch"
        set -l dirty (command git status --porcelain --untracked-files=no 2>/dev/null | head -n 1)
        echo -n ' '
        if test -n "$dirty"
            __pill $muted_bg $ok " $branch ± "
        else
            __pill $muted_bg $muted_fg " $branch "
        end
    end

    # failed command: its exit code
    if test $last_status -ne 0
        echo -n ' '
        __pill $bad $strong_fg " $last_status "
    end

    echo
    if test $last_status -eq 0
        set_color normal
    else
        set_color $bad
    end
    echo -n '❯ '
    set_color normal
end
