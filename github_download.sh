#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})

source $DIR/_download_cmds.sh

function showOptions() {
    echo "-a,  GitHub username (author)."
    echo "-r,  Repo (project) name."
    echo "-n,  Partial file name to look for."
    echo "-f,  Custom file name."
    echo "-o,  Output directory (default: $output_dir)."
    echo "-s,  Github source type (default: $url_type)."
    echo "-h,  Show this help menu."
    echo "Usage: $(basename $0) [-s <source>] [-a <author>] [-r <repo>] [-n <File name to look for>] [-o <output directory>] [-f <Custom file name>]"
    echo "Example: $(basename $0) -s api -a Acidanthera -r Lilu -o ~/Downloads -f Lilu"
}

while getopts a:r:n:f:o:s:h option; do
    case $option in
    a)
        author=$OPTARG
    ;;
    r)
        repo=$OPTARG
    ;;
    n)
        partial_name=$OPTARG
    ;;
    f)
        file_name=$OPTARG
    ;;
    o)
        output_dir=$OPTARG
    ;;
    s)
        source=$OPTARG
    ;;
    h)
        showOptions
        exit 0
    ;;
    esac
done

shift $((OPTIND-1))

if [[ -n "$author" && -n "$repo" ]]; then
    if [[ -n "$source" && "$source" == "api" ]]; then
        githubAPIDownload "$author" "$repo" "$output_dir" "$partial_name" "$file_name"
    else
        githubDownload "$author" "$repo" "$output_dir" "$partial_name" "$file_name"
else
    showOptions
    exit 1
fi
