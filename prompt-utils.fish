# @fish-lsp-disable 4004
if status is-interactive
    function format_git_prompt
        # genetate the git prompt
        test -z "$__git_prompt_items"; and return

        # save argv before be consumed by argparse
        set -l argv_bak "$argv"
        argparse h/help c/charset= f/format= D/dirty_char= -- $argv

        if set -q _flag_help
            # The help message defined above
            printf "%s\n" "Usage: format_git_prompt [OPTIONS]" \
                "" \
                "Options:" \
                "  -h, --help            Show this help message and exit" \
                "  -c, --charset=STR     Set symbols for git references" \
                "  -D, --dirty_char=C    Set the character for change indicator (default: \"+\")" \
                "  -f, --format=FORMAT   The format string to use (default: %R%r%S)" \
                "" \
                "Charset format:" \
                "  <commit> <branch> <remote> <tag> (default: @   󰓹)" \
                "" \
                "Format Specifiers:" \
                "  %R  Reference symbol" \
                "  %r  Reference name" \
                "  %h  Commit hash" \
                "  %D  dirty character"
            return
        end

        # uses cached prompt if nothing changes
        if test "$__git_prompt_cache[1]" = "$__git_prompt_items $argv_bak"
            echo $__git_prompt_cache[2]
            return
        end

        set -l reftype $__git_prompt_items[1]
        set -l refname $__git_prompt_items[2]
        set -l dirty_status clean

        # set the staging character
        set -l dirty_char
        if test $dirty_status = dirty
            if set -q _flag_dirty_char
                set -- dirty_char "$_flag_dirty_char"
            else
                set -- dirty_char '+'
            end
        end

        # defines the symbol for git reference
        set -l ref_charset @   󰓹

        if set -q _flag_charset
            set -- ref_charset (string split ' ' -- $_flag_charset)
        end

        set -l refchar ''
        set -l refchar_index (contains -i $reftype commit branch remote tag)

        if test -n "$refchar_index"
            set -- refchar $ref_charset[$refchar_index]
        end

        # defines th output format
        set -l output_format "%R%r%D"

        set -q _flag_format; and set -- output_format $_flag_format
        set -l output $output_format

        set output (string replace -- '%R' "$refchar" $output)
        set output (string replace -- '%r' "$refname" $output)
        set output (string replace -- '%D' "$dirty_char" $output)

        set -g __git_prompt_cache "$__git_prompt_items $argv_bak" "$output"

        echo -e $output
    end
end
