# @fish-lsp-disable 4004
function fish_prompt
    # Zenburn-like style 
    set -l zen_gray 5f5f5f
    set -l zen_green 7f9f7f
    set -l zen_cyan 93e0e3
    set -l zen_white dcdccc
    set -l zen_red cc9393

    # Draw the separation line
    set_color $zen_gray
    mist_line .

    # User and host login info
    set_color $zen_green
    mist_login "%s %u "

    # Dimmed current working directory path
    set_color $zen_cyan -d
    mist_pwd "%s %t%p"

    # Bold current directory name
    set_color -o $zen_white
    mist_pwd "%d "

    # Git status details
    set_color $zen_red
    mist_git "%R%r%C %A%B"

    # Main prompt arrow
    set_color $zen_green
    printf "\n> "

    # Reset colors to default
    set_color normal
end
