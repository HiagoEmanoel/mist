# @fish-lsp-disable 4004
if status is-interactive
    set -e __mist_clock_cache __mist_timezone

    function mist_info
        set -l options h/help n/newline m/min-time= s/success= f/not-found= i/incorrect= e/error=
        argparse $options -- $argv
        or return

        if set -q _flag_h
            printf "%b\n" \
                "Usage: \e[1;33mmist_info\e[0m [OPTIONS] [FORMAT]" \
                "" \
                "\e[1mOptions:\e[0m" \
                "  \e[33m-h, --help\e[0m           Show this help message" \
                "  \e[33m-n, --newline\e[0m        Print with newline" \
                "  \e[33m-m, --min-time=MS\e[0m    Min execution time in ms to show %t (default: 0)" \
                "  \e[33m-s, --success=STR\e[0m    Format for status 0 (default: \"0\")" \
                "  \e[33m-f, --not-found=STR\e[0m  Format for command not found 127 (default: \"127\")" \
                "  \e[33m-i, --incorrect=STR\e[0m  Format for incorrect usage 2 (default: \"2\")" \
                "  \e[33m-e, --error=STR\e[0m      Format for generic error (default: status code)" \
                "" \
                "\e[1mFormat Specifiers:\e[0m" \
                "  \e[32m%s\e[0m  Status string or symbol" \
                "  \e[32m%c\e[0m  Raw numeric status code" \
                "  \e[32m%t\e[0m  Formatted command execution time" \
                "  \e[32m%%\e[0m  Just a %"
            return
        end

        set -l last_status "$__mist_info_data[1]"
        set -l cmd_duration "$__mist_info_data[2]"

        test -z "$last_status"
        and set last_status 0

        test -z "$cmd_duration"
        and set cmd_duration 0

        # Status formatting
        set -l status_str
        switch $last_status
            case 0
                set -q _flag_s
                and set status_str $_flag_s
                or set status_str "✔"
            case 127
                set -q _flag_f
                and set status_str $_flag_f
                or set status_str "?"
            case 2
                set -q _flag_i
                and set status_str $_flag_i
                or set status_str "✘"
            case '*'
                set -q _flag_e
                and set status_str $_flag_e
                or set status_str "✘ $last_status"
        end

        # Duration formatting (builtins only)
        set -l min_time 0
        set -q _flag_m
        and set min_time $_flag_m

        set -l time_str ""
        if test $cmd_duration -ge $min_time -a $cmd_duration -gt 0
            if test $cmd_duration -lt 1000
                set time_str {$cmd_duration}ms
            else if test $cmd_duration -lt 60000
                set -l sec (math -s1 "$cmd_duration / 1000")
                set time_str {$sec}s
            else
                set -l min (math -s0 "$cmd_duration / 60000")
                set -l rem_ms (math "$cmd_duration % 60000")
                set -l sec (math -s0 "$rem_ms / 1000")
                set time_str {$min}m{$sec}s
            end
        end

        set -l output
        if test -n "$argv"
            set output $argv
        else
            set output "%s %t"
        end

        set output (string replace -ra -- "(?<!%)%s" "$status_str" $output)
        set output (string replace -ra -- "(?<!%)%c" "$last_status" $output)
        set output (string replace -ra -- "(?<!%)%t" "$time_str" $output)
        set output (string replace -ra -- '%(%+)' '$1' $output)

        set output (string trim -- "$output")

        set -q _flag_n
        and printf "%b\n" "$output"
        or printf "%b" "$output"
    end

    function mist_date
        set -l options h/help n/newline
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

        test -n "$argv"
        and set -f output $argv
        or set -f output "%w %d/%M/%Y %H:%m:%s"

        set -f unix_timestamp (math (path mtime -R /proc) + 1)

        if test -z "$__mist_clock_date" -o -z "$__mist_timezone"
            set -l date_out (string split ' ' (date "+%H %d %a %b %y %Y"))

            set -g __mist_clock_date $date_out[2..]

            set -l hour_now (math -s0 $unix_timestamp / 3600 % 24)
            set -g __mist_timezone (math \($date_out[1] - $hour_now\) x 3600)
        end

        set -f date $__mist_clock_date
        set -f local_ts (math $unix_timestamp + $__mist_timezone)

        set -f specifiers (string match -rga -- '(?<!%)%([dwMyYHhIms])' $output)
        set specifiers (string match -rga -- '(\w)(?:\s*\1)*' (path sort $specifiers))

        for spec in $specifiers
            set -l val
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
                    set -l hour (math -s 0 $local_ts / 3600 % 24)
                    set val (printf "%02d" $hour)
                case h
                    set -l hour (math -s 0 $local_ts / 3600 % 24 % 12)
                    set val (printf "%02d" (math "$hour % 12"))
                case I
                    set -l hour (math -s 0 $local_ts / 3600 % 24)
                    test $hour -ge 12
                    and set val PM
                    or set val AM
                case m
                    set -l min (math -s 0 $local_ts / 60 % 60)
                    set val (printf "%02d" $min)
                case s
                    set -l sec (math "$local_ts % 60")
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
        set -l options h/help p/pad= s/size= a/aling= n/newline
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

        set -f char "$argv"
        test -z "$char"
        and return

        set -f charsize (string length -- "$char")

        set -f size
        test -n "$_flag_s" -a "$_flag_s" -lt 100
        and set size $_flag_s
        or set size 100

        set -f pad
        set -q _flag_p
        and set pad $_flag_p
        or set pad 0

        set -f charcount (math -s0 $COLUMNS / \($charsize + $pad\) x $size / 100)
        set -f linebuff (string repeat -n $charcount -- "$char"\n)

        set -f padstr (string repeat -n $pad -- ' ')
        set -f finaline (string join "$padstr" -- $linebuff)

        set -f aling
        set -q _flag_a
        and set aling $_flag_a
        or set aling left

        printf "\e[s"

        switch (string sub -l 1 -- $aling)
            case c
                set -l linesize (string length -- "$finaline")
                set -l start (math -s0 -- \($COLUMNS - $linesize\) / 2)
                printf "\e[%dG" $start
            case r
                set -l linesize (string length -- "$finaline")
                set -l start (math -s0 \($COLUMNS - $linesize\))
                printf "\e[%dG" $start
            case l
                printf "\e[0G"
            case '*'
                echo Unknow aling: "$aling"
                return
        end

        printf "%s\r\e[u" $finaline

        if set -q _flag_n
            printf "\n"
        end
    end
end
