# @fish-lsp-disable 4004
function fish_prompt
    set -l orange DC884C
    set -l gold eec667
    set -l terracotta e06c75
    set -l bronze C98936
    set -l gray 6b737f

    set_color -o $orange
    mist_login "╭─(%s %u)"

    set -l pparts (mist_pwd -n " %s %t%p" %d)
    set_color $gold
    printf "$pparts[1]"

    set_color -o
    printf "$pparts[2]"

    set -l gparts (mist_git -n %R%r %C %A%B)

    if test -n "$gparts[1]"

        set_color $gold
        printf " ~> "
    end

    set_color $terracotta
    printf $gparts[1]

    set_color $gray
    printf "$gparts[2]"

    set_color $bronze
    printf "$gparts[3]"

    echo
    set_color $orange
    printf "╰─🍁 "
    set_color normal
end
