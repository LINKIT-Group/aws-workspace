NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
YELLOW="\[\e[1;33m\]"
CYAN="\[\e[1;36m\]"
DEV="\[\e[100m\]"

if [ ! -z "$SHOW_WARNING" ];then
    PS1=$YELLOW'${AWS_PROFILE}-'$RED'${PWD/*\//} $ '$NORMAL
else
    PS1=$YELLOW'${AWS_PROFILE}-'$NORMAL$GREEN'${PWD/*\//} $ '$NORMAL
fi
