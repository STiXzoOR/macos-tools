#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})
os_version="$(sw_vers -productVersion | cut -c1-5)"
helper_plist=org.stixzoor.MountSystem.plist

function mountSystem() {
    if [[ "${os_version}" >= "10.15" ]]; then
        echo "Mounting system root for Read/Write"

        sudo mount -uw /
        sudo killall Finder
    else
        echo "Mounting the system is only required on macOS 10.15 and greater"
        exit 1
    fi
}

function installMountSystemHelper() {
    if [[ "${os_version}" >= "10.15" ]]; then
        echo "Installing MountSystem helper tool"

        sudo cp -f "$DIR/$helper_plist" /Library/LaunchDaemons/
        sudo chmod 644 /Library/LaunchDaemons/$helper
        sudo chown root:wheel /Library/LaunchDaemons/$helper

        sudo launchctl load /Library/LaunchDaemons/$helper
    else
        echo "This is only for use on macOS 10.15 and greater"
        exit 1
    fi
}