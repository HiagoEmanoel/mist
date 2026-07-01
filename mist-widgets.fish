# @fish-lsp-disable 4004
if status is-interactive

    # clear all caches
    set -e __mist_pwd_cache __mist_clock_cache __mist_git_ref_date __mist_git_status_cache __mist_timezone

    function mist_date
        # format date
        set options h/help n/newline
        argparse $options -- $argv
        or return

        # 3. Help (Seguindo o estilo visual das outras widgets)
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

    function mist_git
        # format git information
        set argv_all "$argv"

        set options h/help b/branch= c/commit r/remote t/tag d/dirty= s/staging= a/ahead= i/behind= n/newline D/debug
        argparse $options -- $argv
        or return

        if set -q _flag_D
            set -e __mist_git_prompt_cache
        end

        # Cache processing
        if test "$__mist_git_prompt_cache[1]" = "$__mist_git_ref$__mist_git_status$argv_all"
            test -z "$__mist_git_wt"
            and return

            set output $__mist_git_prompt_cache[2..]

            set -q _flag_n
            and printf "%b\n" $output
            or printf "%b" "$output"
            return
        end

        if set -q _flag_help
            printf "%b\n" \
                "Usage: \e[1;33mmist_git\e[0m [OPTIONS] [FORMAT]..." \
                "" \
                "Prints git status information. If multiple formats are given, returns an array." \
                "" \
                "\e[1mOptions:\e[0m" \
                "  \e[33m-h, --help\e[0m         Show this help message and exit" \
                "  \e[33m-b, --branch=STR\e[0m   Branch symbol  (default: \"\")" \
                "  \e[33m-c, --commit=STR\e[0m   Commit symbol  (default: \"@\")" \
                "  \e[33m-r, --remote=STR\e[0m   Remote symbol  (default: \"\")" \
                "  \e[33m-t, --tag=STR\e[0m      Tag symbol     (default: \"󰓹\")" \
                "  \e[33m-d, --dirty=STR\e[0m    Dirty symbol   (default: \"+\")" \
                "  \e[33m-s, --staging=STR\e[0m  Staging symbol (default: \"*\")" \
                "  \e[33m-a, --ahead=STR\e[0m    Ahead symbol   (default: \"↑\")" \
                "  \e[33m-i, --behind=STR\e[0m   Behind symbol  (default: \"↓\")" \
                "  \e[33m-n, --newline\e[0m      Print each format argument on a new line" \
                "" \
                "\e[1mFormat Specifiers:\e[0m" \
                "  \e[32m%R\e[0m  Reference symbol (branch/tag/commit/remote)" \
                "  \e[32m%r\e[0m  Reference name (e.g., 'main' or 'v1.0')" \
                "  \e[32m%h\e[0m  Short commit hash" \
                "  \e[32m%t\e[0m  Type of the current reference" \
                "  \e[32m%a\e[0m  Number of commits ahead of remote" \
                "  \e[32m%b\e[0m  Number of commits behind remote" \
                "  \e[32m%A\e[0m  Symbol for 'ahead' (only shows if %a > 0)" \
                "  \e[32m%B\e[0m  Symbol for 'behind' (only shows if %b > 0)" \
                "  \e[32m%D\e[0m  Dirty symbol (shows if there are unstaged changes)" \
                "  \e[32m%S\e[0m  Staging symbol (shows if there are staged changes)" \
                "  \e[32m%C\e[0m  Smart Change: uses \e[3mStaging\e[0m symbol if everything is staged," \
                "      otherwise uses the \e[3mDirty\e[0m symbol." \
                "  \e[32m%%\e[0m  Escape character: prevents the next character from being" \
                "      interpreted (e.g., \e[36m%%A\e[0m outputs a literal \e[36m%A\e[0m)" \
                "" \
                "\e[1mExample:\e[0m" \
                "  \e[32m\$\e[0m mist_git \"%R%r\" \"State: %C\"" \
                "\e[1mOutput:\e[0m" \
                "  main state: +" \
                "\e[1mDefault:\e[0m \"[%R%r%C] %A%B\""
            return
        end

        test -z "$__mist_git_ref" -o -z "$__mist_git_status"; and return

        if test -n "$argv"
            set output $argv
        else
            set output '[%R%r%C]' '%A%B'
        end

        set ref_data $__mist_git_ref
        set reftype $ref_data[1]
        set refname $ref_data[2]
        set refhash $ref_data[3]

        set status_data $__mist_git_status
        set is_dirty $status_data[1]
        set is_staging $status_data[2]

        set ahead $status_data[3]
        set behind $status_data[4]

        if set -q _flag_D
            echo "ref_data: $ref_data" >&2
            echo "reftype: $reftype" >&2
            echo "refname: $refname" >&2
            echo "refhash: $refhash" >&2

            echo "status_data: $status_data" >&2
            echo "is_dirty: $is_dirty" >&2
            echo "is_staging: $is_staging" >&2

            echo "ahead: $ahead" >&2
            echo "behind: $behind" >&2
        end

        if string match -rq '(?<!%)%C' $output
            test "$is_dirty" = false -a "$is_staging" = true
            and set choiced_ind '%S'
            or set choiced_ind '%D'
            set output (string replace -ra -- '(?<!%)%C' "$choiced_ind" $output)
        end

        set output_bak $output

        # Replace every specifier in output
        set specifiers (string match -rga -- '(?<!%)%([RrhtabABDS])' $output)
        set specifiers (string match -rga -- '(\w)(?:\s*\1)*' (path sort $specifiers))
        for spec in $specifiers
            set val
            switch $spec
                case R
                    set charset_default    󰓹
                    set input_charset "$__flag_help" "$__flag_branch" "$__flag_commit" "$__flag_remote" "$__flag_tag"

                    set refchar
                    set char_index (contains -i -- $reftype commit branch remote tag)

                    if test -n "$input_charset[$char_index]"
                        set refchar $input_charset[$char_index]
                    else
                        set refchar $charset_default[$char_index]
                    end

                    set val "$refchar"
                case r
                    set val "$refname"
                case h
                    set val "$refhash"
                case t
                    set val "$reftype"
                case a
                    set val "$ahead_num"
                case b
                    set val "$behind"
                case A
                    set ahead_ind
                    if test $ahead -gt 0
                        set -q _flag_ahead
                        and set ahead_ind $_flag_ahead
                        or set ahead_ind '↑'
                        set val "$ahead_ind"
                    end
                case B
                    set behind_ind
                    if test $behind -gt 0
                        set -q _flag_behind
                        and set behind_ind $_flag_behind
                        or set behind_ind '↓'
                        set val "$behind_ind"
                    end
                case D
                    if test "$is_dirty" = true -o "$is_staging" = true
                        set -q _flag_dirty
                        and set dirty_indicator $_flag_dirty
                        or set dirty_indicator '+'
                        set val "$dirty_indicator"
                    end
                case S
                    if test "$is_staging" = true
                        set -q _flag_staging
                        and set staging_indicator $_flag_staging
                        or set staging_indicator '*'
                        set val "$saging_indicator"
                    end
            end
            set output (string replace -ra -- "(?<!%)%$spec" "$val" $output)
        end

        # clean blocks with only empty keys
        set count 1
        for block in $output
            if test "$block" = "$output_bak[$count]"
                set output[$count] ''
            end
            set count (math $count + 1)
        end

        # Process non-replaced specifiers and scapes
        set output (string replace -ra -- '(?<!%)%([RrhtabABDS])' '' $output)
        set output (string replace -ra -- '%(%+)' '$1' $output)

        set -g __mist_git_prompt_cache "$ref_data$status_data$argv_all" $output

        set -q _flag_n
        and printf "%b\n" $output
        or printf "%b" "$output"
    end

    function mist_pwd
        set argv_all "$argv"
        set options h/help H/homesym F/foldersym s/separator= T/no-tilde m/max-size= n/newline
        argparse $options -- $argv
        or return

        if set -q _flag_h
            printf "%b\n" \
                "\e[1mUsage:\e[0m \e[1;33mmist_pwd\e[0m [OPTIONS] [FORMAT] ..." \
                "" \
                "\e[1mOptions:\e[0m" \
                "  \e[33m-h, --help\e[0m       Show this help message and exit" \
                "  \e[33m-H, --homesym\e[0m    Symbol for home folder (default: \"󰋜\")" \
                "  \e[33m-F, --foldersym\e[0m  Symbol for generic folders (default: \"\")" \
                "  \e[33m-s, --separator\e[0m  Symbol for directory separation (default: \"/\")" \
                "  \e[33m-T, --no-tilde\e[0m   Show full home path instead of '~'" \
                "  \e[33m-m, --max-size\e[0m   Max length of the path before shortening (default: 50)" \
                "  \e[33m-n, --newline\e[0m    Print each output on a new line" \
                "" \
                "\e[1mFormat Specifiers:\e[0m" \
                "  \e[32m%S\e[0m  Context symbol (Home / Generic)" \
                "  \e[32m%t\e[0m  The home name or tilde (~)" \
                "  \e[32m%p\e[0m  Parent path (relative to home if applicable)" \
                "  \e[32m%d\e[0m  Current directory name" \
                "" \
                "\e[1mExamples:\e[0m" \
                "  \$ mist_pwd \"%S %t%p%d\"                   \e[0m# Standard look\e[0m" \
                "  ~/mist/tools" \
                "  \$ mist_pwd -s \" > \" \"%p\e[32m%d\e[0m\"               \e[0m# Arrow separated path\e[0m" \
                "  > mist > tools"
            return
        end

        # Cache
        if test "$__mist_pwd_cache[1]" = "$PWD$argv_all" -a -n "$__mist_pwd_cache"
            set output $__mist_pwd_cache[2..]

            set -q _flag_n
            and printf "%b\n" $output
            or printf "%b" "$output"

            return
        end

        set homesym "󰋜"
        set -q _flag_H
        and set homesym $_flag_H

        set -q _flag_F
        and set foldersym $_flag_F
        or set foldersym "󰝰"

        set -q _flag_s
        and set separator $_flag_s
        or set separator /

        set dirname (path basename $PWD)
        if set -q _flag_m
            set maxsize_total $_flag_m
            set maxsize (math $maxsize_total - (string length "$dirname"))
            test $maxsize -lt 0
            and set maxsize 0
        else
            set maxsize_total 30
            set maxsize (math $maxsize_total - (string length "$dirname"))
            test $maxsize -lt 0
            and set maxsize 0
        end

        set -q _flag_T
        and set tilde (path basename "$HOME")
        or set tilde '~'

        # Default prompt
        test -n "$argv"
        and set output $argv
        or set output %S %t%p%d

        set homepath (string escape --style=regex -- "$HOME")

        if test "$HOME" = "$PWD"
            set symbol "$homesym"

            set dirname
            set dirpath

        else if string match -rq "^$homepath/" "$PWD"
            # Triggers if the pwd is ahead home
            set symbol "$foldersym"
            set dirpath (string match -rg  -- "^$homepath(.*?)[^/]*\$" "$PWD")

            # Shorts the dirpath
            set cutpath (string sub -s -$maxsize -- (string replace -- / "$separator" "$dirpath"))
            set maxdirs (count (string match -ra -- (string escape --style=regex -- "$separator") "$cutpath"))

            if test "$maxdirs" = 0
                if test "$dirpath" != /
                    set dirpath /…/
                end
                set dirname (string shorten -l -m $maxsize_total (path basename $PWD))
                set dirpath (string replace -r -- "(^/)?.+((?:/[^/]+){$maxdirs}/\$)" '$1…$2' "$dirpath")
            end
        else
            set tilde
            set symbol "$foldersym"
            # Shorts the dirpath
            set dirpath (path dirname "$PWD")

            set cutpath (string sub -s -$maxsize -- (string replace -- / "$separator" "$dirpath"))
            set maxdirs (count (string match -ra -- (string escape --style=regex -- "$separator") "$cutpath"))

            if test "$maxdirs" = 0
                set dirpath …/
                set dirname (string shorten -l -m $maxsize_total (path basename $PWD))
            else
                set dirpath (string replace -r -- ".+((?:/[^/]+){$maxdirs}\$)" '…$1' "$dirpath")/
            end
        end

        set dirpath (string replace -a -- / "$separator" $dirpath)

        set output (string replace -a -- "%S" "$symbol" $output)
        set output (string replace -a -- "%p" "$dirpath" $output)
        set output (string replace -a -- "%d" "$dirname" $output)
        set output (string replace -a -- "%t" "$tilde" $output)

        set -g __mist_pwd_cache "$PWD$argv_all" $output

        set -q _flag_n
        and printf "%b\n" $output
        or printf "%b" "$output"
    end
end
