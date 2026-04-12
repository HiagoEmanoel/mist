# @fish-lsp-disable 4004 2003
if status is-interactive

    set -g __mist_git_directory
    set -g __mist_git_reference
    set -g __mist_git_directory
    set -g __mist_git_status false false 0 0
    set -g __mist_git_needs_refresh false

    # commands that are ignored by posteexec
    set -g __mist_git_black_list
    set -a __mist_git_black_list ls ll la pwd dir vdir du df string ps pstree kill
    set -a __mist_git_black_list cat less more tail head bat glow peek fastfetch
    set -a __mist_git_black_list find fd locate which whereis type grep ripgrep rg
    set -a __mist_git_black_list whoami groups id uptime free top htop btm neofetch
    set -a __mist_git_black_list history clear exit jobs fg bg alias export set math apt pacman dnf pip

    set -g __mist_git_subcmd_black_list
    set -a __mist_git_subcmd_black_list log reflog shortlog show-branch help
    set -a __mist_git_subcmd_black_list status diff show ls-files ls-tree count-objects
    set -a __mist_git_subcmd_black_list grep annotate blame verify-pack

    function __mist_git_getdir
        # return the git directory, and set the worktree fon nom-bare repos
        set -g __mist_git_worktree
        set worktree
        set gitdir

        if test -n "$GIT_WORK_TREE"
            set worktree $GIT_WORK_TREE
        end

        if test -n "$GIT_DIR"
            set gitdir $GIT_DIR
            return
        end

        if test -n "$worktree" -a -n "$gitdir"
            set __mist_git_worktree $worktree
            set -g __mist_git_directory $gitdir
            return
        end

        if test -d .git
            if path filter -vqt file,dir $gitdir_location/{config,HEAD,objects,refs}
                return
            end
            test -z "$worktree"; and set -g __mist_git_worktree $PWD
            test -z "$gitdir"; and set -g __mist_git_directory $PWD/.git
        end

        set ignore_dirs $HOME $TERMUX__ROOTFS_DIR (string split ':' $GIT_CEILING_DIRECTORIES)

        set splited_pwd $PWD

        # generates every subpath from the PWD
        while test $splited_pwd[-1] != /
            set -a splited_pwd (path normalize $splited_pwd[-1]/..)
            contains $splited_pwd[-1] $ignore_dirs; and break
        end

        set gitdir_location (path filter -d $splited_pwd/.git)[1]

        if test -z "$gitdir_location" # detect bare repositories

            set gitdir_candidate (path filter -f $splited_pwd/config)[1]
            test -z "$gitdir_candidate"; and return

            if path filter -vqt file,dir $gitdir_candidate/{config,HEAD,objects,refs}
                return
            end

            read -lzn 200 config_content <$gitdir_candidate/config
            if string match -qr 'bare\s*=\s*true' $config_content

                test -z "$gitdir"; and set gitdir (path dirname $gitdir_candidate)
                set -g __mist_git_directory $gitdir
                return
            end

            return
        end

        if path filter -vqt file,dir $gitdir_location/{config,HEAD,objects,refs}
            return
        end

        test -z "$worktree"; and set worktree (path dirname $gitdir_location)
        test -z "$gitdir"; and set gitdir $gitdir_location

        set -g __mist_git_worktree $worktree
        set -g __mist_git_directory $gitdir
    end

    function __mist_git_getref
        # return git reference (type name and hash) in an array
        set gitdir $__mist_git_directory
        test -z "$gitdir"; and return

        set -g __mist_git_reference
        read -l githead <"$gitdir/HEAD"

        if string match -qr '^[[:xdigit:]]+$' $githead
            # Verifys if the HEAD has a hash and verify
            # if the referance is in packed_refs and extract the informations

            set short_hash (string sub -l 7 $githead)

            if test -f "$gitdir/packed-refs"
                set pack_ref (string match -rg "$githead refs/(\w+)/(.+)" <$gitdir/packed-refs)

                if test -n "$pack_ref"

                    set reftype (string sub -e -1 $pack_ref[1])
                    set refname $pack_ref[2]

                    set -g __mist_git_reference $reftype $refname $short_hash
                    return
                end
            end

            if test -d $gitdir/refs/remotes # detect if the detached state is on a remote
                set remotes (string match -v '*/HEAD' $gitdir/refs/remotes/*/*)

                for remote in $remotes

                    if string match -q $githead <$remote
                        set -g __mist_git_reference remote (string match -rg '/(\w+/\w+)$' $remote) $short_hash
                        return
                    end
                end
            end

            set -g __mist_git_reference commit $short_hash $short_hash
            return
        end

        set ref_path (string sub -s 6 $githead) # get refpath
        set refhash

        if test -f "$gitdir/$ref_path" # detects unborn repositories
            read refhash <"$gitdir/$ref_path"
        else
            set refhash 0000000
        end

        set short_hash (string sub -l 7 $refhash)
        set ref_path_data (string match -rg 'refs/(\w+)/(.+)' $ref_path)

        set reftype $ref_path_data[1]
        set refname $ref_path_data[2]

        set reftype_names branch tag
        set type_index (contains -i $reftype heads tags)
        set reftype $reftype_names[$type_index]

        set -g __mist_git_reference $reftype $refname $short_hash
    end

    function __mist_git_emitter
        test -z "$__mist_git_worktree"; and return
        set lock_list $__mist_git_lock

        if test -n "$lock_list"
            # a garbage collector that cleans all dead fish sessions
            set pid_list (string match -r '^\d+' $lock_list)
            set alive_pids (path filter /proc/$pid_list/comm)

            set validated_pids
            for pid in $alive_pids
                # test if the proc_alive processes are from fish
                if string match -q fish <$pid
                    set -a validated_pids $pid
                end
            end

            set ok_pids (string match -rg '/proc/(\d+)/comm' $validated_pids)
            set regex_filter (string join '|' $ok_pids)

            set lock_list (string match -r "(?:$regex_filter):.+" $lock_list)
        end

        set worktree $__mist_git_worktree
        set new_entry $fish_pid:$worktree

        if contains $worktree (string match -rg '^\d+:(.+)' $lock_list)
            set -g __mist_git_needs_refresh true
        else
            set -a lock_list $new_entry
            set git_command "git status --porcelain=v2 --branch --short 2> /dev/null"
            fish --private -c "set -U __mist_git_status_data ($git_command) $worktree; kill -SIGUSR1 $fish_pid" &
        end

        set -U __mist_git_lock $lock_list
    end

    function __mist_git_handler --on-signal SIGUSR1
        # handlers the output of backgroundvcommands
        test -z "$__mist_git_worktree"; and return
        test -z "$__mist_git_status_data"; and return

        set git_data $__mist_git_status_data[..-2]
        set worktree $__mist_git_status_data[-1]

        if test $worktree != "$__mist_git_worktree"
            return
        end

        set is_dirty false
        set is_staging false

        if test (count $git_data) -gt 1
            if string match -rq '^(?:\s|[ADM])[ADM]' $git_data[2..]
                set is_dirty true
            end

            if string match -rq '^[ADM]\s' $git_data[2..]
                set is_staging true
            end
        end

        set ahead (string match -rg '\[(?:ahead (\d).*)\]' "$git_data[1]")
        set behind (string match -rg '\[.*(?:behind (\d))\]' "$git_data[1]")

        test -z "$ahead"; and set ahead 0
        test -z "$behind"; and set behind 0

        set -g __mist_git_status $is_dirty $is_staging $ahead $behind
        commandline -f repaint

        # remove lock and run the await call
        set new_lock_list (string match -v "$fish_pid:$worktree" $__mist_git_lock)
        set -U __mist_git_lock $new_lock_list

        if test $__mist_git_needs_refresh = true
            set -g __mist_git_needs_refresh false
            __mist_git_emitter
        end
    end

    set -g __mist_last_pwd $PWD
    function __mist_git_trigger_postexec --on-event fish_postexec
        # atualizes git after every command
        set args (string split ' ' $argv)

        if test "$__mist_last_pwd" != "$PWD"
            set -g __mist_last_pwd "$PWD"
            if ! string match -q "$__mist_git_worktree/*" "$PWD"
                set -g __mist_git_status false false 0 0
            end
            __mist_git_getdir
            if test -z "$__mist_git_worktree"
                set -g __mist_git_reference
                set -g __mist_git_status false false 0 0
                return
            end
        end

        test -z "$__mist_git_worktree"; and return

        # disregard read-only commands
        if ! contains -- '>' $args; or contains -- '>>' $args
            if test "$args[1]" = git -o "$args[1]" = g
                if contains -- "$args[2]" $__mist_git_subcmd_black_list
                    return
                end
            else
                if contains -- "$args[1]" $__mist_git_black_list
                    return
                end
            end
        end

        __mist_git_getref
        __mist_git_emitter
    end

    # update git informations on startup
    __mist_git_getdir
    __mist_git_getref
    __mist_git_emitter
end
