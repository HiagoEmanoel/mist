# @fish-lsp-disable 4004
function fish_prompt
    set -l blue 7aa2f7
    set -l cyan 7dcfff
    set -l magenta bb9af7
    set -l green 9ece6a
    set -l red f7768e
    set -l comment 565f89

    # Linha 1: Contexto completo (Login, Path, Git)
    set_color $magenta
    mist_login "╭─ %s %u "

    set_color $cyan
    mist_pwd -p " %t%p%d"

    set_color $blue
    mist_git "  %r%C" "%A%B"

    echo
    # Linha 2: Indicador dinâmico de status do comando
    set_color $magenta
    printf "╰─"

    # Cor dinâmica para a seta dependendo do sucesso/erro do comando
    set -l status_code (mist_info "%c")
    if test "$status_code" = 0
        set_color $green
    else
        set_color $red
    end

    printf " ❯ "
    set_color normal
end

function fish_right_prompt
    set -l comment 565f89
    set -l cyan 7dcfff

    echo -e "\e[1A"

    # Tempo de execução elegante + relógio estético
    set_color $comment
    mist_info -m 1000 "%t "

    set_color $cyan
    mist_date "󰥔 %H:%m:%s"

    echo -e "\e[1B"
    set_color normal
end
