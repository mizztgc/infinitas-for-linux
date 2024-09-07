# Infinitas for Linux (TESTING)
An unofficial method of playing beatmania IIDX INFINITAS on Linux, written in Bash

Be sure to check out the [wiki](https://github.com/mizztgc/infinitas-for-linux/wiki) for some helpful information

## WARNING:

This script currently does _**NOT**_ have the ability to install beatmania IIDX INFINITAS. This script is only meant for starting the game, and will assume you already have the game installed. If you haven't installed beatmania IIDX INFINITAS yet, your best bet is to use the script in the main branch, and then replace it with this script once it's done.

## DISCLAIMER:

This script is in no way affiliated with, endorsed, nor supported by KONAMI. In order to access the full game outside of trial mode, you must be subscribed to the beatmania IIDX INFINITAS Basic Course. This script will NOT allow you to gain access to things you aren't paying for, nor will the script developer assist you with such actions.

Like most online games today, getting banned for playing the game on GNU/Linux (outside of what the developers intended) is a possibility. The script developer is not to be held responsible, should you receive any bans from use of this script.

*Play at your own risk.*

## WHAT DOES THIS SCRIPT DO?

This script is meant to be used for playing KONAMI's beatmania IIDX INFINITAS: a PC rhythm game based on their already established arcade franchise of the same name, using Wine. It can also be used as a base for launching other KONAMI Amusement Station Cloud (Konaste) games as well, such as SOUND VOLTEX EXCEED GEAR.

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
