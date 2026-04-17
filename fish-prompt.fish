# @fish-lsp-disable 4004
if status is-interactive

    functions -e fish_prompt fish_right_prompt
    # Sonokai pallet
    # bg0    = 2c2e34
    # bg1    = 33353f
    # bg2    = 363944
    # bg3    = 3b3e48
    # bg4    = 414550
    # bg5    = 444852
    # red    = fc5d7c
    # orange = f39660
    # yellow = e7c664
    # green  = 9ed072
    # cyan   = 8dd0b6
    # blue   = 76cce0
    # purple = b39df3
    # grey   = 7f8490
    function fish_prompt
        set -a parts (mist_git -n ' %R%r%C' ' %A%B')
        set_color 414550
        # mist_line -s 60 .
        echo -ne "╭─ "

        set_color b39df3 -o
        mist_pwd

        set_color normal
        set_color e7c664
        echo -n $parts[1]

        if test -n "$parts[2]"
            test (string length $parts[2]) = 2
            and set_color f39660
            or set_color fc5d7c
            echo -n $parts[2]
        end

        echo
        set_color 414550
        echo -n '╰─❯ '
        set_color normal
    end
end

# function fish_right_prompt
#     printf "\e[s"
#     printf "\e[1A"
#     set_color 8dd0b6
#     mist_date
#     printf "\e[u"
#     set_color normal
# end
