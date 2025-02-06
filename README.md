# Konaste Linux (formerly Infinitas for Linux)
An unofficial method of playing KONAMI Amusement Game Station (Konaste/コナステ) games on Linux, written in Bash

## DISCLAIMER:

This script is in no way affiliated with, endorsed, nor supported by KONAMI Amusement. All games require a KONAMI ID to play, and most games require a subscription to their respective basic course subscriptions in order to access their full versions. This script will NOT allow you to gain access to things you aren't paying for, nor will the script developer assist you with such actions. *Play at your own risk.*

Due to Wine's nature, some games may exhibit severe issues not present on Windows. This script ***only*** does the bare minimum to get these games working on Linux.

## WHAT DOES THIS SCRIPT DO?

This script is intended to be a simpler way of managing, installing, and playing Konaste games on Linux, using Wine. Unlike many Wine-related programs/scripts, this script does not have many features that power users would enjoy, such as choosing the location of the prefix, using third-party Wine builds, etc.

**This script does NOT work with the Flatpak version of Wine as of right now. This might be a deal breaker for those on stable/immutable distros like Debian and SteamOS.**

## WHAT GAMES ARE SUPPORTED?

The following games are supported via Konaste Linux:

* beatmania IIDX INFINITAS (`iidx`)
* SOUND VOLTEX EXCEED GEAR コナステ (`sdvx`)
* DanceDanceRevolution GRAND PRIX (`ddr`)
* GITADORA コナステ (`gitadora`)
* ノスタルジア (`nostalgia`)
* pop'n music Lively (`popn`)
* ボンバーガール (`bombergirl`)

**NOTE:** I have only tested IIDX INFINITAS, SOUND VOLTEX, and Bomber Girl.

## DEPENDENCIES:

This script requires the following dependencies: (**NOTE:** The dependency names listed here are their associated packages on Arch Linux. Your distribution may have these packages labeled differently, or may have the required dependencies separated in other packages.)

* **Web browser of your choice** (Firefox, Chrome, etc.)
* **wine>=9.0** (this is a game for Windows after all)
* **wine-mono** (needed for the launcher's settings menu to function)
  * If your distribution does not have wine-mono packaged, you must install the version of mono that's compatible with your build of Wine. You can learn how [here](https://gitlab.winehq.org/wine/wine/-/wikis/Wine-Mono).
* **pipewire** (for sound)
* **pipewire-pulse** (for sound)
  * Debian users may need to also install **pulseaudio-utils**
* **pipewire-audio** (for sound)
* **libpulse** (for sound & to determine audio sample rate)
* **xdg-utils** (to handle the login tokens)
* **wget** (for downloading the needed windows dependencies and of course, the game installers)

## HOW TO INSTALL:
### Arch Linux-based Distros (EndeavourOS, Manjaro, etc.)

Konaste Linux can be installed from the [Arch User Repository](https://aur.archlinux.org/packages/konaste-linux). Using an AUR helper such as `paru`, run the following command:
```
paru -S konaste-linux
```
### Other Distributions
Download the latest archive from [Releases](https://github.com/mizztgc/konaste-linux/releases) and follow the instructions in INSTRUCTIONS.txt.

## KNOWN ISSUES
Due to the nature of Linux (and Wine), you may encounter issues that aren't present on Windows. Many of the issues listed were related to beatmania IIDX INFINITAS, but other Konaste games may also exhibit these issues:

### The launcher's settings menu doesn't open
Your Wineprefix is missing `wine-mono`. Install it from your distribution's package manager, or click "install" when prompted if using a custom build. If `wine-mono` is not available from your distribution's package manager, you must install it manually. See [this page](https://gitlab.winehq.org/wine/wine/-/wikis/Wine-Mono) for instructions on how to do so.

### Black screen when the game launches
If you launch the game and you've been stuck on a black screen for a while, try alt-tabbing to see if there's an error message hidden behind the game window. This error message is supposed to indicate that the game couldn't find a suitable audio device and must close. The cause for this issue is due to your WASAPI audio mode set to 排他モード (Exclusive mode), which Wine does not support, but it can be fixed by setting it to 共有モード (Shared mode).

### No sound, despite the loopback device running
Check to see if the loopback device is muted.

### The game crashes after the KONAMI/e-amusement/BEMANI splash screens
This issue is caused by gstreamer not having access to any H.264 plugins on your system. If you run Ubuntu or any of its derivatives like Linux Mint, make sure you install the third-party multimedia codecs if you didn't do so when first installing your OS.

***
# Special thanks
* [This Reddit thread](https://www.reddit.com/r/bemani/comments/yardc2/anyone_run_their_konasute_infinitas_sdvx_etc/) [(this comment specifically)](https://www.reddit.com/r/bemani/comments/yardc2/comment/ke5z7mi/)
* [Bombergirl on Linux](https://rentry.org/bombergirl-linux) guide
