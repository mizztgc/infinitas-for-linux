# Infinitas for Linux
An unofficial method of playing beatmania IIDX INFINITAS (and other Konaste games) on Linux, written in Bash

**※ (DeepL) 日本のユーザー: このリポジトリはほとんど英語で書かれています。必要に応じて、このスクリプトが何をするのかを理解し、どのような問題が発生するのかを理解するために、機械翻訳ユーティリティの助けが必要になるかもしれません。**

[discord server](https://discord.com/invite/snPwbvagWZ)

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
* **libpulse** (required; for sound & to determine audio sample rate)
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

**NOTE:** If you want to use the Flatpak build of Wine over a native build, run `./infinitas --flatpak install`. This should only be done if you use a stable distro that doesn't have Wine 9.0 like Debian 12.x, if you run a Steam Deck, or if you really care about sandboxing. Despite the basic Flatpak support, this script was made without sandboxing in mind, so I cannot guarantee if the game will work.

You will also need to install `org.winehq.Wine` from Flathub. Ensure the branch is `stable-23.08` or newer.

~~(I still need to learn how to make a proper flatpak application...)~~

## KNOWN ISSUES
Due to the nature of Linux (and Wine), you may encounter issues that aren't present on Windows. Some of the issues are documented below:

### The launcher's settings menu doesn't open
Your Wineprefix is missing `wine-mono`. Install it from your distribution's package manager, or click "install" when prompted if using a custom build. If `wine-mono` is not available from your distribution's package manager, you must install it manually. See [this page](https://gitlab.winehq.org/wine/wine/-/wikis/Wine-Mono) for instructions on how to do so.

Also, when installing the appropriate mono package for your build of Wine, you should also export WINEPREFIX to the location of the prefix that contains the beatmania IIDX INFINITAS game data (ex. `$ WINEPREFIX="$HOME/.local/share/konaste" wine /path/to/wine-mono-*-x86.msi`)

### Fonts in the launcher's settings menu rendering as boxes
This is because the Wineprefix doesn't have any CJK (Chinese/Japanese/Korean) fonts to display. Until I find a fix for this, your best bet is to use `winetricks` to download and install the necessary fonts.

### Black screen when the game launches
If you launch the game and you've been stuck on a black screen for a while, try alt-tabbing to see if there's an error message hidden behind the game window. This error message is supposed to indicate that the game couldn't find a suitable audio device and must close. The cause for this issue is due to your WASAPI audio mode set to 排他モード (Exclusive mode), which Wine does not support, but it can be fixed by setting it to 共有モード (Shared mode).

### Game fails to start with 5-1501-0003 error
You will mostly encounter this issue if you play in a Wayland session. Due to Wayland's behavior, it will only expose your currently set refresh rate to all applications, which causes beatmania IIDX INFINITAS to not be able to find a suitable display mode. It can become annoying if you have a display that natively outputs at 75Hz, 90Hz, etc.

To fix this issue, set your refresh rate to either 60Hz or 120Hz if supported. You can optionally switch to a 16:9 resolution if you can't stand the game being stretched to fill your screen. Alternatively, you can play in an Xorg (X11) session, which will allow the game to automatically set your resolution and refresh rate.

### The game crashes after the KONAMI/e-amusement/BEMANI splash screens
This issue is caused by gstreamer not having access to any H.264 plugins on your system. If you run Ubuntu or any of its derivatives like Linux Mint, make sure you install the third-party multimedia codecs if you didn't do so when first installing your OS.

### The keysounds in some songs are bugged/delayed/DistorteD/missing
This is speculated to be due to a new audio container used for the newer beatmania IIDX versions starting with CANNON BALLERS and becoming the default for HEROIC VERSE and beyond. As of right now, there seems to be no fix for this. Unless you actively play the songs from SINOBUZ and earlier or the INFINITAS exclusive ones (which seem to also use the older audio container from my observations), this might be a deal breaker for you.

### Some songs that use overlays crash the game
As of right there, there is no fix for this, other than to disable the BGA in the advanced song options menu.

***
# Special thanks
* [This Reddit thread](https://www.reddit.com/r/bemani/comments/yardc2/anyone_run_their_konasute_infinitas_sdvx_etc/) [(this comment specifically)](https://www.reddit.com/r/bemani/comments/yardc2/comment/ke5z7mi/)
* [Bombergirl on Linux](https://rentry.org/bombergirl-linux) guide
