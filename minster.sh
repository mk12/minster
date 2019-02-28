#!/bin/bash

set -eufo pipefail

prog=$(basename "$0")

force=false
fix_quarter=
fix_hour=

say() {
    echo " * $*"
}

die() {
    echo "$prog: $*" >&2
    exit 1
}

usage() {
    cat <<EOS
usage: $prog [-hf] [-b HOUR | -q QUARTER]

plays Westminster chimes

options:
    -h          show this help message
    -f          skip checks
    -b HOUR     chime the given hour
    -q QUARTER  chime the given quarter
EOS
}

check_should_chime() {
    if ! [[ $(pmset -g ps | head -1) =~ "AC Power" ]]; then
        die "not on AC power"
    fi
}

chime_hour() {
    say "chiming hour $1"
}

chime_quarter() {
    say "chiming quarter $1"
}

main() {
    if [[ "$force" == true ]]; then
        say "force mode: skipping checks"
    else
        check_should_chime
    fi

    if [[ -n "$fix_quarter" && -n "$fix_hour" ]]; then
        die "cannot chime both quarter and hour"
    fi
    if [[ -n "$fix_quarter" ]]; then
        if [[ "$fix_quarter" -lt 1 && "$fix_quarter" -gt 3 ]]; then
            die "invalid quarter: $fix_quarter"
        fi
        chime_quarter "$fix_quarter"
        exit 0
    fi
    if [[ -n "$fix_hour" ]]; then
        if [[ "$fix_hour" -lt 1 && "$fix_hour" -gt 12 ]]; then
            die "invalid hour: $fix_hour"
        fi
        chime_hour "$fix_hour"
        exit 0
    fi

    time=$(date +%r)
    hour=$(cut -d: -f1 <<< "$time")
    minute=$(cut -d: -f2 <<< "$time")
    if [[ "$minute" -eq 0 ]]; then
        chime_hour "$hour"
    elif [[ "$minute" -eq 15 ]]; then
        chime_quarter 1
    elif [[ "$minute" -eq 30 ]]; then
        chime_quarter 2
    elif [[ "$minute" -eq 45 ]]; then
        chime_quarter 3
    else
        die "invalid time: $time"
    fi
}

while getopts "hfb:q:" opt; do
    case $opt in
        h) usage ; exit 0 ;;
        f) force=true ;;
        b) fix_quarter=$OPTARG ;;
        b) fix_hour=$OPTARG ;;
        *) exit 1 ;;
    esac
done
shift $((OPTIND - 1))
[[ $# -eq 0 ]] || die "too many arguments"

main
