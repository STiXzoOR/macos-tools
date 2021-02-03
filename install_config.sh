#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})

source $DIR/_config_cmds.sh

function showOptions() {
    echo "-b,  Specify EFI bootloader (default: OC)."
    echo "-u,  Update only relevant settings (Preserve user settings like SMBIOS, etc)."
    echo "-h,  Show this help message."
    echo "Usage: $(basename $0) [Options] [New config.plist]"
    echo "Example: $(basename $0) -b CLOVER -u ~/Downloads/config.plist"
}

while getopts b:uh option; do
    case $option in
    b)
        bootloader=$OPTARG
        ;;
    u)
        update=1
        ;;
    h)
        showOptions
        exit 0
        ;;
    esac
done

shift $((OPTIND - 1))

if [[ -e "$1" ]]; then
    if [[ -n "$update" ]]; then
        updateConfig "$bootloader" "$1"
    else
        installConfig "$bootloader" "$1"
    fi
else
    showOptions
    exit 1
fi
