# @fish-lsp-disable 4004
function fish_prompt
    # Zenburn-like style 
    set -l zen_gray 5f5f5f
    set -l zen_green 7f9f7f
    set -l zen_cyan 93e0e3
    set -l zen_white dcdccc
    set -l zen_red cc9393
    set -l zen_yellow e0cf9f

    # Linha decorativa
    set_color $zen_gray
    mist_line .

    # User e login
    set_color $zen_green
    mist_login "%s %u "

    # Diretório e nome da pasta atual
    set_color $zen_cyan -d
    mist_pwd -p "%s %t%p"

    set_color -o $zen_white
    mist_pwd "%d "

    # Status Git
    set_color $zen_red
    mist_git "%R%r%C %A%B"

    # Status de erro/tempo do comando anterior se demorou mais de 1s
    set_color $zen_yellow
    mist_info -m 1000 -s "" -e " [%c]" " %t%s"

    # Símbolo do prompt
    set_color $zen_green
    printf "\n> "

    set_color normal
end
