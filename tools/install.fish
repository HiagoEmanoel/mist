set -eU __mist_git_cache \
    __mist_git_lock \
    __mist_git_sessions \
    __mist_git_sync

cp ./{mist-git.fish,mist-widgets.fish,mist-decors.fish} $__fish_config_dir/conf.d
