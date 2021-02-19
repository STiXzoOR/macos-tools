#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})
os_version="$(sw_vers -productVersion | cut -c1-5)"
helper_plist=org.stixzoor.MountSystem.plist

function mountSystem() {
    if [[ "$os_version" -ge "11" ]]; then
        mount_dir=~/livemount
        sys_vol=$(diskutil apfs list | grep -i "(System)" | awk '{ print $6 }')

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
