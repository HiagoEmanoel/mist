function fish_prompt
    set last_status $status
    #  
    # Cores de Fundo (Pastel)
    set color_icon f5a97f
    set color_user eed49f
    set color_pwd f0c6c6
    set color_git ee99a0
    set color_dark 181926
    set color_red ed8796
    set color_green a6da95

    # Segmento 1: Usuário
    set_color -b $color_user $color_dark
    set user_parts (mist_login -n "%s" " %u ")

    set_color normal
    set_color $color_icon
    printf ""

    set_color $color_dark -b $color_icon
    printf "$user_parts[1]"

    set_color $color_icon -b $color_user
    printf ""

    set_color $color_dark -b $color_user
    printf "$user_parts[2]"

    set_color -b $color_pwd $color_user
    printf ""

    # Segmento 2: PWD
    set_color -b $color_pwd $color_dark
    mist_pwd " %s %t%p%d "

    # Verifica se estamos em um repositório Git usando sua técnica de array
    set git_part (mist_git -n "%R%r%C %A%B")

    if test -n "$git_part"
        # Finaliza o Git com Meia Lua voltando para o terminal
        set_color -b $color_git $color_pwd
        printf ""
        set_color $color_dark
        printf "$git_part"
        set_color normal
        set_color $color_git
        printf ""
    else
        # Se não tem git, finaliza o PWD com Meia Lua
        set_color normal
        set_color $color_pwd
        printf ""
    end

    # Indicador de comandos na próxima linha
    echo
    if test $last_status -eq 0
        set_color $color_green
    else
        set_color $color_red
    end
    printf " ❯ "
    set_color normal
end
