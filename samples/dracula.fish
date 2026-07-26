# @fish-lsp-disable 4004
function fish_prompt
    set -l bg_dark 282a36
    set -l purple bd93f9
    set -l pink ff79c6
    set -l cyan 8be9fd
    set -l green 50fa7b
    set -l comment 6272a4

    # Linha 1: Login + PWD + Git
    set_color $purple
    mist_login "┌──[%s %u@%h]"

    set_color $pink
    mist_pwd -p " in %t%p%d"

    set_color $cyan
    mist_git " on %R%r%C" "%A%B"

    echo
    # Linha 2: Símbolo do Prompt
    set_color $purple
    printf "└──❯ "
    set_color normal
end

function fish_right_prompt
    set -l comment 6272a4
    set -l red ff5555
    set -l green 50fa7b

    # Eleva o cursor para ficar na mesma linha de cima
    echo -e "\e[1A"

    # Tempo de execução (se > 500ms) e ícone de status
    set_color $comment
    mist_info -m 500 -s "✔ " -f "✘ 127 " -i "⚡ 2 " -e "✘ %c " "%s %t"

    echo -e "\e[1B"
    set_color normal
end
