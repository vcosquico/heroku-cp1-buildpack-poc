#!/bin/bash


if [ -n "$SSH_KEY_VALUE" ]; then
    echo "$SSH_KEY_VALUE" > /tmp/.git_key.$$
    chmod 600 /tmp/.git_key.$$
    echo "ssh -o ServerAliveInterval=10 -o ServerAliveCountMax=2  -o ControlMaster=no -oControlPersist=no -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o TCPKeepAlive=no -o BatchMode=yes -i /tmp/.git_key.$$ \$@" > /tmp/.git_ssh.$$
    chmod +x /tmp/.git_ssh.$$
    export GIT_SSH=/tmp/.git_ssh.$$
fi

# the remote action will block when the speed kept below 1KB/s for 600 seconds(10min), the action will block.
export GIT_HTTP_LOW_SPEED_LIMIT=1000
export GIT_HTTP_LOW_SPEED_TIME=600

#export GIT_TRACE=1 # for debugging only.

# in case the git command is repeated
[ "$1" = "git" ] && shift

# Run the git command
# skip annoying logs if the git action is unimportant
if [[ "$git_action" == "config" || "$git_action" == "reset" ]]; then
    git "$@"
    T=$?
    exit $T
fi

export HOME= # disable reading .gitconfig
export GIT_CONFIG_NOSYSTEM=1 # if set, disables the use of the system-wide configuration file ( /etc/ )

# Run the git command
time git "$@"
T=$?

# if the ssh process that git started did not die (if it is ssh only).
if [[ -n "${GIT_SSH}" ]]; then
    GITPID=$(pgrep -f "$GIT_SSH")
    if [[ -n "${GITPID}" ]]; then
        echo "## Looking for process $GITPID $GIT_SSH $(pgrep -l -f $GIT_SSH) and killing zero or more: $(pgrep -P $GITPID -l)"
        pkill -P $GITPID
    fi
fi

(>&2 pwd && du -xsmch /tmp/jobRepository) # print the current working dir, its total size, and the size of the subdirs
exit $T
