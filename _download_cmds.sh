#!/bin/bash

output_dir=~/Downloads

hotpatch_repo="https://github.com/RehabMan/OS-X-Clover-Laptop-Config/raw/master/hotpatch"

function downloadSSDT() {
    # $1: SSDT name
    # $2: Output directory (optional)
    if [[ -d "$2" ]]; then
        local output_dir="$2"
    fi
    echo "Downloading $1 to $output_dir"
    url="$hotpatch_repo/$1"
    curl --progress-bar --location "$url" --output "$output_dir/$1"
}

function downloadAllHotpatchSSDTs() {
    # $1: Output directory (optional)
    if [[ -d "$output_dir" ]]; then
        local output_dir="$1"
    fi
    rm -Rf /tmp/Hotpatch.git
    git clone https://github.com/RehabMan/OS-X-Clover-Laptop-Config /tmp/Hotpatch.git -q 2>/dev/null
    cp /tmp/Hotpatch.git/hotpatch/*.dsl "$output_dir"
}

function bitbucketDownload() {
    # $1: Author
    # $2: Repo
    # $3: Output directory (optional)
    # $4: Partial file name to look for (optional)
    # $5: Custom file name (optional)
    if [[ -d "$3" ]]; then
        local output_dir="$3"
        if [[ -n "$4" ]]; then
            local partial_name="$4"
        fi
    elif [[ -n "$3" ]]; then
        local partial_name="$3"
    fi

    curl --silent --output /tmp/org.$1.download.txt --location https://bitbucket.org/$1/$2/downloads/
    scrape=$(grep -o -m 1 "$1/$2/downloads/$partial_name.*\.zip" /tmp/org.$1.download.txt | sed 's/".*//')

    if [[ -n "$5" ]]; then
        local fileName="$5.zip"
    else
        local fileName=$(basename $scrape)
    fi

    echo Downloading $fileName to $output_dir
    curl --progress-bar --location https://bitbucket.org/$scrape --output $output_dir/$fileName
}

function githubDownload() {
    # $1: Author
    # $2: Repo
    # $3: Output directory (optional)
    # $4: Partial file name to look for (optional)
    # $5: Custom file name (optional)
    if [[ -d "$3" ]]; then
        local output_dir="$3"
        if [[ -n "$4" ]]; then
            local partial_name="$4"
        fi
    elif [[ -n "$3" ]]; then
        local partial_name="$3"
    fi

    if [[ -n "$5" ]]; then
        local fileName="$5.zip"
    else
        local fileName="$1-$2.zip"
    fi

    curl --silent --location "https://github.com/$1/$2/releases" --output "/tmp/org.$1.download.txt"

    if [[ -n "$partial_name" ]]; then
        local scrape=$(grep -o -m 1 "/.*$partial_name.*\.zip" "/tmp/org.$1.download.txt")
    else
        local scrape=$(grep -o "/.*\.zip" "/tmp/org.$1.download.txt" | grep -m 1 -i -v "debug")
    fi

    echo Downloading $fileName to $output_dir
    curl --progress-bar --location https://github.com/$scrape --output $output_dir/$fileName
}

function githubAPIDownload() {
    # $1: Author
    # $2: Repo
    # $3: Output directory (optional)
    # $4: Partial file name to look for (optional)
    # $5: Custom file name (optional)
    if [[ -d "$3" ]]; then
        local output_dir="$3"
        if [[ -n "$4" ]]; then
            local partial_name="$4"
        fi
    elif [[ -n "$3" ]]; then
        local partial_name="$3"
    fi

    if [[ -n "$5" ]]; then
        local fileName="$1-$5.zip"
    else
        local fileName="$1-$2.zip"
    fi

    if [[ ! -f "/tmp/org.$1.$2.headers.txt" || $(find "/tmp/org.$1.$2.headers.txt" -mtime +1 -print) ]]; then
        curl -Is --location "https://api.github.com/repos/$1/$2/releases?per_page=100" --output "/tmp/org.$1.$2.headers.txt"
    fi

    if [[ ! -f "/tmp/org.$1.$2.download.txt" || $(find "/tmp/org.$1.$2.download.txt" -mtime +1 -print) ]]; then
        if [[ -f "/tmp/org.$1.$2.download.txt" ]]; then rm -Rf "/tmp/org.$1.$2.download.txt"; fi
        local pages=$(grep -o -m 1 '[/|&]page=.*>; rel="last"' "/tmp/org.$1.$2.headers.txt" | sed -E 's/.*&page=([^&]+)>; rel="last"/\1/')
        for ((page = 1; page <= $pages; page += 1)); do
            curl -s "https://api.github.com/repos/$1/$2/releases?page=$page&per_page=100"
        done >"/tmp/org.$1.$2.download.txt"
    fi

    if [[ -n "$partial_name" ]]; then
        local scrape=$(grep -o -m 1 "/.*$partial_name.*\.zip" "/tmp/org.$1.$2.download.txt")
    else
        local scrape=$(grep -o "/.*\.zip" "/tmp/org.$1.$2.download.txt" | grep -m 1 -i -v "debug")
    fi

    echo Downloading $fileName to $output_dir
    curl --progress-bar --location https:$scrape --output $output_dir/$fileName
}
