#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})

source $DIR/_system_cmds.sh

function showOptions() {
    echo "-m,  Mount system root for Read/Write"
    echo "-i,  Install helper daemon to mount the system on boot."
    echo "-h,  Show this help message."
    echo "Usage: $(basename $0) [Options]"
    echo "Example: $(basename $0) -i"
}

while getopts mih option; do
    case $option in
        i)
            install=1
        ;;
        m)
            mount=1
        ;;
        h)
            showOptions
            exit 0
        ;;
    esac
done

shift $((OPTIND-1))

if [[ -n "$mount" ]]; then
    mountSystem
elif [[ -n "$install" ]]; then
    installMountSystemHelper
else
    showOptions
    exit 1
fi
