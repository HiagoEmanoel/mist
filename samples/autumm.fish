# @fish-lsp-disable 4004
function fish_prompt
    set orange fc9867
    set yellow ffd866
    set red ff6188
    set purple ab9df2
    set gray 5b595c
    set fg F2D98C

    set_color -o $orange
    mist_login "%u"

    set_color $fg
    printf " in "

    set pparts (mist_pwd -n "%s %t%p" %d)
    set_color $yellow
    printf "$pparts[1]"

    set_color -o
    printf "$pparts[2]"

    set gparts (mist_git -n %R%r %C %A%B)

    if test -n "$gparts[1]"
        set_color $fg
        printf " at "
    end

    set_color $red
    printf $gparts[1]

    set_color $gray
    printf "$gparts[2]"

    set_color $purple
    printf "$gparts[3]"

    echo
    printf "🍁 "
    set_color normal
end
