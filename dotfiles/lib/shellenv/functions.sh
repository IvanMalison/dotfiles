function get_python_scripts_path {
    python -c "import sysconfig; print sysconfig.get_path('scripts')"
}

function path_lines {
    local python_command
    # We need to get a path to the ACTUAL python command because
    # pyenv alters PATH before actually executing python, which ends
    # up changing PATH in a way that is not desireable.
    hash pyenv 2>/dev/null && python_command="$(pyenv which python)" || python_command="$(which python)"
    "$python_command" "$HOME/.lib/python/shell_path.py" --path-lines "$@"
}

function indirect_expand {
    eval "value=\"\${$1}\""
    echo $value
}

function environment_variable_exists {
    eval "value=\"\${$1+x}\""
    [ ! -z $value ]
}

function exists_in_path_var {
    target=${2-PATH}
    local path_contents="$(indirect_expand $target)"
    [[ ":$path_contents:" == *":$1:"* ]]
}

function split_into_vars () {
    local string IFS

    string="$1"
    IFS="$2"
    shift 2
    read -r -- "$@" <<EOF
$string
EOF
}

function echo_split () {
   local IFS
    IFS="$2" read -rA -- arr <<EOF
$1
EOF
    for i in "${arr[@]}"; do
        echo $i
    done
}

function shell_contains () {
  local e
  for e in "${@:2}"; do
      [[  "$1" == *"$e"* ]] && return 0
  done
  return 1
}

function dotfiles_directory() {
    echo $(dirname `readlink -f ~/.zshrc | xargs dirname`)
}

function go2dotfiles() {
    cd $(dotfiles_directory)
}

function update_dotfiles() {
    local old_pwd=$(pwd)
    go2dotfiles
    git ffo
    cd $old_pwd
}

function current_shell() {
    which "$(ps -p $$ | tail -1 | awk '{print $NF}' | sed 's/\-//')"
}

function is_zsh() {
    [ ! -z ${ZSH_VERSION+x} ]
}

function git_diff_add() {
    git status --porcelain | awk '{print $2}' | xargs -I filename sh -c "git du filename && git add filename"
}

function confirm() {
    # call with a prompt string or use a default
    read -r -p "$1" response
    case $response in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

function get_cols() {
    FS=' '
    OPTIND=1
    while getopts "F:" OPTCHAR; do
        case $OPTCHAR in
            F)
                FS=$OPTARG
                ;;
        esac
    done
    shift $((OPTIND-1))
    gawk -f "$HOME/.lib/get_cols.awk" -v "cols=$*" -v "FS=$FS"
}

function filter_by_column_value {
    awk '$'"$1"' == '"$2"'  { print $0 }'
}

function find_all_ssh_agent_sockets() {
    find /tmp -type s -name agent.\* 2> /dev/null | grep '/tmp/ssh-.*/agent.*'
}

function set_ssh_agent_socket() {
    export SSH_AUTH_SOCK=$(find_all_ssh_agent_sockets | tail -n 1 | awk -F: '{print $1}')
}

# Determine size of a file or total size of a directory
function fs() {
    if du -b /dev/null > /dev/null 2>&1; then
    local arg=-sbh
    else
    local arg=-sh
    fi
    if [[ -n "$@" ]]; then
    du $arg -- "$@"
    else
    du $arg .[^.]* *
    fi
}

# Start an HTTP server from a directory, optionally specifying the port
function server() {
    local port="${1:-8000}"
    sleep 1 && open "http://localhost:${port}/" &
    # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
    # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
    python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
}

# All the dig info
function digga() {
    dig +nocmd "$1" any +multiline +noall +answer
}

function shell_stats() {
    history 0 | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl |  head -n20
}

function is_ssh() {
    test $SSH_CLIENT
}

# TODO: Remove this.
alias clipboard='oscopy'

function oscopy() {
    if is_osx;
    then
        reattach-to-user-namespace pbcopy
    else
    test -n "$DISPLAY" && xclip -selection c
    fi
}

function ospaste() {
    if is_osx;
    then
        reattach-to-user-namespace pbpaste
    else
    xclip -o
    fi
}

function git_root() {
    cd "$(git root)"
}

function git_diff_replacing() {
    local original_sha='HEAD~1'
    local new_sha='HEAD'
    OPTIND=1
    while getopts "do:n:" OPTCHAR;
    do
        case $OPTCHAR in
            o)
                original_sha="$OPTARG"
                ;;
            n)
                new_sha="$OPTARG"
                ;;
            d)
                debug="true"
        esac
    done
    shift $((OPTIND-1))
    local replaced="$1"
    local replacing="$2"
    local replace_sha_string='$(echo filename | sed '"s:$replaced:$replacing:g"')'
    test -z $debug || echo "Diffing from $original_sha to $new_sha, replacing $replaced with $replacing"
    test -z $debug || git diff $original_sha $new_sha --name-only | grep -v "$replacing"
    git diff $original_sha $new_sha --name-only | grep -v "$replacing" | xargs -I filename sh -c "git diff $original_sha:filename $new_sha:"$replace_sha_string
}

function git_reset_author() {
    local should_update_command=''
    local update_command=''
    OPTIND=1
    while getopts "a:e:A:E:h" OPTCHAR;
    do
        case $OPTCHAR in
            a)
                new_author="$OPTARG";
                test -n "$update_command" && update_command="$update_command"' && '
                update_command="$update_command"'export GIT_AUTHOR_NAME='"'$new_author'"' && export GIT_COMMITTER_NAME='"'$new_author'"
                ;;
            A)
                author_regex="$OPTARG";
                test -n "$should_update_command" && should_update_command="$should_update_command"' && '
                should_update_command=$should_update_command'[[ "$GIT_AUTHOR_NAME" =~ "'"$author_regex"'" ]]'
                ;;
            e)
                new_email="$OPTARG";
                test -n "$update_command" && update_command="$update_command"' && '
                update_command="$update_command"'export GIT_AUTHOR_EMAIL='"'$new_email'"' && export GIT_COMMITTER_EMAIL='"'$new_email'"
                ;;
            E)
                email_regex="$OPTARG";
                test -n "$should_update_command" && should_update_command="$should_update_command"' && '
                should_update_command=$should_update_command'[[ "$GIT_AUTHOR_EMAIL" =~ "'"$email_regex"'" ]]'
                ;;
            h)
                echo "Usage:
-a specify the new author/committer name.
-A specify a regex that will be used to filter commits by author name.
-e specify the new author/committer email.
-E specify a regex that will be used to filter commits by author email.
-h show this help message.
"
                return
                ;;
        esac
    done
    local filter_branch_command="$should_update_command"' && '"$update_command"' || test true'
    git filter-branch -f --env-filter $filter_branch_command -- --all
}

alias git_reset_author_to_user='git_reset_author -a "$(git config --get user.name)" -e "$(git config --get user.email)" '
alias git_reset_author_from_user='git_reset_author -A "$(git config --get user.name)" -E "$(git config --get user.email)" '

function git_prune_all_history_involving {
    git filter-branch --force --index-filter \
        "git rm -r --cached --ignore-unmatch $1" \
        --prune-empty --tag-name-filter cat -- --all
}

function set_osx_hostname() {
    local new_hostname="${1-imalison}"
    sudo scutil --set ComputerName $new_hostname
    sudo scutil --set HostName $new_hostname
    sudo scutil --set LocalHostName $new_hostname
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string $new_hostname
}

function pip_package_location() {
    pip show $1 | grep Location | get_cols 2
}

function set_modifier_keys_on_all_keyboards() {
    for vendor_product_id in $(get_keyboard_vendor_id_product_id_pairs | tr " " "-"); do
        set_modifier_keys_for_vendor_product_id $vendor_product_id 0 2; echo $vendor_product_id;
    done;
}

function get_keyboard_vendor_id_product_id_pairs() {
    ioreg -n IOHIDKeyboard -r | grep -e 'class IOHIDKeyboard' -e VendorID\" -e Product | gawk 'BEGIN { RS = "class IOHIDKeyboard" } match($0, /VendorID. = ([0-9]*)/, arr) { printf arr[1]} match($0, /ProductID. = ([0-9]*)/, arr) { printf " %s\n", arr[1]} '
}

function git_config_string() {
    git config -f $1 --list | xargs -I kv printf '-c \"%s\" ' kv
}

function talk_dirty_to_me() {
    python - <<EOF
from random import randrange
import re
import urllib

def talk_dirty_to_me():
    socket = urllib.urlopen("http://www.youporn.com/random/video/")
    htmlSource = socket.read()
    socket.close()
    result = re.findall('<p class="message">((?:.|\\n)*?)</p>', htmlSource)
    if len(result):
        print result[randrange(len(result))]
    else:
        talk_dirty_to_me()

talk_dirty_to_me()
EOF
}

function dirty_talk() {
    while :
    do
        talk_dirty_to_me | tee >(cat) | say
    done
}

function track_modified {
    local timestamp_file="/tmp/__track_modified_timestamp__"
    touch $timestamp_file
    stat $timestamp_file
    echo "Press any key to execute find command"
    read -r key
    echo "Finding..."
    find $1 -cnewer "$timestamp_file"
}

function python_module_path {
    python -c "import os, $1; print(os.path.dirname($1.__file__))"
}

function mu4e_directory {
    if is_osx; then
        echo "$(brew --prefix mu)/share/emacs/site-lisp/mu4e"
    else
        # TODO: make this cleaner.
        echo "/usr/share/emacs/site-lisp/mu4e"
    fi
}

function timestamp {
    date +%s
}

function parse_timestamp {
    date -d "@$1"
}

function parse_timestamp2 {
    date -d "@$(echo $1 | cut -c -10)" -Iseconds
}

function clear_path {
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin"
    unset PATH_HELPER_RAN
    unset ENVIRONMENT_SETUP_DONE
}

function refresh_config {
    clear_path
    source ~/.zshenv
    source ~/.zshrc
}

function file_ends_with_newline {
    [[ $(tail -c1 "$1" | wc -l) -gt 0 ]]
}

function add_authorized_key_to_host {
    local command='test -e ~/.ssh/authorized_keys && [[ $(tail -c1 ~/.ssh/authorized_keys  | wc -l) -gt 0 ]] || echo "\n" >> ~/.ssh/authorized_keys;'"echo $(cat ~/.ssh/id_rsa.pub) >> ~/.ssh/authorized_keys"
    echo "Running:"
    echo $command
    ssh $1 "$command"
}

function add_ssh_key {
    [[ $(tail -c1 ~/.ssh/authorized_keys  | wc -l) -gt 0 ]] || echo "\n" >> ~/.ssh/authorized_keys;
    echo $1 >> ~/.ssh/authorized_keys;
}

function git_free_ssh_rsync {
    echo $1
    rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress --exclude=".git/" $(readlink -f "$1") $2:$1
}

function project_sync {
    git_free_ssh_rsync '~/Projects/'"$1"'/' $2
}

function android_sdk_directory {
    if is_osx; then
        brew --prefix android-sdk
    fi
}

function pkill_zsh {
    ps aux | grep "$1" | grep -v grep | get_cols 2 | xargs kill -9
}


function find_by_size {
    find . -type f -size +$1
}

function get_git_project_name {
    # "$(basename $(git rev-parse --show-toplevel))"
    basename $(git remotes | get_cols 2 | head -n 1)
}

function add_github_remote {
    local project_name="$(get_git_project_name)"
    git remote add "$1" "git@github.com:$1/$project_name"
}

function define_jump_alias_with_completion {
    eval "alias $1='jump_cd $2'"
    compdef "_files -g '$2/*'" $1
}

function jump_cd {
    if [[ $2 =~ ^/ ]]; then
        cd $2
    else
        cd $1
        cd $2
    fi
}

function source_if_exists {
    test -r "$1" && source "$1"
}

function python_module_exists {
    python_module_path $@ 1>/dev/null 2>/dev/null
}

function set_default_prompt {
    python_module_exists powerline && set_powerline_prompt || set_my_prompt
}

function edit_script {
    $EDITOR "$(which $1)"
}

function in_git_directory {
    [ -d .git ]
}

function process_running {
    [[ ! -z "$(pgrep $@)" ]]
}

function which_readlink {
    readlink -f "$(which $1)"
}

function localip {
    case `uname` in
        'Darwin')
            ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
            ;;
        'Linux')
			ip -4 addr | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1 | head -n 1
			# This was a nicer solution, but it returns ipv6 addresses on
            # machines that have them:
			# hostname --ip-address
            ;;
    esac
}

function all_lines_after {
    sed -n "/$1/"'$p'
}

function list_interfaces {
    ip link show | grep -vE '^ ' | get_cols -F ':' 2 | xargs -n 1
}

function all_after_char {
    while read -r line; do
          echo ${line##*$1}
    done;
}

function find_local_ssh_hosts {
	nmap -p 22 --open -sV 10.0.0.0/24 | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"
}

function rwhich {
	readlink -f $(which $1)
}
