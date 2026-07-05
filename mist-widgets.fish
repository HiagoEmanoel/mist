# @fish-lsp-disable 4004 2003
if status is-interactive
    # The main mist widgets
    set -e __mist_pwd_cache __mist_git_ref_date __mist_git_status_cache __mist_login_cache

    function mist_login
        # Generates a login string
        set -l options h/help n/newline
        argparse $options -- $argv
        or return

        if set -q _flag_h
            printf "%b\n" \
                "Usage: \e[1;33mmist_login\e[0m [OPTIONS] [FORMAT]" \
                "" \
                "\e[1mOptions:\e[0m" \
                "  \e[33m-h, --help\e[0m     Show this help message" \
                "  \e[33m-n, --newline\e[0m  Print with newline" \
                "" \
                "\e[1mFormat Specifiers:\e[0m" \
                "  \e[32m%u\e[0m  User name" \
                "  \e[32m%h\e[0m  Hostname" \
                "  \e[32m%s\e[0m  The distro symbol" \
                "  \e[32m%%\e[0m  Just a %"
            return
        end

        if test "@$argv$argv_opts" = "$__mist_login_cache[1]" -a -n "$__mist_login_cache[2]"
            set -l output $__mist_login_cache[2..]

            set -q _flag_n
            and printf "%b\n" $output
            or printf "%b" "$output"

            return
        end

        # Set -l the default output
        set -l output
        test -n "$argv"
        and set output $argv
        or set output "[%s] %h@%u"

        set output (string replace -ra -- "(?<!%)%h" "$hostname" $output)
        set output (string replace -ra -- "(?<!%)%u" "$USER" $output)
        set output (string replace -ra -- "(?<!%)%s" "$__mist_login_distrosym" $output)

        set output (string replace -ra -- '%(%+)' '$1' $output)

        set -g __mist_login_cache "@$argv$argv_opts" $output

        set -q _flag_n
        and printf "%b\n" $output
        or printf "%b" "$output"
    end

    # Find the symbol of the distro
    if test -z "$__mist_login_distrosym"
        set -f raw_list \
            "
        alpine               
        amazon               
        android              
        arch                 
        artix                
        centos               
        debian               
        deepin               
        devuan               
        elementary           
        endeavouros          
        endless              
        fedora               
        freebsd              
        gentoo               
        guix                 
        kali                 
        linuxmint            
        mageia               
        magpie               
        manjaro              
        nixos                
        openbsd              
        opensuse             
        opensuse-leap        
        opensuse-tumbleweed  
        parrot               
        parabola             
        pop                  
        puresos              
        raspbian             
        rhel                 
        rocky                
        sabayon              
        slackware            
        solus                
        ubuntu               
        void                 
        zorin                
        "
        set -l namelist (string match -ra '\w+' $raw_list)
        set -l symbolist (string match -ra '[^\w\s]' $raw_list)
        set -l distro

        if test -n "$ANDROID_ROOT"
            set distro android
        else if test -f /etc/os-release
            set distro (string match -rg '^ID=(\w+)' < /etc/os-release)
        end

        set -l distrosym
        if test -n "$distro"
            set -f index (contains -i -- $distro $namelist)

            if test -n "$index"
                set distrosym $symbolist[$index]
            else
                set distrosym 
            end
        else
            set distrosym 
        end

        set -U __mist_login_distrosym $distrosym
    end

    function mist_git
        # format git information
        set -l options h/help b/branch= c/commit r/remote t/tag d/dirty= s/staging= a/ahead= i/behind= n/newline
        argparse $options -- $argv
        or return

        # Cache processing
        if test "$__mist_git_prompt_cache[1]" = "$__mist_git_ref$__mist_git_status$argv$argv_opts" -a -n "$__mist_git_prompt_cache[1]"
            test -z "$__mist_git_wt"
            and return

            set -l output $__mist_git_prompt_cache[2..]

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

        test -z "$__mist_git_ref" -o -z "$__mist_git_status"
        and return

        set -l output
        if test -n "$argv"
            set output $argv
        else
            set output '[%R%r%C]' '%A%B'
        end

        set -l ref_data $__mist_git_ref
        set -l reftype $ref_data[1]
        set -l refname $ref_data[2]
        set -l refhash $ref_data[3]

        set -l status_data $__mist_git_status
        set -l is_dirty $status_data[1]
        set -l is_staging $status_data[2]

        set -l ahead $status_data[3]
        if test -z "$ahead"
            set ahead 0
        end

        set -l behind $status_data[4]
        if test -z "$behind"
            set behind 0
        end

        if string match -rq '(?<!%)%C' $output
            set -f choiced_ind
            test "$is_dirty" = false -a "$is_staging" = true
            and set choiced_ind '%S'
            or set choiced_ind '%D'
            set output (string replace -ra -- '(?<!%)%C' "$choiced_ind" $output)
        end

        set -l output_bak $output

        # Replace every specifier in output
        set -l specifiers (string match -rga -- '(?<!%)%([RrhtabABDS])' $output)
        set specifiers (string match -rga -- '(\w)(?:\s*\1)*' (path sort $specifiers))
        for spec in $specifiers
            set -f val ""
            switch $spec
                case R
                    set -l charset_default    󰓹
                    set -l input_charset "$_flag_commit" "$_flag_branch" "$_flag_remote" "$_flag_tag"

                    set -l refchar
                    set -l char_index (contains -i -- $reftype commit branch remote tag)

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
                    set val "$ahead"
                case b
                    set val "$behind"
                case A
                    set -f ahead_ind
                    if test $ahead -gt 0
                        set -q _flag_ahead
                        and set ahead_ind $_flag_ahead
                        or set ahead_ind '↑'
                        set val "$ahead_ind"
                    end
                case B
                    set -f behind_ind
                    if test $behind -gt 0
                        set -q _flag_behind
                        and set behind_ind $_flag_behind
                        or set behind_ind '↓'
                        set val "$behind_ind"
                    end
                case D
                    if test "$is_dirty" = true -o "$is_staging" = true
                        set -f dirty_indicator
                        set -q _flag_dirty
                        and set dirty_indicator $_flag_dirty
                        or set dirty_indicator '+'
                        set val "$dirty_indicator"
                    end
                case S
                    if test "$is_staging" = true
                        set -f staging_indicator
                        set -q _flag_staging
                        and set staging_indicator $_flag_staging
                        or set staging_indicator '*'
                        set val "$staging_indicator"
                    end
            end
            set output (string replace -ra -- "(?<!%)%$spec" "$val" $output)
        end

        # clean blocks with only empty keys
        set -l count 1
        for block in $output
            if test "$block" = "$output_bak[$count]"
                set output[$count] ''
            end
            set count (math $count + 1)
        end

        # Process non-replaced specifiers and scapes
        set output (string replace -ra -- '(?<!%)%([RrhtabABDS])' '' $output)
        set output (string replace -ra -- '%(%+)' '$1' $output)

        set -g __mist_git_prompt_cache "$ref_data$status_data$argv$argv_opts" $output

        set -q _flag_n
        and printf "%b\n" $output
        or printf "%b" "$output"
    end

    function mist_pwd
        set -l options h/help H/homesym= F/foldersym= s/separator= T/no-tilde m/max-size= n/newline
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
                "  \e[32m%s\e[0m  Context symbol (Home / Generic)" \
                "  \e[32m%t\e[0m  The home name or tilde (~)" \
                "  \e[32m%p\e[0m  Parent path (relative to home if applicable)" \
                "  \e[32m%d\e[0m  Current directory name" \
                "" \
                "\e[1mExamples:\e[0m" \
                "  \$ mist_pwd \"%s %t%p%d\"                   \e[0m# Standard look\e[0m" \
                "  ~/mist/tools" \
                "  \$ mist_pwd -s \" > \" \"%p\e[32m%d\e[0m\"               \e[0m# Arrow separated path\e[0m" \
                "  > mist > tools"
            return
        end

        # Cache
        if test "$__mist_pwd_cache[1]" = "$PWD$argv$argv_opts" -a -n "$__mist_pwd_cache"
            set -l output $__mist_pwd_cache[2..]

            set -q _flag_n
            and printf "%b\n" $output
            or printf "%b" "$output"

            return
        end

        set -l homesym "󰋜"
        set -q _flag_H
        and set homesym $_flag_H

        set -l foldersym
        set -q _flag_F
        and set foldersym $_flag_F
        or set foldersym "󰝰"

        set -l separator
        set -q _flag_s
        and set separator $_flag_s
        or set separator /

        set -l dirname (path basename $PWD)
        set -l maxsize
        set -l maxsize_total

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

        set -l tilde
        set -q _flag_T
        and set tilde (path basename "$HOME")
        or set tilde '~'

        # Default prompt
        set -l output
        test -n "$argv"
        and set output $argv
        or set output "%s %t%p%d"

        set -l homepath (string escape --style=regex -- "$HOME")
        set -l symbol
        set -l dirpath

        if test "$HOME" = "$PWD"
            set symbol "$homesym"
            set dirname ""
            set dirpath ""
        else if string match -rq "^$homepath/" "$PWD"
            # Triggers if the pwd is ahead home
            set symbol "$foldersym"
            set dirpath (string match -rg  -- "^$homepath(.*?)[^/]*\$" "$PWD")

            # Shorts the dirpath
            set -l cutpath (string sub -s -$maxsize -- (string replace -- / "$separator" "$dirpath"))
            set -l maxdirs (count (string match -ra -- (string escape --style=regex -- "$separator") "$cutpath"))

            if test "$maxdirs" = 0
                if test "$dirpath" != /
                    set dirpath /…/
                end
                set dirname (string shorten -l -m $maxsize_total (path basename $PWD))
                set dirpath (string replace -r -- "(^/)?.+((?:/[^/]+){$maxdirs}/\$)" '$1…$2' "$dirpath")
            end
        else
            set tilde ""
            set symbol "$foldersym"
            # Shorts the dirpath
            set dirpath (path dirname "$PWD")

            set -l cutpath (string sub -s -$maxsize -- (string replace -- / "$separator" "$dirpath"))
            set -l maxdirs (count (string match -ra -- (string escape --style=regex -- "$separator") "$cutpath"))

            if test "$maxdirs" = 0
                set dirpath …/
                set dirname (string shorten -l -m $maxsize_total (path basename $PWD))
            else
                set dirpath (string replace -r -- ".+((?:/[^/]+){$maxdirs}\$)" '…$1' "$dirpath")/
            end
        end

        set dirpath (string replace -a -- / "$separator" $dirpath)

        set output (string replace -a -- "%s" "$symbol" $output)
        set output (string replace -a -- "%p" "$dirpath" $output)
        set output (string replace -a -- "%d" "$dirname" $output)
        set output (string replace -a -- "%t" "$tilde" $output)

        set -g __mist_pwd_cache "$PWD$argv$argv_opts" $output

        set -q _flag_n
        and printf "%b\n" $output
        or printf "%b" "$output"
    end
end
