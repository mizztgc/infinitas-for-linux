# Infinitas for Linux
An unofficial method of playing beatmania IIDX INFINITAS on Linux, written in Bash

Be sure to check out the [wiki](https://github.com/mizztgc/infinitas-for-linux/wiki) for some helpful information

## NOTICE FOR FLATPAK USERS:
Support for the Flatpak build of Wine is temporarily disabled until I can discover why installing the base game fails most of the time, and why Bash thinks the variable for the Wine executable is one whole command. In the meantime, you are urged to use a native build of Wine from your distro's package manager, _as long as it's Wine 9.0 or later (you can check by running `wine --version`)_

## DISCLAIMER:

This script is in no way affiliated with, endorsed, nor supported by KONAMI. In order to access the full game outside of trial mode, you must be subscribed to the beatmania IIDX INFINITAS Basic Course. This script will NOT allow you to gain access to things you aren't paying for, nor will the script developer assist you with such actions.

Like most online games today, getting banned for playing the game on GNU/Linux (outside of what the developers intended) is a possibility. The script developer is not to be held responsible, should you receive any bans from use of this script.

*Play at your own risk.*

It's also worth pointing out I'm still pretty new at this whole GitHub thing, so I may feel lost/confused about some things.

## WHAT DOES THIS SCRIPT DO?

This script is meant to be used for playing KONAMI's beatmania IIDX INFINITAS: a PC rhythm game based on their already established arcade franchise of the same name, using Wine.

## DEPENDENCIES:

This script requires the following dependencies:

* **Web browser of your choice** (Firefox, Chrome, etc.)
* **wine >=9.0** (required; this is a game for Windows after all)
* **pipewire** (required; for sound)
* **pipewire-pulse** (required; for sound)
* **pulseaudio-utils** (required; for enabling the loopback device that is needed for audio to work)
* **libnotify** (required; to show non-intrusive warnings related to configuration)
* **xdg-utils** (required; to handle the `bm2dxinf://` URI)
* **kdialog** (required; for showing error message boxes)
* **msitools** (game install only; for extracting the files from the installer)
* **wget** (game install only; for downloading the installer)
* **tar** (game install only; for extracting the files for DXVK)
* **imagemagick** (game install only; for generating icons)

## HOW TO INSTALL:
```
git clone https://github.com/mizztgc/infinitas-for-linux/
cd infinitas-for-linux/
chmod +x infinitas
./infinitas install
```

You can also specify the following options:
* `--prefix=` Set the location for the Wineprefix that will hold all game files
* `--winebuild=` Use a custom Wine build for not only playing IIDX INFINITAS, but also use it to install the game.
* `--no-dxvk` Do not install DXVK to the Wineprefix. While IIDX INFINITAS can run perfectly fine without it, I'd still recommend installing it.
