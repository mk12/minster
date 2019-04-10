# Minster

Minster brings [Westminster chimes][wq] to your computer. Like Big Ben. Or a grandfather clock.

## Usage

1. Clone the project.
2. Install timidity (available on Homebrew and apt-get).
3. Manually play the chimes with `minster.sh`.
4. Run `crontab -e` and add the following lines, using absolute paths:

```
*/15 * * * * /path/to/minster.sh -t /path/to/timidity > /tmp/minster.log 2>&1
```

## Chimes

Westminster chimes are based on (mostly) 5 permutations of 4 notes in E major:

1. G, F, E, B
2. E, G, F, B
3. E, F, G, E ("mostly")
4. G, E, F, B
5. B, F, G, E

The bells chime as follows:

1. First quarter: P1.
2. Half hour: P2, P3.
3. Third quarter: P4, P5, P1.
4. *N*th hour: P2, P3, P4, P5. Then *N* strikes for the hour.

See the [Wikipedia article][wq] for more information.

## Sound

Minster uses [timidity][tm] to play MIDI files for the sounds. Those files can be edited in [Aria Maestosa][am], an open source MIDI editor. For each sound clip, there is an Aria file in the `aria/` folder and a MIDI file in the `midi/` folder.

## Configuration

Minster reads configuration from `~/.config/minster/config.ini`. There are a few options:

```ini 
volume_factor=125  # play chimes at 125% current volume
stop_music=true    # (macOS only) fade iTunes music out while chiming
check_screen=true  # (macOS only) check if the display is on before chiming

# Specify the instrument. The optiona are tubular (default), piano, brpiano,
harpsichord, # xylophone, harp, ocarina, and random.
instrument=tubular
```

## Troubleshooting

If the cron job isn't working, check `/tmp/minster.log`, and try adding `set -x` to the top of `minster.sh` to make it log every command. If it can't find programs, try adding this to the top of your crontab file:

```
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
```

Note that on macOS, you may see a pop up window asking for permissions. You need to grant these permissions for Minster to work.

## Launchd

As an alternative to cron, on macOS you can run `install.sh` to install a [launchd][ld] job . According to the Apple documentation:

> Unlike cron which skips job invocations when the computer is asleep, launchd will start the job the next time the computer wakes up. If multiple intervals transpire before the computer is woken, those events will be coalesced into one event upon wake from sleep.

The `minster.sh` script is designed so that this behavior usually doesn't cause duplicate chimes, but it's not perfect.

## License

© 2019 Mitchell Kember

Minster is available under the MIT License; see [LICENSE](LICENSE.md) for details.

[wq]: https://en.wikipedia.org/wiki/Westminster_Quarters
[tm]: http://timidity.sourceforge.net
[am]: http://ariamaestosa.sourceforge.net
[ld]: https://en.wikipedia.org/wiki/Launchd
