# @fish-lsp-disable 4004
if status is-interactive
    set -g __mist_timezone 0

    function format_date
        argparse h/help -- $argv
        if set -q _flag_h
            printf "%s\n" \
                "Usage: format_date [FORMAT]" \
                "" \
                "A simple utilitarie for date output for fish prompt" \
                "Format is one or more strings that defines the output" \
                "Format Specifiers:" \
                "  %w  Weekday name (e.g., Sun)" \
                "  %d  Day of the month (01-31)" \
                "  %M  Month number (01-12)" \
                "  %N  Month name (e.g., Apr)" \
                "  %Y  Full year " \
                "  %y  Short year (the last two numbers)" \
                "  %h  Hour (00-12)" \
                "  %H  Hour (00-24)" \
                "  %m  Minute" \
                "  %s  Second"
            return
        end

        # Howard Hinnant algorithm implementation
        set unix_timestamp (math (path mtime -R /proc) + 1)
        set local_timestamp (math $unix_timestamp - $__mist_timezone x 3600 )
        set z_days (math -s 0 -m floor $local_timestamp / 86400 + 719468)

        set era (math -s 0 $z_days / 146097)
        set doe (math $z_days % 146097)
        set yoe (math -s 0 \( $doe - $doe / 1460 + $doe / 36524 - $doe / 146096 \) / 365)
        set year (math $yoe + $era x 400)

        set doy (math $doe - \( 365 x $yoe + floor\($yoe / 4\) - floor\($yoe / 100\) \))

        set month (math -s 0 \( 5 x $doy + 2\) / 153)
        set day (math -s 0 -m ceil $doy - \( 153 x $month + 2\) / 5 + 1)

        set month_list mar apr may jun jul aug sep oct nov dec jan feb
        set month_name $month_list[(math $month + 1)]
        set month_number
        if test $month -gt 9
            set mount_number (math $month - 9)
        else
            set month_number (math $month + 3)
        end

        set week_num (math $z_days % 7)
        set week_list Wed Thu Fri Sat Sun Mon Tue
        set week_day $week_list[(math $week_num + 1)]

        set hour (math -s 0 $local_timestamp / 3600 % 24)
        set second_hour (math $hour % 12)

        set minutes (math -s 0 $local_timestamp / 60 % 60)
        set seconds (math $local_timestamp % 60)

        set output_format "%w %d/%M/%Y %H:%m:%s"
        if test -n "$argv"
            set output_format $argv[1..]
        end

        set output $output_format

        set short_year (string sub -s 3 $year)

        set output (string replace -a -- "%w" "$week_day" $output)
        set output (string replace -a -- "%H" "$hour" $output)
        set output (string replace -a -- "%h" "$second_hour" $output)
        set output (string replace -a -- "%m" "$minutes" $output)
        set output (string replace -a -- "%s" "$seconds" $output)
        set output (string replace -a -- "%d" "$day" $output)
        set output (string replace -a -- "%M" "$month_number" $output)
        set output (string replace -a -- "%N" "$month_name" $output)
        set output (string replace -a -- "%y" "$short_year" $output)
        set output (string replace -a -- "%Y" "$year" $output)

        printf "%s\n" $output
    end

    set -g __mist_timezone (math (format_date "%H") - (date +%H))

    function format_git_prompt
        set argv_bak "$argv"
        argparse h/help c/charset= f/format=+ d/dirty= s/staging= a/ahead= b/behind= -- $argv

        if set -q _flag_help
            printf "%s\n" "Usage: format_git_prompt [OPTIONS]" \
                "" \
                "Options:" \
                "  -h, --help            Show this help message and exit" \
                "  -c, --charset=STR     Set symbols for git references" \
                "  -d, --dirty=STR       Set the symbol for change indicator (default: \"+\")" \
                "  -s  --staging=STR     Set the symbol for staging indicator (default: \"*\")" \
                "  -a  --ahead=STR       Set the symbol for ahead indicator (default: \"↑\")" \
                "  -b  --behind=STR      Set the symbol for behind indicator (default: \"↓\")" \
                "  -f, --format=FORMAT   The format string to use, (default: %R%r%S)" \
                "                        format can be specified multiple times" \
                "                        in this case, a array will be returned" \
                "" \
                "Charset format:" \
                "  <commit> <branch> <remote> <tag> (default: \"@   󰓹\")" \
                "" \
                "Format Specifiers:" \
                "  %R  Reference symbol" \
                "  %r  Reference name" \
                "  %h  Commit hash" \
                "  %D  dirty symbol" \
                "  %S  staging symbol" \
                "  %a  ahead number" \
                "  %b  behind number" \
                "  %A  ahead symbol" \
                "  %B  behind symbol"
            return
        end

        if test -z "$__mist_git_worktree"
            return
        end

        # uses cached prompt if nothing changes
        if test "$__mist_git_prompt_cache[1]" = "$__mist_git_reference$__mist_git_status$argv_bak"
            printf "%s\n" $__mist_git_prompt_cache[2..]
            return
        end

        set output_format "%R%r%D%%SA%B"
        set -q _flag_format; and set output_format $_flag_format
        set output $output_format

        set reftype $__mist_git_reference[1]
        set refname $__mist_git_reference[2]
        set refhash $__mist_git_reference[3]

        set is_dirty $__mist_git_status[1]
        set is_staging $__mist_git_status[2]

        set ahead $__mist_git_status[3]
        set behind $__mist_git_status[4]

        set dirty_indicator
        set staging_indicator

        if test "$is_dirty" = true
            set -q _flag_dirty
            and set dirty_indicator $_flag_dirty
            or set dirty_indicator '+'
        end

        if test "$is_staging" = true
            set -q _flag_staging
            and set staging_indicator $_flag_staging
            or set staging_indicator '*'
        end

        set ahead_number
        set behind_number
        set ahead_indicator
        set behind_indicator

        if test $ahead -gt 0
            set ahead_number $ahead
            set -q _flag_ahead
            and set ahead_indicator $_flag_ahead
            or set ahead_indicator '↑'
        end

        if test $behind -gt 0
            set behind_number $behind
            set -q _flag_behind
            and set behind_indicator $_flag_behind
            or set behind_indicator '↓'
        end

        set charset @   󰓹

        if set -q _flag_charset
            set chars (string split ' ' $_flag_charset)
            set char_count (count $chars)
            set charset[..$char_count] $chars
        end

        set refchar
        set char_index (contains -i $reftype commit branch remote tag)
        if test -n "$char_index"
            set refchar $charset[$char_index]
        end

        set output (string replace "%R" "$refchar" $output)
        set output (string replace "%r" "$refname" $output)
        set output (string replace "%h" "$refhash" $output)
        set output (string replace "%D" "$dirty_indicator" $output)
        set output (string replace "%S" "$staging_indicator" $output)
        set output (string replace "%a" "$ahead_number" $output)
        set output (string replace "%b" "$behind_number" $output)
        set output (string replace "%A" "$ahead_indicator" $output)
        set output (string replace "%B" "$behind_indicator" $output)

        set -g __mist_git_prompt_cache "$__mist_git_reference$__mist_git_status$argv_bak" $output
        printf "%s\n" $output
    end
end
