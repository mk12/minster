#!/bin/bash

set -eufo pipefail

prog=$(basename "$0")

the_quarter=
the_hour=
midi_dir=$(cd "$(dirname "$0")" && pwd)/midi

say() {
    echo " * $*"
}

die() {
    echo "$prog: $*" >&2
    exit 1
}

usage() {
    cat <<EOS
usage: $prog [-h] [-q QUARTER | -s HOUR | -S HOUR] [-m DIR]

plays Westminster chimes

Without any options, checks the current times and chimes if it is HH:00, HH:15,
HH:30, or HH:45. Otherwise, does nothing.

options:
    -h          show this help message
    -q QUARTER  chime the quarter (1-4)
    -s HOUR     strike the hour (1-12)
    -S HOUR     chime 4th quarter and strike the hour (1-12)
    -m DIR      specify the MIDI directory
EOS
}

play_midi() {
    timidity "$midi_dir/$1.midi" > /dev/null 2>&1
}

chime_part() {
    play_midi "p$1"
}

chime_parts() {
    for n in "$@"; do
        chime_part $n &
        if [[ "$n" == "${!#}" ]]; then
            sleep 5
        else
            sleep 3
        fi
    done
}

chime_quarter() {
    say "chiming quarter $1"
    case $1 in
        1) chime_part 1 ;;
        2) chime_parts 2 3 ;;
        3) chime_parts 4 5 1 ;;
        4) chime_parts 2 3 4 5 ;;
        *) die "invalid quarter: $1" ;;
    esac
}

strike_hour() {
    say "striking hour $1"
    count=$1
    while [[ "$count" -gt 0 ]]; do
        play_midi "hour" &
        sleep 2
        ((count--))
    done
}

check_arguments() {
    if [[ -d "$midi_dir" ]]; then
        say "using MIDI dir $midi_dir"
    else
        die "$midi_dir: directory does not exist"
    fi

    if [[ -n "$the_quarter" ]]; then
        if [[ "$the_quarter" -lt 1 && "$the_quarter" -gt 4 ]]; then
            die "$the_quarter: invalid quarter"
        fi
    fi
    if [[ -n "$the_hour" ]]; then
        if [[ "$the_hour" -lt 1 || "$the_hour" -gt 12 ]]; then
            die "$the_hour: invalid hour"
        fi
    fi
}

infer_from_time() {
    time=$(date +%r)
    hour=$(cut -d: -f1 <<< "$time")
    minute=$(cut -d: -f2 <<< "$time")
    if [[ "$minute" -eq 0 ]]; then
        the_quarter=4
        the_hour=$hour
    elif [[ "$minute" -eq 15 ]]; then
        the_quarter=1
    elif [[ "$minute" -eq 30 ]]; then
        the_quarter=2
    elif [[ "$minute" -eq 45 ]]; then
        the_quarter=3
    else
        die "invalid time: $time"
    fi

    ident=$(date +"%Y-%m-%d.%H:%M")
    data_dir=${XDG_DATA_HOME:-$HOME/.local/share}/minster
    mkdir -p "$data_dir"
    file="$data_dir/last"
    if [[ -f "$file" ]]; then
        content=$(< "$file")
        if [[ "$ident" == "$content" ]]; then
            die "skipping duplicate chime: entry $ident exists"
        fi
    fi
    echo "$ident" > "$file"
}

main() {
    check_arguments
    if [[ -z "$the_quarter" && -z "$the_hour" ]]; then
        infer_from_time
    fi

    [[ -n "$the_quarter" ]] && chime_quarter "$the_quarter"
    [[ -n "$the_hour" ]] && strike_hour "$the_hour"
    wait
}

while getopts "hq:s:S:m:" opt; do
    case $opt in
        h) usage ; exit 0 ;;
        q) the_quarter=$OPTARG ;;
        s) the_hour=$OPTARG ;;
        S) the_quarter=4 ; the_hour=$OPTARG ;;
        m) midi_dir=$OPTARG ;;
        *) exit 1 ;;
    esac
done
shift $((OPTIND - 1))
[[ $# -eq 0 ]] || die "too many arguments"

main
