# @fish-lsp-disable 4004
if status is-interactive
    function __gitdir
        if test -n "$GIT_DIR"
            echo $GIT_DIR
            return
        end

        set -l cut_pwd $PWD
        set -l ignore_dirs $HOME $TERMUX__ROOTFS_DIR (string split ':' $GIT_CEILING_DIRECTORIES)

        for cut in (string length (string match -ra "/[^/]+" $PWD)[-1..1])
            # find .git dir in filesystem
            contains -- $cut_pwd $ignore_dirs && break

            if test -d $cut_pwd/.git # detect and verify .git directory

                if ! test -f $cut_pwd/.git/HEAD -a -d $cut_pwd/.git/refs -a -d $cut_pwd/.git/objects
                    break
                end

                echo $cut_pwd/.git
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
        # return git informations (type refname and hash) in an array
        set -l gitdir $argv[1]
        test -z "$gitdir" && return 2

        read -l githead <"$gitdir/HEAD"

        if string match -qr '^[[:xdigit:]]+$' $githead
            # Verifys if the HEAD has a hash and verify
            # if the referance is in packed_refs and extract the informations

            if test -f "$gitdir/packed-refs"

                set -l pack_ref (string match -rg "$githead refs/(\w+)/(.+)" <$gitdir/packed-refs)

                if test -n "$pack_ref"
                    printf "%s\n" $pack_ref (string sub -l 7 $githead)
                    return
                end
            end

            set -l short_hash (string sub -l 7 $githead)
            printf "%s\n" $short_hash commit $short_hash
            return
        end

        set -l ref_path (string sub -s 6 $githead)

        if test -f "$gitdir/$ref_path" # detects unborn repositories
            read refhash <"$gitdir/$ref_path"
        else
            set refhash 0000000
        end

        printf "%s\n" (string match -rg 'refs/(\w+)/(.+)' $ref_path) (string sub -l 7 $refhash)
    end

    function __git_state
        # recives git directory and git info
        # return the dirty status bases on git staging
        # and state (merging, rebase, etc)

        set -l gitdir $argv[1]
        set -l reftype $argv[2]
        set -l refname $argv[3]

        set -l git_status clean normal

        if test $reftype = heads
            set -l ref_time (path mtime -R $gitdir/refs/heads/$refname)
            set -l index_time (path mtime -R .git/index)

            if test $ref_time -gt $index_time
                set git_status[1] dirty
            end
        end

        printf "%s\n" $git_status
    end

    function format_prompt
        set -l gitdir (__gitdir)

        if test -z "$gitdir"
            return
        end

        set -l ref_info (__git_info $gitdir)
        set -l ref_state (__git_state $gitdir $ref_info)

        set -l dirty_char

        if test $ref_state[1] = dirty
            set dirty_char '+'
        end

        switch $ref_info[1]
            case commit
                echo "@$ref_info[2]$dirty_char"
            case heads
                echo "$ref_info[2]$dirty_char"
            case remotes
                echo "$ref_info[2]$dirty_char"
            case tags
                echo "󰓹$ref_info[2]$dirty_char"
        end
    end
end
