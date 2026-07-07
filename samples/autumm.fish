# @fish-lsp-disable 4004
function fish_prompt
    set -l orange DC884C
    set -l gold eec667
    set -l terracotta e06c75
    set -l bronze C98936
    set -l gray 6b737f

    # User and host login info
    set_color $orange
    mist_login "╭─(%s %u)"

    # Current working directory path 
    set -l pparts (mist_pwd -n " %s %t%p" %d)
    set_color $gold
    printf "$pparts[1]"

    # Highlighted urrent folder 
    set_color -o
    printf "$pparts[2]"

    set -l gparts (mist_git -n %R%r %C " %A%B")

    set_color normal

    if test -n "$gparts[1]"
        set_color $gold
        printf " ~> "
    end

    # Reference 
    set_color $terracotta
    printf $gparts[1]

    # Dirty/Staging indicator 
    set_color $gray
    printf "$gparts[2]"

    # Remote diverge indicator 
    set_color $bronze
    printf "$gparts[3]"

    echo
    set_color $orange
    printf "╰─🍁 "
    set_color normal
end

function fish_right_prompt
    set -l orange DC884C
    set -l orange DC884C
    set -l gold eec667
    set -l terracotta e06c75
    set -l bronze C98936
    set -l gray 6b737f

    set -l leaf_green 97BE5A
    set -l maple_red e64848
    set -l harvest 4A7096
    set -l sun f39c12
    # Move cursor up
    echo -e "\e[1A"

    set -l last_status (mist_info "%s")

    switch $last_status
        case 0
            set_color -o $leaf_green
            echo "•󰄬 "
            set_color normal
        case 127
            set_color -o $gold
            echo "•? "
            set_color normal
        case 1
            set_color -o $maple_red
            echo "•✗ "
            set_color normal
        case '*'
            set_color -o $maple_red
            echo "•✗ "
            set_color normal
            set_color -o $maple_red
            echo "[$last_status] "
            set_color normal
    end

    # Using the gray for a subtle date/time display
    set_color $gray
    mist_date "%H:%m "
    set_color normal

    switch (mist_date "%I")
        case PM
            set_color -o $harvest
            printf 󰖔
            set_color normal
        case AM
            set_color -o $sun
            printf 󰖨
            set_color normal
    end

    # Move cursor down
    echo -e "\e[1B"
end
