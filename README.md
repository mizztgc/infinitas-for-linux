# Infinitas for Linux
An unofficial method of playing beatmania IIDX INFINITAS on Linux, written in Bash

## NOTICE FOR FLATPAK USERS:
Due to Flatpak's "sandboxed" nature, you will have many issues pertaining to installing the game, as well as song data (keysounds, videos, overlays, etc). It is **HIGHLY RECOMMENDED** to use a native build of Wine to play beatmania IIDX INFINITAS. That being said, if you're on a stable distro like Debian and/or only have access to versions of Wine older than 9.0, _you may need to upgrade your distro_.

## DISCLAIMER:

This script is in no way affiliated with, endorsed, nor supported by KONAMI. In order to access the full game outside of trial mode, you must be subscribed to the beatmania IIDX INFINITAS Basic Course. This script will NOT allow you to gain access to things you aren't paying for, nor will the script developer assist you with such actions.

Like most online games today, getting banned for playing the game on GNU/Linux (outside of what the developers intended) is a possibility. The script developer is not to be held responsible, should you receive any bans from use of this script.

*Play at your own risk.*

It's also worth pointing out I'm still pretty new at this whole GitHub thing, so I may feel lost/confused about some things.

## WHAT DOES THIS SCRIPT DO?

This script is meant to be used for playing KONAMI's beatmania IIDX INFINITAS: a PC rhythm game based on their already established arcade franchise of the same name, using Wine.

## DEPENDENCIES:

This script requires the following dependencies:

- **Web browser of your choice** (Firefox, Chrome, etc.)
- **wine >=9.0** (required; self-explanatory)
- **pipewire** (required; for sound)
- **xdg-utils** (required; to handle the `bm2dxinf://` URI)
- **kdialog** (required; for showing error message boxes)
- **msitools** (game install only; for extracting the files from the installer)
- **wget** (game install only; for downloading the installer)
- **tar** (game install only; for extracting the files for DXVK)
- **imagemagick** (game install only; for generating icons)

## HOW TO INSTALL:
```
git clone https://github.com/mizztgc/infinitas-for-linux/
cd infinitas-for-linux/
chmod +x infinitas
./infinitas install
```

NOTE: If you want to use the Flatpak build of Wine, add `--flatpak` to your arguments! **(not recommended)**
