# @fish-lsp-disable 4004 2003 3003 4006
if status is-interactive
    if test "$MIST_ENABLE_TERMUX_API" = true
        set -g __mist_info_emitter_timestamp 0

        function __mist_info_runner
            sh -c 'fish -P -c "
            set -U __mist_info_runner_pid \$fish_pid
            set baterry (termux-battery-status | string match -rg '\''\"percentage\":\s*(\d+)'\'')
            set network (termux-wifi-connectioninfo | string match -rg '\''\"ssid\":\s*\"(.*)\"'\'' )
            set -U __mist_info_data_async \$baterry \$network
            sleep 5
            set -U __mist_info_trigger (path mtime /proc)" &'
        end

        function __mist_info_emitter
            if ! test -n "$ANDROID_ROOT" -a -n "$TERMUX_VERSION"
                return
            end

            # Clear dead shells 
            set -l cur_list $__mist_info_waitlist
            set -l new_list
            set -l alive_items

            for item in $cur_list
                set -l pid (string match -r '\d+$' $item)
                if test -f "/proc/$pid/comm"
                    string match -rq '^fish$' </proc/$pid/comm
                    and set -a alive_items $item
                end
            end

            # Update timestamp if the shell already on the list 
            set -l index (contains -i $fish_pid (string match -r '\d+$' $alive_items))
            set -l cur_timestamp (path mtime -R /proc)

            if test -n "$index"
                set new_list $alive_items
                set -e new_list[$index]
                set -a new_list $cur_timestamp:$fish_pid
            else
                set new_list $alive_items[..4]
                set -a new_list $cur_timestamp:$fish_pid
            end

            if test "$new_list" != "$cur_list"
                set -U __mist_info_waitlist $new_list
            end

            # Verify if there is a runner alive
            set -l runner_pid "$__mist_info_runner_pid"
            if test -f "/proc/$runner_pid/comm"
                string match -rq '^fish$' </proc/$runner_pid/comm
                and return
            end

            __mist_info_runner
        end

        function __mist_info_trigger_runner --on-variable __mist_info_trigger
            set -l last_item $__mist_info_waitlist[-1]
            if test (string match -r '\d+$' $last_item) = $fish_pid
                __mist_info_runner
            end
        end

        function __mist_info_trigger_postexec --on-event fish_postexec
            set -l last_status $status
            set -l men_usage (math -s0 (string match -rg '^(?:MemAvailable:)\s*(\d+)' </proc/meminfo)/1024)
            set -l men_total (math -s0 (string match -rg '^(?:MemTotal:)\s*(\d+)' </proc/meminfo)/1024)

            set -l baterry_and_network 0 unknown
            if test -n "$__mist_info_data_async"
                set baterry_and_network $__mist_info_data_async
            end

            set -g __mist_info_data $last_status $men_usage $men_total $baterry_and_network

            if test (path mtime -R /proc) -gt (math $__mist_info_emitter_timestamp + 5)
                __mist_info_emitter
            end
        end

    else
        function __mist_info_trigger_postexec --on-event fish_postexec
            set -l last_status $status
            set -l men_usage (math -s0 (string match -rg '^(?:MemAvailable:)\s*(\d+)' </proc/meminfo)/1024)
            set -l men_total (math -s0 (string match -rg '^(?:MemTotal:)\s*(\d+)' </proc/meminfo)/1024)

            set -g __mist_info_data $last_status $men_usage $men_total 0 unknown
        end
    end

    # Global state
    set -e __mist_git_wt \
        __mist_git_dir \
        __mist_git_ref \
        __mist_last_pwd_mtime

    set -g __mist_git_status false false 0 0
    set -g __mist_last_pwd $PWD

    if ! set -q __mist_git_timeout
        set -g __mist_git_timeout 10
    end

    # Blacklist configuration
    set -g __mist_git_black_list \
        ls ll la pwd dir vdir du df string ps pstree kill \
        cat less more tail head bat glow peek fastfetch \
        find fd locate which whereis type grep ripgrep rg \
        whoami groups id uptime free top htop btm neofetch \
        history clear exit jobs fg bg alias export set math \
        apt pacman dnf pip npm rsync unzip tar zip 7z xdg-open \
        "[" _ and argparse begin break builtin case command \
        continue else end eval exec for function if not \
        or read return status switch test time while

    set -g __mist_git_subcmd_black_list \
        log reflog shortlog show-branch help status diff show \
        ls-files ls-tree count-objects grep annotate blame \
        verify-pack config rev-parse list

    function __mist_git_getdir
        # Return the git directory and set the worktree
        set -e __mist_git_wt __mist_git_dir
        set -l worktree
        set -l gitdir
        set -l checks config HEAD objects refs

        test -n "$GIT_OBJECT_DIRECTORY"
        and set -e checks[(contains -i objects $checks)]

        test -n "$GIT_INDEX_FILE"
        and set -e checks[(contains -i index $checks)]

        if test -n "$GIT_WORK_TREE"
            set worktree $GIT_WORK_TREE
        end
        if test -n "$GIT_DIR"
            set gitdir $GIT_DIR
            return
        end

        if test -n "$worktree" -a -n "$gitdir"
            set -g __mist_git_wt $worktree
            set -g __mist_git_dir $gitdir
            return
        end

        # Fast verification in current PWD
        if test -d .git
            if path filter -vqt file,dir .git/{$checks}
                set -g __mist_git_wt $PWD
                set -g __mist_git_dir $PWD/.git
                return
            end
        end

        # Search up the tree using manual logic
        set -l ignore_dirs $HOME $TERMUX__ROOTFS_DIR (string split ':' $GIT_CEILING_DIRECTORIES)
        set -l splited_pwd $PWD
        while test $splited_pwd[-1] != /
            set -a splited_pwd (path normalize $splited_pwd[-1]/..)
            contains $splited_pwd[-1] $ignore_dirs
            and break
        end

        set -l gitdir_location (path filter -d $splited_pwd/.git)[1]

        if test -z "$gitdir_location" # Bare repo detection
            set -f gitdir_candidate (path filter -f $splited_pwd/config)[1]
            test -z "$gitdir_candidate"
            and return

            if path filter -vqt file,dir $gitdir_candidate/{$checks}
                return
            end

            read -lzn 200 config_content <$gitdir_candidate/config
            if string match -qr 'bare\s*=\s*true' $config_content
                set -g __mist_git_dir (path dirname $gitdir_candidate)
                return
            end
            return
        end

        # Worktree and dir assignment
        test -z "$worktree"
        and set worktree (path dirname $gitdir_location)

        test -z "$gitdir"
        and set gitdir $gitdir_location

        set -g __mist_git_wt $worktree
        set -g __mist_git_dir $gitdir
    end

    function __mist_git_getref
        # Return git reference
        set -l gitdir $__mist_git_dir
        test -z "$gitdir"
        and return

        set -g __mist_git_ref
        read -l githead <"$gitdir/HEAD"

        if string match -qr '^[[:xdigit:]]+$' $githead
            set -f short_hash (string sub -l 7 $githead)
            if test -f "$gitdir/packed-refs"
                set -f pack_ref (string match -rg "$githead refs/(\w+)/(.+)" <$gitdir/packed-refs)
                if test -n "$pack_ref"
                    set -g __mist_git_ref (string sub -e -1 $pack_ref[1]) $pack_ref[2] $short_hash
                    return
                end
            end

            if test -d $gitdir/refs/remotes
                set -f remotes (string match -v '*/HEAD' $gitdir/refs/remotes/*/*)
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

        set -l ref_path (string sub -s 6 $githead)
        if test -f "$gitdir/$ref_path"
            read refhash <"$gitdir/$ref_path"
        else
            set refhash 0000000
        end

        set -l short_hash (string sub -l 7 $refhash)
        set -l ref_data (string match -rg 'refs/(\w+)/(.+)' $ref_path)
        set -l type_index (contains -i $ref_data[1] heads tags)
        set -l reftype_names branch tag
        set -g __mist_git_ref $reftype_names[$type_index] $ref_data[2] $short_hash
    end

    function __mist_git_process_data
        # Helper to structure raw git porcelain into local state
        set -l git_data $argv
        set -l is_dirty false
        set -l is_staging false

        if test (count $git_data) -gt 1
            if string match -rq '^(?:\s|\S)\S' $git_data[2..]
                set is_dirty true
            end
            if string match -rq '^\S\s' $git_data[2..]
                set is_staging true
            end
        end

        set -l ahead (string match -rg '\[(?:ahead (\d).*)\]' "$git_data[1]")
        set -l behind (string match -rg '\[.*(?:behind (\d))\]' "$git_data[1]")
        test -z "$ahead"
        and set ahead 0

        test -z "$behind"
        and set behind 0

        printf "%s\n" $is_dirty $is_staging $ahead $behind
    end

    # Emits the background git status
    function __mist_git_emitter
        test -z "$__mist_git_wt"
        and return

        # Use global lock list to prevent simultaneous calls in same worktree
        set -l escaped_wt (string escape --style=regex "$target_wt")
        if string match -rq "\d+:$escaped_wt" $__mist_git_lock
            # Timeout verification
            set -l wt_mtime (string match -rg "(\d+):$escaped_wt" $__mist_git_lock)
            if test "$wt_mtime" -lt (math (path mtime -R /proc) - $__mist_git_timeout)
                set -U __mist_git_lock (string match -rv "\d+:$escaped_wt" $__mist_git_lock)
            else
                return
            end
        end

        set -aU __mist_git_lock (path mtime -R /proc)":$__mist_git_wt"
        set -l git_cmd "git status --porcelain=v2 --branch --short 2>/dev/null"

        fish --private -c "set -U __mist_gitout_$fish_pid $__mist_git_wt ($git_cmd);kill -SIGUSR1 $fish_pid" &
    end

    function __mist_git_handler --on-signal SIGUSR1
        set -l out_var "__mist_gitout_$fish_pid"
        set -l raw_data $$out_var

        test -z "$raw_data"
        and return

        set -eU $out_var

        set -l target_wt $raw_data[1]
        set -l escaped_wt (string escape --style=regex "$target_wt")

        set -l git_output $raw_data[2..]
        set -l status_data (__mist_git_process_data $git_output)

        set -l max_cache 8
        set -l cache_entry "$target_wt $__mist_git_ref $status_data"

        # Move the cache entry to start of the list
        set -l new_cache (string match -rv "^$escaped_wt\s.*" $__mist_git_cache)
        set -p new_cache "$cache_entry"

        if test (count $new_cache) -gt $max_cache
            set -e new_cache[-1]
        end
        set -U __mist_git_cache $new_cache

        # Syncronize sessions
        set -U __mist_git_sync "$target_wt" $__mist_git_ref $status_data
        set -U __mist_git_lock (string match -rv "\d+:$escaped_wt" $__mist_git_lock)

        test "$__mist_git_wt" = "$target_wt"
        and return

        set -g __mist_git_status $status_data
        commandline -f repaint
    end

    function __mist_git_sync_handler --on-variable __mist_git_sync
        # Secondary shells in the same worktree detect global data update
        test -z "$__mist_git_sync"
        and return

        test "$__mist_git_sync[1]" != "$__mist_git_wt"
        and return

        set -g __mist_git_ref $__mist_git_sync[2..4]
        set -g __mist_git_status $__mist_git_sync[5..8]
        commandline -f repaint
    end

    function __mist_git_trigger_postexec --on-event fish_postexec
        set -l args (string split ' ' "$argv" | string match -r '\w+')

        if test "$__mist_last_pwd" != "$PWD" -o (path mtime $__mist_last_pwd) != __mist_last_pwd_mtime
            set -g __mist_last_pwd_mtime (path mtime $__mist_last_pwd)

            set -g __mist_last_pwd "$PWD"
            __mist_git_getdir

            if test -n "$__mist_git_wt"
                # Register session
                if ! string match -qr "^$fish_pid:" $__mist_git_sessions
                    set -aU __mist_git_sessions "$fish_pid:$__mist_git_wt"
                else
                    set -U __mist_git_sessions (string replace -r "^$fish_pid:.*" "$fish_pid:$__mist_git_wt" $__mist_git_sessions)
                end
            else
                set -U __mist_git_sessions (string match -rv "^$fish_pid:" $__mist_git_sessions)
                set -g __mist_git_ref
                set -g __mist_git_status false false 0 0
                return
            end

            # Restore from cache
            set -f escape_wt (string escape --style=regex $__mist_git_wt)
            set -f cache_match (string match -r "^$escape_wt\s.+" $__mist_git_cache)

            if test -n "$cache_match"
                set cache_data (string split ' ' $cache_match)
                set -g __mist_git_ref $cache_data[2..4]
                set -g __mist_git_status $cache_data[5..8]
            else
                set -g __mist_git_ref
                set -g __mist_git_status false false 0 0
            end
        end

        test -z "$__mist_git_wt"
        and return

        if ! contains -- '>' $args
            and ! contains -- '>>' $args

            if test "$args[1]" = git -o "$args[1]" = g
                contains -- "$args[2]" $__mist_git_subcmd_black_list
                and return

            else
                contains -- "$args[1]" $__mist_git_black_list
                and return

            end
        end

        __mist_git_getref
        __mist_git_emitter
    end

    function __mist_git_cleaner --on-event fish_exit
        # Clean current session
        set -eU "__mist_gitout_$fish_pid"
        set -U __mist_git_sessions (string match -rv "^$fish_pid:" $__mist_git_sessions)

        # Batch cleanup of dead processes
        set -l pids (string match -rg '^(\d+):' $__mist_git_sessions)
        set -l dead_pids (string match -rg '^/proc/(\d+)' (path filter -vd /proc/$pids))

        test -z "$dead_pids"
        and return

        set -eU __mist_gitout_$dead_pids
        set -l regex_filter (string join '|' (string replace -r '^/proc/' '' $dead_pids))

        set -U __mist_git_sessions (string match -rv "^(?:$regex_filter):.+" $__mist_git_sessions)

        # Clear timeouted locks
        if test -n "$__mist_git_lock"
            set -l timestamp (path mtime -R /proc)
            set -l new_lock

            for lock in $__mist_git_lock
                set -f lock_timestamp (string match -r '^\d+' $lock)
                if test (math $lock_timestamp + $__mist_git_timeout) -ge $timestamp
                    set -a new_lock $lock
                end
            end

            set __mist_git_lock $new_lock
        end
    end

    # Startup
    __mist_git_getdir
    if test -n "$__mist_git_wt"
        set -aU __mist_git_sessions "$fish_pid:$__mist_git_wt"

        # Restore from cache
        set escape_wt (string escape --style=regex $__mist_git_wt)
        set cache_match (string match -r "^$escape_wt\s.+" $__mist_git_cache)

        if test -n "$cache_match"
            set cache_data (string split ' ' $cache_match)
            set -g __mist_git_ref $cache_data[2..4]
            set -g __mist_git_status $cache_data[5..8]
        end
    end
    __mist_git_getref
    __mist_git_emitter
end
