if status is-interactive
    # Commands to run in interactive sessions can go here
end
# emsdk (only if it is installed)
test -f ~/emsdk/emsdk_env.fish; and source ~/emsdk/emsdk_env.fish
set -gx DOTFILES ~/dotfiles/.config/
alias nigga=sudo
