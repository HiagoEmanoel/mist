# @fish-lsp-disable 4004
if status is-interactive
    function mist_line
        # Print a line of the given string
        set options h/help p/pad= s/size= a/aling= n/newline
        argparse $options -- $argv

        or return

        if set -q _flag_h
            printf "%b\n" \
                "Usage: \e[1;33mmist_line\e[0m [OPTIONS] [CHAR]" \
                "" \
                "Prints a decorative line using the given character" \
                "and returns to the start of the line, allowing overwriting" \
                "OBS: Line wrap may cause visual glitches" \
                "" \
                "\e[1mOptions:\e[0m" \
                "  \e[33m-h\e[0m, \e[33m--help\e[0m     Show this help message and exit" \
                "  \e[33m-p\e[0m, \e[33m--pad\e[0m      Space between characters (default: 0)" \
                "  \e[33m-s\e[0m, \e[33m--size\e[0m     Screen relative size in % (1-100, default: 100)" \
                "  \e[33m-a\e[0m, \e[33m--align\e[0m    Alignment: \e[36ml/left\e[0m, \e[36mc/center\e[0m, \e[36mr/right\e[0m" \
                "  \e[33m-n\e[0m, \e[33m--newline\e[0m  Print newline instead of returning to first column" \
                "" \
                "\e[1mExample:\e[0m" \
                "  \e[32m\$\e[0m mist_line -p 1 -a right -s 50 -" \
                "  \e[32m\$\e[0m other things..." \
                "\e[1mOutput:\e[0m"
            set_color cyan
            mist_line -p 1 -a right -s 50 -
            set_color brmagenta
            echo -n $USER
            set_color normal
            echo -n "@$hostname "
            set_color green
            prompt_pwd
            set_color normal
            echo '❯ '
            return
        end

        set char "$argv"
        test -z "$char"
        and return

        set charsize (string length -- "$char")

        test -n "$_flag_s" -a "$_flag_s" -lt 100
        and set size $_flag_s
        or set size 100

        set -q _flag_p
        and set pad $_flag_p
        or set pad 0

        # Calculate the number of repeats to match size
        set charcount (math -s0 $COLUMNS / \($charsize + $pad\) x $size / 100)
        set linebuff (string repeat -n $charcount -- "$char"\n)

        set padstr (string repeat -n $pad -- ' ')

        set finaline (string join "$padstr" -- $linebuff)

        # Fix alingnment
        set -q _flag_a
        and set aling $_flag_a
        or set aling left

        switch (string sub -l 1 -- $aling)
            case c
                set linesize (string length -- "$finaline")
                set start (math -s0 -- \($COLUMNS - $linesize\) / 2)
                printf "\e[%dG" $start
            case r
                set linesize (string length -- "$finaline")
                set start (math -s0 \($COLUMNS - $linesize\))
                printf "\e[%dG" $start
            case l
                printf "\e[0G"
            case '*'
                echo Unknow aling: "$aling"
                return
        end

        printf "%s" $finaline

        # Return to beginner of the line
        set -q _flag_n
        and printf "\n"
        or printf "\r"
    end
end
