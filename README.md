# Minster

Minster brings [Westminster chimes][wq] to your Mac. Like Big Ben. Or a grandfather clock.

## Usage

1. Clone the project.
2. Install timidity with [Homebrew][hb]: `brew install timidity`.
3. Manually play the chimes with `minster.sh`.
4. Automate the chimes with `install.sh`.

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

## Launchd

When you install it with `install.sh`, Minster chimes automatically every quarter hour, scheduled by [launchd][ld]. According to the Apple documentation:

> Unlike cron which skips job invocations when the computer is asleep, launchd will start the job the next time the computer wakes up. If multiple intervals transpire before the computer is woken, those events will be coalesced into one event upon wake from sleep.

The `minster.sh` script is designed so that this behavior should never cause duplicate chimes.

## License

© 2019 Mitchell Kember

Minster is available under the MIT License; see [LICENSE](LICENSE.md) for details.

[hb]: https://brew.sh
[wq]: https://en.wikipedia.org/wiki/Westminster_Quarters
[tm]: http://timidity.sourceforge.net
[am]: http://ariamaestosa.sourceforge.net
[ld]: https://en.wikipedia.org/wiki/Launchd
