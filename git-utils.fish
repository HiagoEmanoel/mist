# @fish-lsp-disable 4004
if status is-interactive
    function __gitdir

        set -g __git_worktree_dir # work as a cache, only aplies to work repos

        if test -n "$GIT_DIR"
            echo $GIT_DIR
            return
        end

        if test -d .git
            echo $PWD/.git
            set -g __git_worktree_dir $PWD
            return
        end

        set -l cut_pwd $PWD
        set -l ignore_dirs $HOME $TERMUX__ROOTFS_DIR (string split ':' $GIT_CEILING_DIRECTORIES)

        for cut in (string length (string match -ra "/[^/]+" $PWD)[-1..1])
            # find .git dir in filesystem
            # this calculates the lenght of dir entry names and
            # cut pwd acording of the size, focusing in security

            contains -- $cut_pwd $ignore_dirs; and break

            if test -d $cut_pwd/.git # detect and verify .git directory

                if ! test -f $cut_pwd/.git/HEAD -a -d $cut_pwd/.git/refs -a -d $cut_pwd/.git/objects
                    break
                end

                echo $cut_pwd/.git
                set -g __git_worktree_dir $cut_pwd
                break

            else if test -f $cut_pwd/config # detect bare repositories
                if ! test -f $cut_pwd/HEAD -a -d $cut_pwd/refs -a -d $cut_pwd/objects
                    continue
                end
                read -lzn 200 config_content <$cut_pwd/config
                if string match -qr 'bare\s*=\s*true' $config_content

                    echo $cut_pwd
                    return
                end
            end

            set cut_pwd (string sub -e -$cut $cut_pwd)
        end
    end

    function __git_info
        # return git informations (type name and hash) in an array
        set -l gitdir $argv[1]
        test -z "$gitdir"; and return 2

        read -l githead <"$gitdir/HEAD"

        if string match -qr '^[[:xdigit:]]+$' $githead
            # Verifys if the HEAD has a hash and verify
            # if the referance is in packed_refs and extract the informations

            set -l short_hash (string sub -l 7 $githead)

            if test -f "$gitdir/packed-refs"
                set -l pack_ref (string match -rg "$githead refs/(\w+)/(.+)" <$gitdir/packed-refs)

                if test -n "$pack_ref"
                    printf "%s\n" $pack_ref $short_hash
                    return
                end
            end

            if test -d $gitdir/refs/remotes # detect if the detached state is on a remote
                set -l remotes (string match -v '*/HEAD' $gitdir/refs/remotes/*/*)

                for remote in $remotes

                    if test (string collect < $remote) = $githead
                        printf "%s\n" remotes (string match -rg '/(\w+/\w+)$' $remote) $short_hash
                        return
                    end
                end
            end

            printf "%s\n" commit $short_hash $short_hash
            return
        end

        set -l ref_path (string sub -s 6 $githead) # get refpath
        set -l refhash

        if test -f "$gitdir/$ref_path" # detects unborn repositories
            read refhash <"$gitdir/$ref_path"
        else
            set refhash 0000000
        end

        set -l short_hash (string sub -l 7 $refhash)

        printf "%s\n" (string match -rg 'refs/(\w+)/(.+)' $ref_path) $short_hash
    end

    function __git_state
        # recives git directory and git info
        # return the staged status bases on git staging
        # and state (merging, rebase, etc)

        set -l gitdir $argv[1]
        set -l reftype $argv[2]
        set -l refname $argv[3]

        if test $reftype != heads
            printf "%s\n" clean normal
            return
        end

        set -l staging_status clean
        set -l operation_status normal

        set -l ref_time (path mtime -R $gitdir/refs/heads/$refname)
        set -l index_time (path mtime -R $gitdir/index)

        if test -z "$ref_time" -o -z "$index_time"
            printf "%s\n" clean normal
            return
        end

        if test $index_time -lt $ref_time
            set staging_status staging
        end

        printf "%s\n" $staging_status $operation_status
    end

    function __update_git_prompt_info
        # return git informations for prompt in this order:
        # ref type, name, short hash, staging state, operation state (like merge, rebase)

        set -g __git_prompt_itens

        set -l gitdir (__gitdir)
        test -z "$gitdir"; and return

        set -l ref_info (__git_info $gitdir)
        set -l ref_state (__git_state $gitdir $ref_info)

        # convert the internal format to a more common
        set -l reftype_names commit branch remote tag

        set -l type_index (contains -i $ref_info[1] commit heads remotes tags)
        set -l reftype $reftype_names[$type_index]

        set -g __git_prompt_itens $reftype $ref_info[2..] $ref_state
    end

    # triggers to only recalculat git whennecessary
    function __git_trigger_pwd --on-variable PWD
        # detects if is in agit directory after PWD chamges
        if test -z "$__git_worktree_dir"
            __update_git_prompt_info
            return
        end

        if ! string match -q "$__git_worktree_dir/*" $PWD
            __update_git_prompt_info
            return
        end
    end

    function __git_trigger_postexec --on-event fish_postexec
        # uses gitdir mtime to detect git changes
        test -z "$__git_worktree_dir"; and return

        set -l args (string split -n ' ' "$argv")
        set -l argc (count $args)
        test $argc = 1; and return

        if test $args[1] = git
            # detects read-only commands
            contains -- $args[2] status diff ls-remote log show rev-parse
            and return
            # detects commands that only read by default, but can write with flags
            if contains -- $args[2] branch tag remote config
                test $argc -le 2; and return
            end

            __update_git_prompt_info
            return
        end

        # detect changes by other commands than git
        set -l git_mtime (path mtime -R $__git_worktree_dir/.git)
        test -z "$git_mtime"; and return

        if test $git_mtime -lt (math $CMD_DURATION / 1000)
            __update_git_prompt_info
        end
    end

    __update_git_prompt_info
end

function format_git_prompt
    # genetate the git prompt
    test -z "$__git_prompt_itens"; and return

    # save argv before be consumed by argparse
    set -l argv_bak "$argv"
    argparse h/help c/charset= f/format= S/staging_char= -- $argv

    if set -q _flag_help
        # The help message defined above
        printf "%s\n" "Usage: format_git_prompt [OPTIONS]" \
            "" \
            "Options:" \
            "  -h, --help            Show this help message and exit" \
            "  -c, --charset=STR     Set symbols for git references" \
            "  -S, --staging_char=C  Set the character for staged change (default: \"+\")" \
            "  -f, --format=FORMAT   The format string to use (default: %R%r%S)" \
            "" \
            "Charset format:" \
            "  <commit> <branch> <remote> <tag> (default: @   󰓹)" \
            "" \
            "Format Specifiers:" \
            "  %R  Reference symbol" \
            "  %r  Reference name" \
            "  %h  Commit hash" \
            "  %S  Staging character"
        return
    end

    # uses cached prompt if nothing changes
    if test -n "$__git_prompt_cache"
        if test "$__git_prompt_cache[1]" = "$__git_prompt_itens $argv_bak"
            echo $__git_prompt_cache[2]
            return
        end
    end

    set -l reftype $__git_prompt_itens[1]
    set -l refname $__git_prompt_itens[2]
    set -l refhash $__git_prompt_itens[3]
    set -l staging_status $__git_prompt_itens[4]

    # set the staging character
    set -l staging_char
    if test $staging_status = staging
        if set -q _flag_staging_char
            set -- staging_char $_flag_staging_char
        else
            set staging_char '+'
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
    set -l output_format "%R%r%S"

    set -q _flag_format; and set -- output_format $_flag_format
    set -l output $output_format

    set -l specifiers (string match -ra '%R|%r|%h|%S' -- $output_format)

    for specifier in $specifiers
        switch $specifier
            case %R
                set output (string replace -- '%R' "$refchar" $output)
            case %r
                set output (string replace -- '%r' "$refname" $output)
            case %h
                set output (string replace -- '%h' "$refhash" $output)
            case %S
                set output (string replace -- '%S' "$staging_char" $output)
        end
    end

    set -g __git_prompt_cache "$__git_prompt_itens $argv_bak" "$output"

    echo $output
end
