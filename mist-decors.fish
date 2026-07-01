# @fish-lsp-disable 4004
if status is-interactive
    # Secondary widgets and decorative functions
    set -e __mist_clock_cache __mist_timezone

    function mist_date
        # format date
        set options h/help n/newline
        argparse $options -- $argv
        or return

        if set -q _flag_h
            printf "%b\n" \
                "Usage: \e[1;33mmist_date\e[0m [OPTIONS] [FORMAT]" \
                "" \
                "\e[1mOptions:\e[0m" \
                "  \e[33m-h, --help\e[0m     Show this help message" \
                "  \e[33m-n, --newline\e[0m  Print with newline" \
                "" \
                "\e[1mFormat Specifiers:\e[0m" \
                "  \e[32m%d\e[0m  Day (01-31)    \e[32m%H\e[0m  Hour (24h)" \
                "  \e[32m%w\e[0m  Weekday (Sun)  \e[32m%H\e[0m  Hour (12h)" \
                "  \e[32m%M\e[0m  Month (jan)    \e[32m%I\e[0m  AM/PM" \
                "  \e[32m%Y\e[0m  Full Year      \e[32m%m\e[0m  Minute " \
                "  \e[32m%Y\e[0m  Short Year     \e[32m%s\e[0m  Second" \
                "  \e[32m%%\e[0m  Just a %"
            return
        end

        # Set the default output
        test -n "$argv"
        and set output $argv
        or set output "%w %d/%M/%Y %H:%m:%s"

        set unix_timestamp (math (path mtime -R /proc) + 1)

        # Init the timezone and date
        if test -z "$__mist_clock_date" -o -z "$__mist_timezone"
            set date_out (string split ' ' (date "+%H %d %a %b %y %Y"))

            set -g __mist_clock_date $date_out[2..]

            set hour_now (math -s0 $unix_timestamp / 3600 % 24)
            set -g __mist_timezone (math \($date_out[1] - $hour_now\) x 3600)
        end

        set date $__mist_clock_date

        set local_ts (math $unix_timestamp + $__mist_timezone)

        # filter the specifiers and make then unique
        set specifiers (string match -rga -- '(?<!%)%([dwMyYHhIms])' $output)
        set specifiers (string match -rga -- '(\w)(?:\s*\1)*' (path sort $specifiers))

        for spec in $specifiers
            switch $spec
                case d
                    set val "$date[1]"
                case w
                    set val "$date[2]"
                case M
                    set val "$date[3]"
                case y
                    set val "$date[4]"
                case Y
                    set val "$date[5]"
                case H
                    set hour (math -s 0 $local_ts / 3600 % 24)
                    set val (printf "%02d" $hour)
                case h
                    set hour (math -s 0 $local_ts / 3600 % 24 % 12)
                    set val (printf "%02d" (math "$hour % 12"))
                case I
                    set hour (math -s 0 $local_ts / 3600 % 24)
                    test $hour -ge 12
                    and set val PM
                    or set val AM
                case m
                    set min (math -s 0 $local_ts / 60 % 60)
                    set val (printf "%02d" $min)
                case s
                    set sec (math "$local_ts % 60")
                    set val (printf "%02d" $sec)
            end
            set output (string replace -ra -- "(?<!%)%$spec" "$val" $output)
        end

        set output (string replace -ra -- '%(%+)' '$1' $output)

        set -q _flag_n
        and printf "%b\n" $output
        or printf "%b" "$output"
    end

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
