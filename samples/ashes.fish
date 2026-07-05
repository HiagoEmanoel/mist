# @fish-lsp-disable 4004
function fish_prompt
    set_color brblack
    printf "\e[2J"
    mist_line .
    set_color green
    mist_login "%s %u "
    set_color blue -d
    mist_pwd "%s %t%p"
    set_color -o
    mist_pwd "%d "
    set_color brblack
    mist_git "%R%r%C "
    set_color green
    printf "\n> "
    set_color normal
end
