function fish_prompt
    set_color green
    echo -n (prompt_pwd)
    set git_prompt (format_git_prompt -f "[%R%r%D%S]" -f "%A%B")

    if test -n "$git_prompt[1]"
        set_color cyan
        echo -n "$git_prompt[1]"
        set_color normal
    end

    if test -n "$git_prompt[2]"
        set_color yellow
        echo -n " $git_prompt[2]"
        set_color normal
    end

    set_color normal
    echo -n " \$ "
end
