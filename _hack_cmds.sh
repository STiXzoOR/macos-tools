#!/bin/bash

tools_dir=$(dirname ${BASH_SOURCE[0]})
repo_dir=$(dirname $0)

source $tools_dir/_system_cmds.sh
source $tools_dir/_download_cmds.sh
source $tools_dir/_install_cmds.sh
source $tools_dir/_archive_cmds.sh
source $tools_dir/_config_cmds.sh
source $tools_dir/_hda_cmds.sh
source $tools_dir/_lilu_helper.sh

downloads_dir=$repo_dir/Downloads
hotpatch_dir=$repo_dir/Hotpatch/Downloads
local_kexts_dir=$repo_dir/Kexts
build_dir=$repo_dir/Build

tools_config=$tools_dir/org.stixzoor.config.plist

if [[ -z "$repo_plist" ]]; then
    if [[ -e "$repo_dir/repo_config.plist" ]]; then
        repo_plist=$repo_dir/repo_config.plist
        bootloader=$(printValue "Bootloader" "$repo_plist" 2> /dev/null)
    else
        echo "No repo_config.plist file found. Exiting..."
        exit 1
    fi
fi

if [[ -z "$config_plist" ]]; then
    if [[ -e "$repo_dir/config.plist" ]]; then
        config_plist=$repo_dir/config.plist
    else
        echo "No config.plist file found. Exiting..."
        exit 2
    fi
fi

function installAppWithName() {
# $1: App name
    app=$(findApp "$1" "$downloads_dir")
    if [[ -e "$app" ]]; then
        installApp "$app"
    fi
}

function installKextWithName() {
# $1: Kext name
    kext=$(findKext "$1" "$downloads_dir" "$local_kexts_dir")
    if [[ -e "$kext" ]]; then
        installKext "$kext"
    fi
}

function installToolWithName() {
# $1: Tool name
    tool=$(findTool "$1" "$downloads_dir")
    if [[ -e "$tool" ]]; then
        installTool "$tool"
    fi
}

function installEssentialKextWithName() {
# $1: Kext name
# $2: Output directory (optional)
    if [[ ! -d "$efi" ]]; then efi=$($tools_dir/mount_efi.sh); fi
    if [[ -n "$2" ]]; then 
        local output_dir=$2 
    else 
        local output_dir=$efi/EFI/OC/kexts 
    fi
    kext=$(findKext "$2" "$downloads_dir" "$local_kexts_dir")
    if [[ -e "$kext" ]]; then
        installKext "$kext" "$output_dir"
    fi
}

case "$1" in
    --download-requirements)
        rm -Rf $downloads_dir && mkdir -p $downloads_dir
        rm -Rf $hotpatch_dir && mkdir -p $hotpatch_dir

        # Bitbucket downloads
        for ((index=0; 1; index++)); do
            author=$(printValue "Downloads:Bitbucket:$index:Author" "$repo_plist")
            repo=$(printValue "Downloads:Bitbucket:$index:Repo" "$repo_plist")
            if [[ $? -ne 0 ]]; then break; fi
            name=$(printValue "Downloads:Bitbucket:$index:Name" "$repo_plist" 2> /dev/null)
            file_name=$(printValue "Downloads:Bitbucket:$index:Filename" "$repo_plist" 2> /dev/null)
            bitbucketDownload "$author" "$repo" "$downloads_dir" "$name" "$file_name"
        done

        # GitHub downloads
        for ((index=0; 1; index++)); do
            author=$(printValue "Downloads:GitHub:$index:Author" "$repo_plist")
            repo=$(printValue "Downloads:GitHub:$index:Repo" "$repo_plist")
            if [[ $? -ne 0 ]]; then break; fi
            source=$(printValue "Downloads:GitHub:$index:Source" "$repo_plist" 2> /dev/null)
            name=$(printValue "Downloads:GitHub:$index:Name" "$repo_plist" 2> /dev/null)
            file_name=$(printValue "Downloads:GitHub:$index:Filename" "$repo_plist" 2> /dev/null)

            if [[ "$source" == "api" ]]; then
                githubAPIDownload "$author" "$repo" "$downloads_dir" "$name" "$file_name"
            else
                githubDownload "$author" "$repo" "$downloads_dir" "$name" "$file_name"
            fi
        done

        if [[ -n "$bootloader" && "$bootloader" == "CLOVER" ]]; then
            # Hotpatch SSDT downloads
            downloadAllHotpatchSSDTs "$hotpatch_dir"
        fi
    ;;
    --install-apps)
        unarchiveAllInDirectory "$downloads_dir"

        # GitHub apps
        for ((downloadIndex=0; 1; downloadIndex++)); do
            download=$(printValue "Downloads:GitHub:$downloadIndex" "$repo_plist" 2> /dev/null)
            if [[ $? -ne 0 ]]; then break; fi
            for ((installIndex=0; 1; installIndex++)); do
                name=$(printValue "Downloads:GitHub:$downloadIndex:Installations:Apps:$installIndex:Name" "$repo_plist" 2> /dev/null)
                if [[ $? -ne 0 ]]; then break; fi
                installAppWithName "$name"
            done
        done

        # Bitbucket apps
        for ((downloadIndex=0; 1; downloadIndex++)); do
            download=$(printValue "Downloads:Bitbucket:$downloadIndex" "$repo_plist" 2> /dev/null)
            if [[ $? -ne 0 ]]; then break; fi
            for ((installIndex=0; 1; installIndex++)); do
                name=$(printValue "Downloads:Bitbucket:$downloadIndex:Installations:Apps:$installIndex:Name" "$repo_plist" 2> /dev/null)
                if [[ $? -ne 0 ]]; then break; fi
                installAppWithName "$name"
            done
        done
    ;;
    --install-tools)
        unarchiveAllInDirectory "$downloads_dir"

        # GitHub tools
        for ((downloadIndex=0; 1; downloadIndex++)); do
            download=$(printValue "Downloads:GitHub:$downloadIndex" "$repo_plist" 2> /dev/null)
            if [[ $? -ne 0 ]]; then break; fi
            for ((installIndex=0; 1; installIndex++)); do
                name=$(printValue "Downloads:GitHub:$downloadIndex:Installations:Tools:$installIndex:Name" "$repo_plist" 2> /dev/null)
                if [[ $? -ne 0 ]]; then break; fi
                installToolWithName "$name"
            done
        done

        # Bitbucket tools
        for ((downloadIndex=0; 1; downloadIndex++)); do
            download=$(printValue "Downloads:Bitbucket:$downloadIndex" "$repo_plist" 2> /dev/null)
            if [[ $? -ne 0 ]]; then break; fi
            for ((installIndex=0; 1; installIndex++)); do
                name=$(printValue "Downloads:Bitbucket:$downloadIndex:Installations:Tools:$installIndex:Name" "$repo_plist" 2> /dev/null)
                if [[ $? -ne 0 ]]; then break; fi
                installToolWithName "$name"
            done
        done
    ;;
    --install-kexts)
        if [[ -n "$bootloader" && "$bootloader" == "CLOVER" ]]; then
            unarchiveAllInDirectory "$downloads_dir"

            # GitHub kexts
            for ((downloadIndex=0; 1; downloadIndex++)); do
                download=$(printValue "Downloads:GitHub:$downloadIndex" "$repo_plist" 2> /dev/null)
                if [[ $? -ne 0 ]]; then break; fi
                for ((installIndex=0; 1; installIndex++)); do
                    name=$(printValue "Downloads:GitHub:$downloadIndex:Installations:Kexts:$installIndex:Name" "$repo_plist" 2> /dev/null)
                    if [[ $? -ne 0 ]]; then break; fi
                    installKextWithName "$name"
                done
            done

            # Bitbucket kexts
            for ((downloadIndex=0; 1; downloadIndex++)); do
                download=$(printValue "Downloads:Bitbucket:$downloadIndex" "$repo_plist" 2> /dev/null)
                if [[ $? -ne 0 ]]; then break; fi
                    for ((installIndex=0; 1; installIndex++)); do
                    name=$(printValue "Downloads:Bitbucket:$downloadIndex:Installations:Kexts:$installIndex:Name" "$repo_plist" 2> /dev/null)
                    if [[ $? -ne 0 ]]; then break; fi
                    installKextWithName "$name"
                done
            done

            # Local kexts
            for ((index=0; 1; index++)); do
                name=$(printValue "Local Installations:Kexts:$index:Name" "$repo_plist" 2> /dev/null)
                if [[ $? -ne 0 ]]; then break; fi
                installKextWithName "$name"
            done
        fi
    ;;
    --install-essential-kexts)
        unarchiveAllInDirectory "$downloads_dir"
        EFI=$($tools_dir/mount_efi.sh)

        if [[ -n "$bootloader" && "$bootloader" == "CLOVER" ]]; then
            efi_kexts_dest=$EFI/EFI/$bootloader/kexts/Other
        else
            efi_kexts_dest=$EFI/EFI/OC/kexts
        fi
        
        rm -Rf $efi_kexts_dest/*.kext

        # GitHub kexts
        for ((downloadIndex=0; 1; downloadIndex++)); do
            download=$(printValue "Downloads:GitHub:$downloadIndex" "$repo_plist" 2> /dev/null)
            if [[ $? -ne 0 ]]; then break; fi
            for ((installIndex=0; 1; installIndex++)); do
                name=$(printValue "Downloads:GitHub:$downloadIndex:Installations:Kexts:$installIndex:Name" "$repo_plist" 2> /dev/null)
                if [[ $? -ne 0 ]]; then break; fi
                essential=$(printValue "Downloads:GitHub:$downloadIndex:Installations:Kexts:$installIndex:Essential" "$repo_plist" 2> /dev/null)
                if [[ "$essential" == "true" ]]; then
                    installEssentialKextWithName "$name" "$efi_kexts_dest"
                fi
            done
        done

        # Bitbucket kexts
        for ((downloadIndex=0; 1; downloadIndex++)); do
            download=$(printValue "Downloads:Bitbucket:$downloadIndex" "$repo_plist" 2> /dev/null)
            if [[ $? -ne 0 ]]; then break; fi
            for ((installIndex=0; 1; installIndex++)); do
                name=$(printValue "Downloads:Bitbucket:$downloadIndex:Installations:Kexts:$installIndex:Name" "$repo_plist" 2> /dev/null)
                if [[ $? -ne 0 ]]; then break; fi
                essential=$(printValue "Downloads:Bitbucket:$downloadIndex:Installations:Kexts:$installIndex:Essential" "$repo_plist" 2> /dev/null)
                if [[ "$essential" == "true" ]]; then
                    installEssentialKextWithName "$name" "$efi_kexts_dest"
                fi
            done
        done

        # Local kexts
        for ((index=0; 1; index++)); do
            name=$(printValue "Local Installations:Kexts:$index:Name" "$repo_plist" 2> /dev/null)
            if [[ $? -ne 0 ]]; then break; fi
            essential=$(printValue "Local Installations:Kexts:$index:Essential" "$repo_plist" 2> /dev/null)
            if [[ "$essential" == "true" ]]; then
                installEssentialKextWithName "$name" "$efi_kexts_dest"
            fi
        done
    ;;
    --remove-installed-kexts)
        if [[ -n "$bootloader" && "$bootloader" == "CLOVER" ]]; then
            for kext in $(printInstalledItems "Kexts"); do
                removeKext "$kext"
            done
        fi
    ;;
    --remove-installed-apps)
        for app in $(printInstalledItems "Apps"); do
            removeApp "$app"
        done
    ;;
    --remove-installed-tools)
        for tool in $(printInstalledItems "Tools"); do
            removeTool "$tool"
        done
    ;;
    --remove-deprecated-kexts)
        if [[ -n "$bootloader" && "$bootloader" == "CLOVER" ]]; then
            # To override default list of deprecated kexts in macos-tools/org.stixzoor.deprecated.plist, set 'Deprecated:Override Defaults' to 'true'.
            override=$(printValue "Deprecated:Override Defaults" "$repo_plist" 2> /dev/null)
            if [[ "$override" != "true" ]]; then
                for kext in $(printArrayItems "Deprecated:Kexts" "$tools_config" 2> /dev/null); do
                    removeKext "$kext"
                done
            fi
            for kext in $(printArrayItems "Deprecated:Kexts" "$repo_plist" 2> /dev/null); do
                removeKext "$kext"
            done
        fi
    ;;
    --install-config)
        installConfig "$bootloader" "$config_plist"
    ;;
    --update-config)
        updateConfig "$bootloader" "$config_plist"
    ;;
    --update-kernelcache)
        sudo kextcache -i /
    ;;
    --install-lilu-helper)
        if [[ -n "$bootloader" && "$bootloader" == "CLOVER" ]]; then
            if [[ ! -d "$build_dir" ]]; then mkdir $build_dir; fi
            createLiluHelper "$build_dir"
            installKext "$build_dir/LiluHelper.kext"
        fi
    ;;
    --mount-system)
        mountSystem
    ;;
    --install-mount-system-helper)
        installMountSystemHelper
    ;;
    --update)
        echo "Checking for updates..."
        git stash --quiet && git pull
        echo "Checking for macos-tools updates..."
        cd $tools_dir && git stash --quiet && git pull && cd ..
    ;;
    --install-downloads)
        $0 --install-tools
        $0 --install-apps
        $0 --remove-deprecated-kexts
        $0 --install-essential-kexts
        $0 --install-kexts
        $0 --install-lilu-helper
        $0 --update-kernelcache
    ;;
esac
