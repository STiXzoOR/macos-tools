#!/bin/bash

DIR=$(dirname ${BASH_SOURCE[0]})

source $DIR/_download_cmds.sh

function showOptions() {
    echo "-a,  Bitbucket username (author)."
    echo "-r,  Repo (project) name."
    echo "-n,  Partial file name to look for."
    echo "-f,  Custom file name."
    echo "-o,  Output directory (default: $output_dir)."
    echo "-h,  Show this help menu."
    echo "Usage: $(basename $0) [-a <author>] [-r <repo>] [-n <File name to look for>] [-o <output directory>] [-f <Custom file name>]"
    echo "Example: $(basename $0) -a RehabMan -r os-x-fakesmc-kozlek -o ~/Downloads -f FakeSMC"
}

while getopts a:r:n:f:o:h option; do
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
    h)
        showOptions
        exit 0
    ;;
    esac
done

shift $((OPTIND-1))

if [[ -n "$author" && -n "$repo" ]]; then
    bitbucketDownload "$author" "$repo" "$output_dir" "$partial_name" "$file_name"
else
    showOptions
    exit 1
fi
