# @fish-lsp-disable 4004
function fish_prompt
    # Zenburn-like style 
    set -l zen_gray 5f5f5f
    set -l zen_green 7f9f7f
    set -l zen_cyan 93e0e3
    set -l zen_white dcdccc
    set -l zen_red cc9393
    set -l zen_yellow e0cf9f

    # Decorative line
    set_color $zen_gray
    mist_line .

    # User / login
    set_color $zen_green
    mist_login "%s %u "

    # Directory path and current folder name
    set_color $zen_cyan -d
    mist_pwd -p "%s %t%p"

    set_color -o $zen_white
    mist_pwd "%d "

    # Git status
    set_color $zen_red
    mist_git "%R%r%C %A%B"

    # Previous command error/duration (only if > 1s)
    set_color $zen_yellow
    mist_info -m 1000 -s "" -e " [%c]" " %t%s"

    # Prompt symbol
    set_color $zen_green
    printf "\n> "

    set_color normal
end
