# @fish-lsp-disable 4004
function fish_prompt
    set -l pink f92672
    set -l green a6e22e
    set -l yellow e6db74
    set -l orange fd971f
    set -l purple ae81ff
    set -l cyan 66d9ef
    set -l gray 75715e

    # Usuário e Host
    set_color $green
    mist_login "%u"
    set_color $gray
    printf "@"
    set_color $cyan
    mist_login "%h "

    # Diretório
    set_color $yellow
    mist_pwd -p "%s %t%p%d"

    # Informações do Git
    set_color $pink
    mist_git " [%R%r%C]" "%A%B"

    # Prompt lambda
    echo
    set_color $purple
    printf "λ "
    set_color normal
end

function fish_right_prompt
    set -l gray 75715e
    set -l orange fd971f

    echo -e "\e[1A"

    # Duração do comando em destaque discreto e horário
    set_color $gray
    mist_info -m 1000 -s "" -e "[err:%c]" "%t %s"

    set_color $orange
    mist_date " %H:%m"

    echo -e "\e[1B"
    set_color normal
end
