#!/bin/bash

set -eufo pipefail

prog=$(basename "$0")
plist="com.mitchellkember.minster.plist"
dest_plist="$HOME/Library/LaunchAgents/$plist"

action="install"

say() {
    echo " * $*"
}

die() {
    echo "$prog: $*" >&2
    exit 1
}

usage() {
    cat <<EOS
usage: $prog [-hsu]

installs Minster using launchd

options:
    -h  show this help message
    -s  check if it is installed
    -u  uninstall
EOS
}

do_install() {
    say "Installing launchd $plist"
    cd "$(dirname "$0")"
    [[ -f "./$plist" ]] || die "$plist: file not found"
    say "Copying to $dest_plist"
    cp "./$plist" "$dest_plist"
    spath="$(cd "$(dirname "$0")" && pwd)/minster.sh"
    tpath=$(command -v "timidity")
    [[ -n "$tpath" ]] || die "could not find timidity"
    sed -i -e "s#%SCRIPT_PATH%#$spath#" "$dest_plist"
    sed -i -e "s#%TIMIDITY_PATH%#$tpath#" "$dest_plist"
    say "Loading $dest_plist"
    launchctl unload "$dest_plist"
    launchctl load "$dest_plist"
    say "Success"
}

do_status() {
    if [[ -f "$dest_plist" ]]; then
        if launchctl list "${plist%.plist}" > /dev/null 2>&1; then
            say "Minster is installed"
        else
            say "Minster is not installed"
            say "note: $dest_plist is present but not loaded"
        fi
    else
        say "Minster is not installed"
    fi
}

do_uninstall() {
    say "Uninstalling launchd $plist"
    if ! [[ -f "$dest_plist" ]]; then
        say "Minster is not installed"
    else
        launchctl unload "$dest_plist"
        rm "$dest_plist"
        say "Success"
    fi
}

main() {
    "do_$action"
}

while getopts "hsu" opt; do
    case $opt in
        h) usage ; exit 0 ;;
        s) action="status" ;;
        u) action="uninstall" ;;
        *) exit 1 ;;
    esac
done

main
