# Infinitas for Linux
An unofficial method of playing beatmania IIDX INFINITAS on Linux, written in Bash

Be sure to check out the [wiki](https://github.com/mizztgc/infinitas-for-linux/wiki) and [Known Issues](https://github.com/mizztgc/infinitas-for-linux/wiki/Known-Issues) for some helpful information

**※ (DeepL) 日本のユーザー: このリポジトリはほとんど英語で書かれています。必要に応じて、このスクリプトが何をするのかを理解し、どのような問題が発生するのかを理解するために、機械翻訳ユーティリティの助けが必要になるかもしれません。**

## DISCLAIMER:

This script is in no way affiliated with, endorsed, nor supported by KONAMI. In order to access the full game outside of trial mode, you must be subscribed to the beatmania IIDX INFINITAS Basic Course. This script will NOT allow you to gain access to things you aren't paying for, nor will the script developer assist you with such actions.

Like most online games today, getting banned for playing the game on GNU/Linux (outside of what the developers intended) is a possibility. The script developer is not to be held responsible, should you receive any bans from use of this script.

*Play at your own risk.*

## WHAT DOES THIS SCRIPT DO?

This script is meant to be used for playing KONAMI's beatmania IIDX INFINITAS: a PC rhythm game based on their already established arcade franchise of the same name, using Wine. It can also be used as a base for launching other KONAMI Amusement Station Cloud (Konaste) games as well, such as SOUND VOLTEX EXCEED GEAR.

This script is supposed to be easy to use and function in a similar way as if you were using Windows. It doesn't have fancy features, such as generating login tokens without the need of a web browser, or allowing the use of Linux utilities to improve performance/compatibility, such as custom builds of Wine and Valve's gamescope compositor (They *may* come soon, assuming I have the motivation to implement them).

## DEPENDENCIES:

This script requires the following dependencies: (**NOTE:** The dependency names listed here are their associated packages on Arch Linux. Your distribution may have these packages labeled differently, or may have the required dependencies separated in other packages.)

* **Web browser of your choice** (Firefox, Chrome, etc.)
* **wine>=9.0** (required; this is a game for Windows after all)
* **wine-mono** (required; needed for the launcher's settings menu to function)
  * If your distribution does not have wine-mono packaged, you must install the version of mono that's compatible with your build of Wine. You can learn how [here](https://gitlab.winehq.org/wine/wine/-/wikis/Wine-Mono).
* **pipewire** (required; for sound)
* **pipewire-pulse** (required; for sound)
  * Debian users may need to also install **pulseaudio-utils**
* **pipewire-audio** (required; for sound)
* **xdg-utils** (required; to handle the `bm2dxinf://` URI)
* **zenity** (required; for showing message boxes)
* **icoutils** (game install only; for creating icons)
* **wget** (game install only; for downloading the installer)
* **flatpak** (optional; only required if `--flatpak` is passed to this script)

## HOW TO INSTALL:
```
git clone https://github.com/mizztgc/infinitas-for-linux/
cd infinitas-for-linux/
chmod +x infinitas
./infinitas install
```

**NOTE:** If you want to use the Flatpak build of Wine over a native build, run `./infinitas --flatpak install`. This should only be done if you use a stable distro that doesn't have Wine 9.0 like Debian 12.x, a Steam Deck, or if you really care about sandboxing. Despite the basic Flatpak support, this script was made without sandboxing in mind, so I cannot guarantee if the game will work.

You will also need to install `org.winehq.Wine` from Flathub. Ensure the branch is `stable-23.08` or newer.
