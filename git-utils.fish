# @fish-lsp-disable 4004 2003
if status is-interactive

    set -e __git_status_async_data
    set -g __git_prompt_async_items
    set -g __git_worktree_last_mtime 0

    function __gitdir

        set -g __git_worktree_dir # work as a cache

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

        while test $cut_pwd != /
            # find .git dir in filesystem
            # this calculates the lenght of dir entry names and
            # cut pwd acording of the size, focusing in security

            contains -- $cut_pwd $ignore_dirs; and break

            if test -d $cut_pwd/.git # detect and verify .git directory

                if ! test -f $cut_pwd/.git/HEAD -a -d $cut_pwd/.git/refs -a -d $cut_pwd/.git/objects
                    continue
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
                    set -g __git_worktree_dir $cut_pwd
                    return
                end
            end

            set cut_pwd (path dirname $cut_pwd)
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

    function __update_git_prompt_info
        # return git informations for prompt in this order:
        # ref type, name, short hash, staging state, operation state (like merge, rebase)

        set -g __git_prompt_items

        set -l gitdir (__gitdir)
        test -z "$gitdir"; and return

        set -l ref_info (__git_info $gitdir)

        # convert the internal format to a more common
        set -l reftype_names commit branch remote tag

        set -l type_index (contains -i $ref_info[1] commit heads remotes tags)
        set -l reftype $reftype_names[$type_index]

        set -g __git_prompt_items $reftype $ref_info[2..]
    end

    # this is the async logic
    function __update_status_async

        test -z "$__git_worktree_dir"

        set -l worktree_identifier $__git_worktree_dir

        if contains $worktree_identifier -- $__git_status_async_lock_list
            set -g __git_status_await_call
            return
        end

        set -aU __git_status_async_lock_list $__git_worktree_dir

        set -l git_command "git status --porcelain=v2 --branch --short 2> /dev/null"
        fish --private -c "set -U __git_status_async_data ($git_command) $worktree_identifier" & disown
    end

    # format the output of git ststus
    function __async_git_status_handler --on-variable __git_status_async_data
        set -l git_data $__git_status_async_data[..-2]
        echo tet te teeto teto
        set -g worktree_identifier $__git_status_async_data[-1]

        if test -z "$__git_status_async_data"
            return
        end

        if test $worktree_identifier != "$__git_worktree_dir"
            return
        end

        set -l modify_status clean

        if test (count $git_data) -gt 1
            if string match -rq '^(?:\s|[ADM])[ADM]' $git_data[2..]
                set modify_status dirty
            else if string match -rq '^[ADM]\s' $git_data[2..]
                set modify_status staging
            end
        end

        set -l ahead (string match -rg '\[(?:ahead (\d).*)\]' "$git_data[1]")
        set -l behind (string match -rg '\[.*(?:behind (\d))\]' "$git_data[1]")

        set -g __git_prompt_async_items $modify_status $ahead $behind
        commandline -f repaint
        # remove lock and run the await call
        set -l identify_index (contains -i $worktree_identifier $__git_status_async_lock_list)
        if test -n "$identify_index"
            set -e __git_status_async_lock_list[$identify_index]
        end

        if set -q __git_status_await_call
            set -e __git_status_await_call
            __update_status_async
        end
    end

    function __git_trigger_postexec --on-event fish_postexec
        # uses gitdir mtime to detect git changes
        test -z "$__git_worktree_dir" -o -z "$__git_worktree_mtime"; and return

        set -l git_worktree_mtime (path mtime $__git_worktree_dir)
        if test git_worktree_mtime != $__git_worktree_last_mtime
            __update_status_async
        end

        set -g __git_worktree_last_mtime $git_worktree_mtime

        if set -q __git_status_await_call
            set -e __git_status_await_call
            __update_status_async
        end
    end

    # triggers to only recalculat git whennecessary
    function __git_trigger_pwd --on-variable PWD
        # detects if is in an git directory after PWD chamges
        if test -z "$__git_worktree_dir"
            __update_git_prompt_info
            if test -n "$__git_worktree_dir"
                __update_status_async
            end
            return
        end

        if ! string match -q "$__git_worktree_dir/*" $PWD
            __update_git_prompt_info
            return
        end
    end
    # update unformations on startup
    __update_git_prompt_info
    if test -n "$__git_worktree_dir"

        set -l worktree_identifier $__git_worktree_dir

        set -l identify_index (contains -i $worktree_identifier $__git_status_async_lock_list)
        if test -n "$identify_index"
            set -eU __git_status_async_lock_list[$identify_index]
        end
        __update_status_async
    end
end
