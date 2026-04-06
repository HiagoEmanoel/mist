function fish_prompt
    set_color green
    echo -n (prompt_pwd)
    set_color cyan
    echo -n (format_git_prompt -f "[%R%r]")
    set_color normal
    echo -n " \$ "
end
