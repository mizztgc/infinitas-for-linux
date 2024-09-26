# Infinitas for Linux
An unofficial method of playing beatmania IIDX INFINITAS on Linux, written in Bash

Be sure to check out the [wiki](https://github.com/mizztgc/infinitas-for-linux/wiki) and [Known Issues](https://github.com/mizztgc/infinitas-for-linux/wiki/Known-Issues) for some helpful information

## DISCLAIMER:

This script is in no way affiliated with, endorsed, nor supported by KONAMI. In order to access the full game outside of trial mode, you must be subscribed to the beatmania IIDX INFINITAS Basic Course. This script will NOT allow you to gain access to things you aren't paying for, nor will the script developer assist you with such actions.

Like most online games today, getting banned for playing the game on GNU/Linux (outside of what the developers intended) is a possibility. The script developer is not to be held responsible, should you receive any bans from use of this script.

*Play at your own risk.*

## WHAT DOES THIS SCRIPT DO?

This script is meant to be used for playing KONAMI's beatmania IIDX INFINITAS: a PC rhythm game based on their already established arcade franchise of the same name, using Wine. It can also be used as a base for launching other KONAMI Amusement Station Cloud (Konaste) games as well, such as SOUND VOLTEX EXCEED GEAR.

The following environment variables are supported:
* `IOL_GAMESCOPE`: Enable support for Valve's gamescope compositor. A value of 1 or 2 will enable gamescope.
  * ***NVIDIA USERS:*** If you do intend on using gamescope, enable the `nvidia-drm.modeset=1` kernel parameter ***AND*** set this environment variable to a value of 2. Using a value of 1 WILL cause gamescope to core dump.
* `IOL_NO_DXVK`: Disable the use of DXVK. If unset, or set to a value of 0, it will look for DXVK in `/usr/share/dxvk`.
  * Only disable DXVK if your graphics card does not have good support for the Vulkan API, or you have issues with DXVK.
* `IOL_NO_LOOPBACK`: If set to 1, this will not enable the PipeWire loopback device.
  * ***WARNING: YOUR AUDIO SAMPLE RATE WITHIN PIPEWIRE MUST BE SET TO 44100Hz, OR YOU WILL NOT HAVE ANY SOUND!***

## DEPENDENCIES:

This script requires the following dependencies:

* **Web browser of your choice** (Firefox, Chrome, etc.)
* **wine>=9.0** (required; this is a game for Windows after all)
* **pipewire** (required; for sound)
* **pipewire-pulse** (required; for sound)
  * Debian users may need to also install **pulseaudio-utils**
* **xdg-utils** (required; to handle the `bm2dxinf://` URI)
* **kdialog** (required; for showing message boxes)
* **icoutils** (game install only; for creating icons)
* **wget** (game install only; for downloading the installer)

As of right now, the Flatpak build of Wine is unsupported.

## HOW TO INSTALL:
```
git clone https://github.com/mizztgc/infinitas-for-linux/
cd infinitas-for-linux/
chmod +x infinitas
./infinitas install
```
