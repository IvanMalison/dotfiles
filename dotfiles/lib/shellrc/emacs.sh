alias emacs='cemacs'
alias cemacs='_emacs -c -n'
alias temacs='_emacs -t'
alias ec='_emacs -n '

function _emacs {
    local directory="$(git rev-parse --show-toplevel 2> /dev/null || pwd)"
    local server_name="$(_dot_directory $directory)"
    if ! _emacs_daemon_exists "$server_name"; then
        echo "Starting emacs with server name '$server_name'"
        \emacs --daemon="$server_name"
    fi
    local command="emacsclient $* --server-file=$server_name"
    if is_osx; then
        as_current_user $command
    else
        $command
    fi
}

function _emacs_daemon_exists {
    ! test -z "$(ps aux | grep -v grep | grep -i "emacs.*--daemon=.*$1$")"
}

function _dot_directory {
    echo $1 | sed "s:/:.:g" 
}
