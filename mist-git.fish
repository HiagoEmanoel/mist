# @fish-lsp-disable 4004 2003 3003 4006

# This function must be available to subshells
function __mist_git_runner
    set wtid $argv[1]
    test -z "$wtid"; and return

    set git_out (git status --porcelain=v2 --branch --short 2>/dev/null)

    set is_dirty false
    set is_staging false

    if test (count $git_out) -gt 1
        # Check for modified/added files in worktree
        if string match -rq '^(?:\s|[ADM])[ADM]' $git_out[2..]
            set is_dirty true
        end
        if string match -rq '^[ADM]\s' $git_out[2..]
            set is_staging true
        end
    end

    set ahead (string match -rg '\[(?:ahead (\d).*)\]' "$git_out[1]")
    set behind (string match -rg '\[.*(?:behind (\d))\]' "$git_out[1]")

    test -z "$ahead"; and set ahead 0
    test -z "$behind"; and set behind 0

    if set -qU __mist_git_refresh_$wtid
        set -eU __mist_git_refresh_$wtid

        if test "$argv[2]" != --no-refresh
            __mist_git_runner $wtid --no-refresh
        end
    end

    set -eU __mist_git_lock_$wtid

    # Apply data to the universal variable slices
    set data_var "__mist_git_data_$wtid"
    set -U {$data_var}[4..7] $is_dirty $is_staging $ahead $behind
end

if status is-interactive
    set -e __mist_git_dir \
        __mist_git_wtid \
        __mist_git_ref \
        __mist_last_pwd

    functions -e __mist_git_handle
    set -g __mist_git_status false false 0 0

    set -g __mist_git_black_list \
        ls ll la pwd dir vdir du df string ps pstree kill \
        cat less more tail head bat glow peek fastfetch \
        find fd locate which whereis type grep ripgrep rg \
        whoami groups id uptime free top htop btm neofetch \
        history clear exit jobs fg bg alias export set math \
        apt pacman dnf pip npm rsync \
        unzip tar zip 7z xdg-open open man tldr info \
        "[" _ and argparse begin break builtin case command \
        continue else end eval exec for function if not \
        or read return status switch test time while

    set -g __mist_git_subcmd_black_list \
        log reflog shortlog show-branch help \
        status diff show ls-files ls-tree \
        count-objects grep annotate blame \
        verify-pack config rev-parse list

    function __mist_git_getdir
        # Get the current git directory and worktree
        set -e __mist_git_wtid \
            __mist_git_dir \
            worktree \
            gitdir

        # Process user-seted git info
        if test -n "$GIT_WORK_TREE"
            set worktree $GIT_WORK_TREE
        end
        if test -n "$GIT_DIR"
            set gitdir $GIT_DIR
            return
        end

        if test -n "$worktree" -a -n "$gitdir"
            set -g __mist_git_wtid (string escape --style=var $worktree)
            set -g __mist_git_dir $gitdir
            return
        end

        # Fast verification
        if test -d .git
            if path filter -vqt file,dir .git/{config,HEAD,objects,refs}
                test -z "$worktree"
                and set -g __mist_git_wtid (string escape --style=var $PWD)

                test -z "$gitdir"
                and set -g __mist_git_dir $PWD/.git
                return
            end
        end

        # Verify cealing directories
        set ignore_dirs $HOME $TERMUX__ROOTFS_DIR (string split ':' $GIT_CEILING_DIRECTORIES)
        set splited_pwd $PWD

        while test $splited_pwd[-1] != /
            set -a splited_pwd (path normalize $splited_pwd[-1]/..)
            contains $splited_pwd[-1] $ignore_dirs; and break
        end

        set gitdir_location (path filter -d $splited_pwd/.git)[1]

        if test -z "$gitdir_location" # Detect bare repos
            set gitdir_candidate (path filter -f $splited_pwd/config)[1]
            test -z "$gitdir_candidate"
            and return

            if ! path filter -vqt file,dir $gitdir_candidate/{config,HEAD,objects,refs}
                set gitdir (path dirname $gitdir_candidate)
                set -g __mist_git_dir $gitdir
                return
            end

            read -lzn 200 config_content <$gitdir_candidate/config
            if string match -qr 'bare\s*=\s*true' $config_content
                test -z "$gitdir"
                and set gitdir (path dirname $gitdir_candidate)

                set -g __mist_git_dir $gitdir
                return
            end
            return
        end

        if ! path filter -vqt file,dir $gitdir_location/{config,HEAD,objects,refs}
            test -z "$worktree"
            and set worktree (path dirname $gitdir_location)

            test -z "$gitdir"
            and set gitdir $gitdir_location

            set -g __mist_git_wtid (string escape --style=var $worktree)
            set -g __mist_git_dir $gitdir
        end
    end

    function __mist_git_getref
        set gitdir $__mist_git_dir
        test -z "$gitdir"; and return

        set -e __mist_git_ref
        read githead <"$gitdir/HEAD"

        if string match -qr '^[[:xdigit:]]+$' $githead
            set short_hash (string sub -l 7 $githead)

            if test -f "$gitdir/packed-refs"
                set pack_ref (string match -rg "$githead refs/(\w+)/(.+)" <$gitdir/packed-refs)
                if test -n "$pack_ref"
                    set -g __mist_git_ref (string sub -e -1 $pack_ref[1]) $pack_ref[2] $short_hash
                    return
                end
            end

            if test -d $gitdir/refs/remotes
                set remotes (string match -v '*/HEAD' $gitdir/refs/remotes/*/*)
                for remote in $remotes
                    if string match -q $githead <$remote
                        set -g __mist_git_ref remote (string match -rg '/(\w+/\w+)$' $remote) $short_hash
                        return
                    end
                end
            end
            set -g __mist_git_ref commit $short_hash $short_hash
            return
        end

        set ref_path (string sub -s 6 $githead)
        if test -f "$gitdir/$ref_path"
            read refhash <"$gitdir/$ref_path"
        else
            set refhash 0000000
        end

        set short_hash (string sub -l 7 $refhash)
        set ref_data (string match -rg 'refs/(\w+)/(.+)' $ref_path)

        set type_index (contains -i $ref_data[1] heads tags)
        set reftype_names branch tag

        set -g __mist_git_ref $reftype_names[$type_index] $ref_data[2] $short_hash
    end

    function __mist_git_emitter
        set wtid $__mist_git_wtid
        test -z "$wtid"; and return

        set lock_var "__mist_git_lock_$wtid"

        if set -q $lock_var
            set timeout (string match -r '^\d+$' $mist_timeout[1]; or echo 10)
            set cur_timestamp (path mtime -R /proc)
            set lock_timestamp $$lock_var

            if test (math "$lock_timestamp" + "$timeout") -lt "$cur_timestamp"
                set -eU $lock_var __mist_git_refresh_$wtid
            else
                set -q __mist_git_refresh_$wtid
                or set -U __mist_git_refresh_$wtid
            end
            return
        end

        set -U __mist_git_lock_$wtid (path mtime -R /proc)
        # Start background runner
        # source is for dev debug
        # fish --private -c "source $HOME/mist/mist-git.fish;__mist_git_runner $wtid" &
        fish --private -c "__mist_git_runner $wtid" &
    end

    function __mist_git_wtid_updater
        # Update wtid after change the PWD
        if test "$__mist_last_pwd" = "$PWD"
            return
        end

        set last_wtid "$__mist_git_wtid"
        __mist_git_getdir

        if test "$last_wtid" = "$__mist_git_wtid"
            return
        end

        set -g __mist_last_pwd "$PWD"

        # Detect if exit a git repo
        if test -n "$last_wtid" -a "$last_wtid" != "$__mist_git_wtid"
            set last_worktree (string unescape --style=var "$last_wtid")

            if ! string match -q "$last_worktree/*" "$PWD/"
                set -g __mist_git_status false false 0 0
                set -g __mist_git_ref

                # Clean variables
                functions -e __mist_git_handle
                set -U __mist_git_sessions (string match -rv "^$fish_pid:" $__mist_git_sessions)

                # Remove unused worktree-specific variables
                if ! string match -rq ":$last_wtid\$" $__mist_git_sessions
                    set -eU "__mist_git_data_$last_wtid" "__mist_git_lock_$last_wtid" "__mist_git_refresh_$last_wtid"

                end
            end
        end

        # Exit if is not in a git repo
        test -z "$__mist_git_wtid"
        and return

        set wtid "$__mist_git_wtid"

        # Updates the global list
        if string match -qr "^$fish_pid:" $__mist_git_sessions
            set -U __mist_git_sessions (string replace -r "^$fish_pid:.*" "$fish_pid:$wtid" $__mist_git_sessions)
        else
            set -aU __mist_git_sessions "$fish_pid:$wtid"
        end

        # Update the git info
        set last_ref "$__mist_git_ref"
        __mist_git_getref

        if test "$__mist_git_ref" != "$last_ref"
            set data_var "__mist_git_data_$__mist_git_wtid"
            set -U {$data_var}[1..3] $__mist_git_ref
        end

        set tmpvar "__mist_git_data_$__mist_git_wtid"[4..7]
        set status_data $$tmpvar

        if test -n "$status_data"
            set -g __mist_git_status $status_data
        else
            set -g __mist_git_status false false 0 0
        end

        # Dynamic handler
        function __mist_git_handle --on-variable __mist_git_data_$wtid -V wtid
            set data_var "__mist_git_data_$wtid"
            set data $$data_var
            if test "$__mist_git_ref $__mist_git_status" != "$data[..7]"
                set -g __mist_git_ref $data[1..3]
                set -g __mist_git_status $data[4..7]
                commandline -f repaint
            end
        end
    end
    function __mist_git_trigger_postexec --on-event fish_postexec
        __mist_git_wtid_updater
        test -z "$__mist_git_wtid"; and return

        # Verify if the command is on black list
        set args (string split ' ' "$argv")
        if test -z "$args"
            return
        end

        if test (count $args) -ge 2 -a \( "$args[1]" = git -o "$args[1]" = g \)
            if contains -- "$args[2]" $__mist_git_subcmd_black_list
                return
            end
        else
            if contains -- "$args[1]" $__mist_git_black_list
                return
            end
        end

        __mist_git_getref
        __mist_git_emitter
    end
    function __mist_git_cleaner --on-event fish_exit
        set session_list $__mist_git_sessions
        set session_list (string match -rv "^$fish_pid" $session_list)

        set pid_list (string match -r '^\d+' $session_list)
        set alive_pids (path filter /proc/$pid_list/comm)

        set validated_pids
        for pid_path in $alive_pids
            string match -q fish <$pid_path; and set -a validated_pids $pid_path
        end

        set ok_pids (string match -rg '/proc/(\d+)/comm' $validated_pids)
        set alive_sessions
        if test -n "$ok_pids"
            set regex (string join '|' $ok_pids)
            set alive_sessions (string match -r "(?:$regex):.+" $session_list)
        end

        set active_wktrees (string match -r '[^:]+$' $alive_sessions | path sort -u)
        set wktree_vars (set -nU | string match -rg '^__mist_git_data_(.+)')
        set dead_wktrees $wktree_vars

        for wktree in $active_wktrees
            set dead_wktrees (string match -v "$wktree" $dead_wktrees)
        end

        if test -n "$dead_wktrees"
            set -eU __mist_git_data_$dead_wktrees __mist_git_lock_$dead_wktrees __mist_git_refresh_$dead_wktrees
        end

        set -U __mist_git_sessions $alive_sessions
    end

    __mist_git_trigger_postexec
end
