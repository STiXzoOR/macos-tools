#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})

source $DIR/_plist_utils.sh

function updateConfig() {
# $1: EFI bootloader type (default: OC)
# $2: New config.plist
    if [[ -n "$1" ]]; then
        local bootloader="$1"
    else
        local bootloader="OC"
    fi

    EFI=$($DIR/mount_efi.sh)
    current_plist=$EFI/EFI/$bootloader/config.plist
    echo Updating config.plist at $current_plist
    replaceDict ":ACPI" "$current_plist" "$2"
    replaceDict ":Boot" "$current_plist" "$2"
    replaceDict ":Devices" "$current_plist" "$2"
    replaceDict ":KernelAndKextPatches" "$current_plist" "$2"
    replaceDict ":SystemParameters" "$current_plist" "$2"
    replaceVar ":RtVariables:BooterConfig" "$current_plist" "$2"
    replaceVar ":RtVariables:CsrActiveConfig" "$current_plist" "$2"
}

function installConfig() {
# $1: EFI bootloader type (default: OC)
# $1: New config.plist
    if [[ -n "$1" ]]; then
        local bootloader="$1"
    else
        local bootloader="OC"
    fi

    EFI=$($DIR/mount_efi.sh)
    current_plist=$EFI/EFI/$bootloader/config.plist
    echo "Copying $2 to $current_plist"
    cp "$2" $current_plist
}
