# @fish-lsp-disable 4004
function fish_prompt
    set last_status $status
    # Theme colors (Catppuccin Macchiato style)  
    set -l color_icon f5a97f
    set -l color_user eed49f
    set -l color_pwd f0c6c6
    set -l color_git ee99a0
    set -l color_dark 181926
    set -l color_red ed8796
    set -l color_green a6da95

    # Get login components
    set user_parts (mist_login -n "%s" " %u ")

    # Segment 1: Left rounded cap + Icon/Prefix  
    set_color $color_icon
    printf ""
    set_color $color_dark -b $color_icon
    printf "%s" $user_parts[1]

    # Segment 2: User info  
    set_color $color_icon -b $color_user
    printf ""
    set_color $color_dark -b $color_user
    printf "%s" $user_parts[2]

    # Segment 3: Working Directory 
    set_color $color_user -b $color_pwd
    printf ""
    set_color $color_dark -b $color_pwd
    mist_pwd " %s %t%p%d "

    # Segment 4: Git Status 
    set -l git_part (mist_git -n " %R%r%C %A%B")

    if test -n "$git_part"
        set_color $color_pwd -b $color_git
        printf ""
        set_color $color_dark -b $color_git
        printf "%s" $git_part

        set_color normal
        set_color $color_git
        printf ""
    else
        set_color normal
        set_color $color_pwd
        printf ""
    end

    # Newline and prompt character based on last status  
    echo
    if test $last_status -eq 0
        set_color $color_green
    else
        set_color $color_red
    end

    printf " ❯ "
    set_color normal
end
