#!/bin/bash

set -eufo pipefail

# Globals
prog=$(basename "$0")
xdg_data_dir=${XDG_DATA_HOME:-$HOME/.local/share}/minster
xdg_config_dir=${XDG_CONFIG_HOME:-$HOME/.config}/minster

# Command-line options
the_quarter=
the_hour=
midi_dir="$(cd "$(dirname "$0")" && pwd)/midi"
timidity_path=$(command -v "timidity" || true)
config_path="$xdg_config_dir/config.ini"
explicit_config_path=false

# Config options
stop_music=false
volume_factor=100
check_screen=false
instrument="tubular"

# Other globals
music_state=
instrument_code=

instrument_names=(
    "piano"
    "brpiano"
    "harpsichord"
    "xylophone"
    "tubular"
    "harp"
    "ocarina"
)

# http://fmslogo.sourceforge.net/manual/midi-instrument.html
instrument_codes=("00" "01" "06" "0d" "0e" "2e" "4f")

say() {
    echo " * $*"
}

die() {
    echo "$prog: $*" >&2
    exit 1
}

default() {
    if [[ -n "${!1}" ]]; then
        p=$(sed -e "s#^$HOME#~#" <<< "${!1}")
        echo "(default: $p)"
    fi
}

usage() {
    cat <<EOS
usage: $prog [-h] [-q QUARTER | -s HOUR | -S HOUR] [-m DIR] [-t PATH] [-c FILE]
             [-i instrument]

plays Westminster chimes

Without any options, checks the current times and chimes if it is HH:00, HH:15,
HH:30, or HH:45. Otherwise, does nothing.

options:
    -h          show this help message
    -q QUARTER  chime the quarter (1-4)
    -s HOUR     strike the hour (1-12)
    -S HOUR     chime 4th quarter and strike the hour (1-12)
    -m DIR      specify the MIDI directory $(default midi_dir)
    -t PATH     specify the path to timidity $(default timidity_path)
    -c FILE     specify the config file $(default config_path)
    -i NAME     specify the instrument to use
EOS
}

play_midi() {
    if [[ "$instrument" == "tubular" ]]; then
        "$timidity_path" --volume "$volume_factor" "$midi_dir/$1.midi" \
            > /dev/null 2>/dev/null
    else
        xxd -g1 "$midi_dir/$1.midi" | sed "s/0e/$instrument_code/" \
            | xxd -r | "$timidity_path" --volume "$volume_factor" - \
            > /dev/null 2>/dev/null
    fi
}

chime_part() {
    play_midi "p$1"
}

chime_parts() {
    for n in "$@"; do
        chime_part $n &
        sleep 3
    done
}

chime_quarter() {
    say "chiming quarter $1"
    case $1 in
        1) chime_parts 1 ;;
        2) chime_parts 2 3 ;;
        3) chime_parts 4 5 1 ;;
        4) chime_parts 2 3 4 5 ;;
        *) die "invalid quarter: $1" ;;
    esac
}

strike_hour() {
    [[ -n "$the_quarter" ]] && sleep 2
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

    if [[ -x "$timidity_path" ]]; then
        say "using timidity path $timidity_path"
    elif [[ -z "$timidity_path" ]]; then
        die "could not find timidity; specify it with -t"
    else
        die "$timidity_path: executable does not exist"
    fi

    if [[ "$explicit_config_path" == true && ! -f "$config_path" ]]; then
        die "$config_path: no such file"
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
    say "current time: $(date)"
    time=$(date +%r)
    hour=$(cut -d: -f1 <<< "$time")
    minute=$(cut -d: -f2 <<< "$time")
    hour=${hour#0}
    minute=${minute#0}
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
        die "$time: not a chiming time"
    fi

    ident=$(date +"%Y-%m-%d.%H:%M")
    mkdir -p "$xdg_data_dir"
    file="$xdg_data_dir/last"
    if [[ -f "$file" ]]; then
        content=$(< "$file")
        if [[ "$ident" == "$content" ]]; then
            die "skipping duplicate chime: entry $ident exists"
        fi
    fi
    echo "$ident" > "$file"
}

stop_music() {
    itunes_open=$(osascript <<EOS
tell application "System Events" to (name of processes) contains "iTunes"
EOS
    )
    [[ "$itunes_open" == "true" ]] || return 0
    music_state=$(osascript <<EOS
tell application "iTunes" to get player state
EOS
    )
    [[ "$music_state" == "playing" ]] || return 0
    say "pausing iTunes"
    osascript <<EOS
tell application "iTunes"
    repeat with i from 1 to 20
        set sound volume to 100 - (i * 5)
        delay 0.05
    end repeat
    pause
end tell
EOS
}

restore_music() {
    if [[ "$music_state" == "playing" ]]; then
        sleep 2
        say "resuming iTunes"
        osascript <<EOS
tell application "iTunes"
    play
    repeat with i from 1 to 20
        set sound volume to (i * 5)
        delay 0.05
    end repeat
end tell
EOS
    fi
}

check_should_chime() {
    if [[ "$check_screen" == true ]]; then
        # https://apple.stackexchange.com/a/103346
        val=$(ioreg -n IODisplayWrangler \
            | grep -i IOPowerManagement \
            | perl -pe 's/^.*DevicePowerState\"=([0-9]+).*$/\1/')
        [[ "$val" == "0" ]] && die "screen is off" || :
    fi
}

read_config() {
    [[ -f "$config_path" ]] || return 0
    say "reading config from $config_path"
    while IFS="=" read -r name value; do
        if [[ "$name" == "stop_music" ]]; then
            stop_music=$value
        elif [[ "$name" == "volume_factor" ]]; then
            volume_factor=$value
        elif [[ "$name" == "check_screen" ]]; then
            check_screen=$value
        elif [[ "$name" == "instrument" ]]; then
            instrument=$value
        fi
    done < "$config_path"
}

set_instrument_code() {
    if [[ "$instrument" == "random" ]]; then
        i=$((RANDOM % ${#instrument_names[@]}))
        instrument=${instrument_names[$i]}
        instrument_code=${instrument_codes[$i]}
        say "chose random instrument '$instrument' ($instrument_code)"
        return
    fi
    for i in "${!instrument_names[@]}"; do
        if [[ "${instrument_names[$i]}" == "$instrument" ]]; then
            instrument_code="${instrument_codes[$i]}"
            say "using instrument '$instrument' ($instrument_code)"
            return
        fi
    done
    die "$instrument: invalid instrument"
}

main() {
    read_config
    check_arguments
    set_instrument_code
    if [[ -z "$the_quarter" && -z "$the_hour" ]]; then
        check_should_chime
        infer_from_time
    fi

    [[ "$stop_music" == true ]] && stop_music
    [[ -n "$the_quarter" ]] && chime_quarter "$the_quarter"
    [[ -n "$the_hour" ]] && strike_hour "$the_hour"
    [[ "$stop_music" == true ]] && restore_music
    wait
}

while getopts "hq:s:S:m:t:c:i:" opt; do
    case $opt in
        h) usage ; exit 0 ;;
        q) the_quarter=$OPTARG ;;
        s) the_hour=$OPTARG ;;
        S) the_quarter=4 ; the_hour=$OPTARG ;;
        m) midi_dir=$OPTARG ;;
        t) timidity_path=$OPTARG ;;
        c) config_path=$OPTARG ; explicit_config_path=true ;;
        i) instrument=$OPTARG ;;
        *) exit 1 ;;
    esac
done
shift $((OPTIND - 1))
[[ $# -eq 0 ]] || die "too many arguments"

main
