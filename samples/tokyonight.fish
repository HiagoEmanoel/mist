# @fish-lsp-disable 4004
function fish_prompt
    set -l blue 7aa2f7
    set -l cyan 7dcfff
    set -l magenta bb9af7
    set -l green 9ece6a
    set -l red f7768e
    set -l comment 565f89

    # Line 1: full context (login, path, git)
    set_color $magenta
    mist_login "╭─ %s %u "

    set_color $cyan
    mist_pwd -p " %t%p%d"

    set_color $blue
    mist_git "  %r%C" "%A%B"

    echo
    # Line 2: dynamic command-status indicator
    set_color $magenta
    printf "╰─"

    # Arrow color based on last command success/failure
    set -l status_code (mist_info "%c")
    if test "$status_code" = 0
        set_color $green
    else
        set_color $red
    end

    printf " ❯ "
    set_color normal
end

function fish_right_prompt
    set -l comment 565f89
    set -l cyan 7dcfff

    echo -e "\e[1A"

    # Duration and clock
    set_color $comment
    mist_info -m 1000 "%t "

    set_color $cyan
    mist_date "󰥔 %H:%m:%s"

    echo -e "\e[1B"
    set_color normal
end
