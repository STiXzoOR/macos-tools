#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})
os_version="$(sw_vers -productVersion | cut -c1-5)"
helper_plist=org.stixzoor.MountSystem.plist

function mountSystem() {
    if [[ "$os_version" -ge "11" ]]; then
        sys_vol=""
        mount_dir=~/livemount
        for i in $(diskutil list | grep -E "[ ]+[0-9]+:.*disk[0-9]+" | sed 's/.*\(disk.*\)/\1/'); do
            mount_point=$(diskutil info $i | grep -i "Mount Point:" | awk '{ $1=""; $2=""; print }' | sed 's/^[ \t]*//;s/[ \t]*$//')
            if [[ "$mount_point" == "/" ]]; then
                sys_vol=$i
                break
            fi
        done

        if [[ "$sys_vol" == "" ]]; then
            echo -e "\n - ERROR: Couldn't found the system volume. Please verify that your system is working properly."
            exit 1
        fi

        echo -n "Mounting system root for Read/Write... "

        mkdir $mount_dir
        sudo mount -o nobrowse -t apfs /dev/$sys_vol $mount_dir

        echo "Done."
        echo -e "\n - NOTE: Once done editing the system volume, create a new snapshot by running:"
        echo -e "\nsudo bless --folder $mount_dir/System/Library/CoreServices --bootefi --create-snapshot"
    elif [[ "$os_version" -ge "10.15" ]]; then
        echo -n "Mounting system root for Read/Write... "

        sudo mount -uw /
        sudo killall Finder

        echo "Done."
    else
        echo -e "\n - ERROR: Mounting the system is only required on macOS 10.15 and greater"
        exit 1
    fi
}

function installMountSystemHelper() {
    if [[ "$os_version" -ge "10.15" && "$os_version" -lt "11" ]]; then
        echo -n "Installing MountSystem helper tool... "

        sudo cp -f "$DIR/$helper_plist" /Library/LaunchDaemons/
        sudo chmod 644 /Library/LaunchDaemons/$helper_plist
        sudo chown root:wheel /Library/LaunchDaemons/$helper_plist

        sudo launchctl load /Library/LaunchDaemons/$helper_plist

        echo "Done."
    else
        echo -e "\n- ERROR: This is only for use on macOS 10.15 and greater"
        exit 1
    fi
}
