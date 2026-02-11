# If we're connected via SSH, try to connect to the last screen session
if ([ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]) && [ -z "$STY" ]; then
  SESSION_TYPE=remote/ssh
else
    case $(ps -o comm= -p $PPID) in
        sshd|*/sshd) SESSION_TYPE=remote/ssh;;
    esac
fi

if [ "$SESSION_TYPE" = "remote/ssh" ]; then
    screen -qAUODR
fi

#if [[ -n $SSH_CONNECTION ]]; then
#    screen -qAUODR
#fi
