# Infinitas for Linux
An unofficial method of playing beatmania IIDX INFINITAS on Linux, written in Bash

## DISCLAIMER:

This script is in no way affiliated with, endorsed, nor supported by KONAMI. In order to access the full game outside of trial mode, you must be subscribed to the beatmania IIDX INFINITAS Basic Course. This script will NOT allow you to gain access to things you aren't paying for, nor will the script developer assist you with such actions.

Like most online games today, getting banned for playing the game on GNU/Linux (outside of what the developers intended) is a possibility. The script developer is not to be held responsible, should you receive any bans from use of this script.

*Play at your own risk.*

## WHAT DOES THIS SCRIPT DO?

This script is meant to be used for playing KONAMI's beatmania IIDX INFINITAS: a PC rhythm game based on their already established arcade franchise of the same name, using Wine. It manages launching the game from the e-amusement website by passing the `bm2dxinf://` URI to the launcher. This URI acts as a temporary login token, so you can log on with your KONAMI ID and have all your scores and purchased song packs synced over. It also proves an indicator of what mode you want to launch the game in: `trial`, and `rel` mode.

## DEPENDENCIES:

This script requires the following dependencies:

- **Web browser of your choice** (Firefox, Chrome, etc.)
- **wine** (required; self-explanatory)
- **pipewire** (required; for sound)
- **xdg-utils** (required; to handle the `bm2dxinf://` URI)
- **kdialog** (required; for showing error message boxes)
- **msitools** (game install only; for extracting the files from the installer)
- **wget** (game install only; for downloading the installer)
- **tar** (game install only; for extracting the files for DXVK)
- **gamescope** (optional; for running the game within a gamescope session)

## HOW TO INSTALL:
```
git clone https://github.com/mizztgc/infinitas-for-linux/
cd infinitas-for-linux/
chmod +x infinitas
./infinitas install
```

## ENVIRONMENT VARIABLES:

This script supports the following environment variables:

- `INFINITAS_USE_GAMESCOPE`: Tells the script to start the game within a gamescope session. Recommended if you don't want to constantly adjust your display options to play this game. A value of **1** will run the Wine process through gamescope. Requires gamescope to be installed.

## INSTALLATION:

To download and install the game files, run `infinitas install`, and let it work its magic. As of right now, the installer will only use your system's build of Wine, and will install the game to `~/.local/share/infinitas` by default. Whenever I decide to stop procrastinating, I'll add the ability to let you choose your own  build of wine and prefix location.

## Q/A:

Q: How much is the beatmania IIDX INFINITAS Basic Course subscription?

A: The subscription for this game is ¥1628/month. Thankfully enough, the payment processing system KONAMI uses allows the use of foreign credit/debit cards (your bank may require you a one-time code to confirm it).



Q: Will I get banned for playing on Linux?

A: While unlikely, it may be possible.



Q: Is it possible to use a custom Wine build?

A: As of right now, no.



Q: Is it possible to play the game using gamescope?

A: Yes it is! Do keep in mind that in order to play through gamescope, you must set the environment variable `INFINITAS_USE_GAMESCOPE` to 1. Passing the script as a gamescope launch argument will kill the gamescope process. This was an intentional decision to prevent any issues if you're that kind of person that uses a Steam Deck or whatever.



Q: Will this script work with other Konaste games?

A: This script is specifically meant for beatmania IIDX INFINITAS, you're more than welcome to attempt to use this as a base to install other Konaste games, such as SOUND VOLTEX EXCEED GEAR and ボンバーガール (Bomber Girl).



Q: Can I play this game on a Steam Deck?

A: I don't own a Steam Deck, so I cannot verify if this game will work on it or not. And if it does, **you *MUST* play in desktop mode**.



Q: It's [insert current year here], why is KONAMI still using a website to launch this game instead of a proper launcher?

A: You're asking the wrong person, buddy.



Q: What's with my access to the game being restricted at certain times?

A: The e-amusement servers go down daily between 05:00-07:00 JST (20:00-22:00 UTC) for maintenance. I know it sucks, especially given the fact that I live in a timezone where I won't be able to play during the late afternoon hours.



Q: I keep getting a 5-1503-0003 error! What's going on?

A: This error relates to your display. The game is trying to adjust your display settings, but is unable to due to how Wine handles displays. To alleviate this issue, set your resolution to 1920x1080@60Hz (or 120Hz if supported), or use gamescope to completely bypass this design quirk.



Q: Why does this game run in a Wine virtual desktop?

A: The reason was mostly due to gamescope being absolutely finicky, and terminating the compositor (and the Wine server) after you click "Play" on the launcher.



Q: The game only shows a black screen. What gives?

A: The game is probably showing an error message box, usually because it cannot find any audio devices due to the game being set to use WASAPI (exclusive).



Q: What's with the settings menu and error messages showing boxes?

A: This is due to the Wineprefix not having a font to render CJK characters. I'm trying to research a way to include CJK fonts in the prefix, but for the time being, install the necessary fonts through utilities like Winetricks.



Q: What's the difference between exclusive WASAPI and shared WASAPI?

A: Exclusive WASAPI, as its name implies, allows the application have exclusive access to your current audio device. This allows you to play the game with very low latency, something that is VERY IMPORTANT in rhythm games with tight timing windows. Shared WASAPI, on the other hand, means the application has to share the audio device with other applications. While it can increase latency, it's recommended to use if you want to pass the application's audio stream to applications like OBS, but it is also ABSOLUTELY MANDATORY if you want to play IIDX INFINITAS on Linux.



Q: There's a (1-0) error on the launcher. What does that indicate?

A: That error indicates you either started the launcher with no launch key, an invalid launch key, or one that has already been used. Refresh the e-amusement page in your browser to generate a new one. Remember that these keys can only be used ONCE.



Q: I have no sound!

A: ~~The game process is probably trying to run at a sample rate of 48kHz, which is the reason for having no sound. You can confirm this by running the command `pactl list sink-inputs`, and checking `node.rate` to see if it reports a value of `1/48000`. In order to have the game output audio, set your sample rate within PipeWire to 44.1kHz. This script will automatically do that for you, *but it may not work all the time*.~~ Run `winecfg` within `~/.local/share/infinitas`, navigate to "Audio", and then set the default option for **Output device:** to `infinitas`. It's highly recommended that you do this when the actual launcher opens,



Q: Why does my audio sound crackly/DistorteD/possessed?

A: You may have PULSE_LATENCY_MSEC set, and its value set to below 40ms. Enjoy the demons that you summoned. Jokes aside, this may also happen if you don't have this environment variable set, but it may not be noticeable, unless you play certain songs. My recommendation is to set `PULSE_LATENCY_MSEC` to a value that is >= 35.
