#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})

source $DIR/_install_cmds.sh

function showOptions() {
    echo "-d,  Directory to install all apps within."
    echo "-s,  Destination directory (default: $apps_dest)."
    echo "-e,  Exceptions list (single string) when installing multiple apps."
    echo "-h,  Show this help message."
    echo "Usage: $(basename $0) [Options] [App to install]"
    echo "Example: $(basename $0) ~/Downloads/VLC.app"
}

while getopts e:s:d:h option; do
    case $option in
    e)
        exceptions=$OPTARG
        ;;
    s)
        apps_dest=$OPTARG
        ;;
    d)
        directory=$OPTARG
        ;;
    h)
        showOptions
        exit 0
        ;;
    esac
done

shift $((OPTIND - 1))

if [[ -d "$directory" ]]; then
    installAppsInDirectory "$directory" "$apps_dest" "$exceptions"
elif [[ -d "$1" ]]; then
    installApp "$1"
else
    showOptions
    exit 1
fi
