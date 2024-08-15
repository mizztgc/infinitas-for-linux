#!/usr/bin/env bash

# Infinitas for Linux script by mizztgc
# https://github.com/mizztgc/infinitas-for-linux/

# DISCLAIMER:
# This script is in no way affiliated with, endorsed, nor supported by KONAMI. In order to access the full game outside
# of trial mode, you must be subscribed to the beatmania IIDX INFINITAS Basic Course. This script will NOT allow you to
# gain access to things you aren't paying for, nor will the script developer assist you with such actions.
#
# Like most online games today, getting banned for playing the game on GNU/Linux (outside of what the developers
# intended) is a possibility. The script developer is not to be held responsible, should you receive any bans from use of
# this script.
#
# Play at your own risk.

ERROR_LABEL="\033[1;91m-> ERROR:\033[0m"
WARN_LABEL="\033[1;93m-> WARNING:\033[0m"

[[ "$UID" -eq 0 ]] && echo -e "$ERROR_LABEL This script is not to be ran as the root user." && exit 127

# flags
prefixLocation="$HOME/.local/share/infinitas"
tempDir="/tmp/iidx"
configFile="$HOME/.config/infinitas/bm2dx.conf"

# links
DXVK_LINK="https://github.com/doitsujin/dxvk/releases/download/v2.4/dxvk-2.4.tar.gz"
INFINITAS_LINK="https://d1rc4pwxnc0pe0.cloudfront.net/v2/installer/infinitas_installer_2022060800.msi"
VCR2010_LINK="https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe"

# disclaimer
read -rd '' disclaimer <<EOM
\n\033[1;91mWARNING:\033[0;1m READ BEFORE CONTINUING:\033[0m\n\n

This script is in no way affiliated with, endorsed, nor supported by KONAMI. In order to access the full game outside\n
of trial mode, you must be subscribed to the beatmania IIDX INFINITAS Basic Course. This script will NOT allow you to\n
gain access to things you aren't paying for, nor will the script developer assist you with such actions.\n\n

Like most online games today, getting banned for playing the game on GNU/Linux (outside of what the developers\n
intended) is a possibility. The script developer is not to be held responsible, should you receive any bans from use of\n
this script.\n\n

\033[3mPlay at your own risk\033[0m.\n\n
EOM

# help
show_help() {
cat <<EOF
usage: $0 [arguments] [command]
arguments:
 --custom-wine=/path/to/winedir: Use a custom build of Wine rather than your distribution's build (default: currently installed wine)
 --prefix=/path/to/wineprefix: Use a custom Wineprefix (default: ~/.local/share/infinitas)
 --flatpak: Use the Flatpak build of Wine instead of your currently installed one. Cannot be used with --custom-wine

commands:
 install: Installs beatmania IIDX INFINITAS
 uninstall: Removes beatmania IIDX INFINITAS
 create-icons: Creates the icons for beatmania IIDX INFINITAS. Requires imagemagick to be installed
 fix-keys: Recreates the registry keys to help beatmania IIDX INFINITAS locate all necessary files and directories
 fix-launcher: Recreates the .desktop launcher for beatmania IIDX INFINITAS
 generate-config: Creates a configuration file for managing the game
 help: shows this message
EOF
}

ynPrompt() {
	while true; do
		pro="$1 ["
		case $2 in
			0)
				pro+="Y/n] "
				;;
			1)
				pro+="N/y] "
				;;
			*)
				pro+="y/n] "
				;;	
		esac
		
		read -rp "$(printf "\033[1m$pro\033[0m")" choice
		if [[ -z "$choice" ]]; then
			case "$2" in
				0)
					choice='y'
					;;
				1)
					choice='n'
					;;
			esac
		fi
		
		case $choice in
			[Yy]|[Yy][Ee][Ss])
				return 0
				;;
			[Nn]|[Nn][Oo])
				return 1
				;;
			*)
				echo -e "$ERROR_LABEL Invalid response."
				;;
		esac
	done
}

create_launcher() {
	echo "Creating launcher and mimetype for beatmania IIDX INFINITAS..."
	[[ -e $HOME/.local/share/applications/infinitas.desktop ]] && echo -e "$WARN_LABEL Overwriting ~/.local/share/applications/infinitas.desktop!"
cat > $HOME/.local/share/applications/infinitas.desktop <<EOF
[Desktop Entry]
MimeType=x-scheme-handler/bm2dxinf
Categories=Application;Game;
Icon=infinitas
GenericName=Rhythm Game
Name=beatmania IIDX INFINITAS
Type=Application
Exec=$HOME/.local/share/infinitas/$(basename -- $0) %u
EOF

	[[ -e $HOME/.local/share/mime/packages/x-scheme-handler-bm2dxinf.xml ]] && echo -e "$WARN_LABEL Overwriting ~/.local/share/mime/packages/x-scheme-handler-bm2dxinf.xml!"
cat > $HOME/.local/share/mime/packages/x-scheme-handler-bm2dxinf.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
    <mime-type type="x-scheme-handler/bm2dxinf">
        <comment>beatmania IIDX INFINITAS</comment>
        <icon name="x-scheme-handler-bm2dxinf"/>
        <glob-deleteall/>
        <glob pattern="bm2dxinf://*"/>
    </mime-type>
</mime-info>
EOF
	update-desktop-database $HOME/.local/share/applications
	update-mime-database $HOME/.local/share/mime
	return 0
}

create_icons() {
	[[ -z $(which magick 2>/dev/null) ]] && echo -e "$WARN_LABEL imagemagick was not found on your system. Icons will not be created." && return 1
	[[ ! -e "$1" ]] && echo -e "$ERROR_LABEL No .ico file provided." && exit 1
	echo "Creating icons for beatmania IIDX INFINITAS..."
	iconLocation="$1"
	mkdir tmpIconDir
	cd tmpIconDir
	magick "$iconLocation" icon.png
		for index in {0..4}; do
			dimens=$(file icon-${index}.png | grep -Eo "[[:digit:]]+ *x *[[:digit:]]+")
			dimens="${dimens% x*}"
			dest="$HOME/.local/share/icons/hicolor/${dimens}x${dimens}"
			[[ ! -e "$dest" ]] && mkdir -p "$dest"
			[[ ! -e "$dest/apps" ]] && mkdir -p "$dest/apps"
			[[ ! -e "$dest/mimetypes" ]] && mkdir -p "$dest/mimetypes"
			[[ -f "$dest/apps/infinitas.png" ]] && echo -e "$WARN_LABEL Overwriting $dest/apps/infinitas.png!"
			cp -f icon-${index}.png "$dest/apps/infinitas.png" 2>/dev/null
			[[ -f "$dest/mimetypes/x-scheme-handler-bm2dxinf.png" ]] && echo -e "$WARN_LABEL Overwriting $dest/mimetypes/x-scheme-handler-bm2dxinf.png!"
			cp -f icon-${index}.png "$dest/mimetypes/x-scheme-handler-bm2dxinf.png" 2>/dev/null
		done
		unset iconLocation dimens dest index
	cd ..
	rm -rf tmpIconDir
	
	[[ $(which gtk-update-icon-cache 2>/dev/null) ]] && gtk-update-icon-cache
	return 0
}

if [[ -n "$1" && "$1" == '--flatpak' ]]; then
	useFlatpak=true
fi

# adjust settings if the user is on flatpak
if [[ $useFlatpak == true ]]; then
	[[ -z $(which flatpak 2>/dev/null) ]] && echo -e "$ERROR_LABEL Flatpak was not found on your system." && exit 2
	[[ -z $(flatpak list --app --columns=application | grep -w 'org.winehq.Wine') ]] && echo -e "$ERROR_LABEL Wine (Flatpak) has not been installed to your system." && exit 2
	EXTRA_FLATPAK_ARGS="--env=WINEPREFIX=$prefixLocation --filesystem=$prefixLocation --filesystem=$tempDir:ro"
	WINE="flatpak run --command=wine64 $EXTRA_FLATPAK_ARGS org.winehq.Wine"
	WINEBOOT="flatpak run --command=wineboot $EXTRA_FLATPAK_ARGS org.winehq.Wine"
	WINESERVER="flatpak run --command=wineserver $EXTRA_FLATPAK_ARGS org.winehq.Wine"
	echo -e "$WARN_LABEL Using Flatpak build of Wine!"
else
	if [[ -n $customWine ]]; then
		[[ ! -f "$customWine/bin/wine64" ]] && echo -e "$ERROR_LABEL Couldn't find wine64 executable in $customWine" && exit 2
		[[ ! -f "$customWine/bin/wineboot" ]] && echo -e "$ERROR_LABEL Couldn't find wineboot executable in $customWine" && exit 2
		[[ ! -f "$customWine/bin/wineserver" ]] && echo -e "$ERROR_LABEL Couldn't find wineserver executable in $customWine" && exit 2

		WINE="$customWine/bin/wine64"
		WINEBOOT="$customWine/bin/wineboot"
		WINESERVER="$customWine/bin/wineserver"
	else
		[[ ! -f $(which wine 2>/dev/null) ]] && echo -e "$ERROR_LABEL Missing dependency \033[1;91mwine\033[0m" && exit 2
		[[ ! -f $(which wine64 2>/dev/null) ]] && echo -e "$ERROR_LABEL Missing dependency \033[1;91mwine (wine64 missing)\033[0m" && exit 2
		[[ ! -f $(which wineboot 2>/dev/null) ]] && echo -e "$ERROR_LABEL Missing dependency \033[1;91mwine (wineboot missing)\033[0m" && exit 2
		[[ ! -f $(which wineserver 2>/dev/null) ]] && echo -e "$ERROR_LABEL Missing dependency \033[1;91mwine (wineserver missing)\033[0m" && exit 2
	
		WINE=$(which wine64 2>/dev/null)
		WINEBOOT=$(which wineboot 2>/dev/null)
		WINESERVER=$(which wineserver 2>/dev/null)
	fi
	export WINEPREFIX="$prefixLocation"
fi

[[ ! -e "$prefixLocation" ]] && echo "Creating new Wineprefix at $prefixLocation..." && mkdir -p "$prefixLocation" 2>/dev/null
		
# check dependencies
[[ $useFlatpak == false ]] && [[ -z $(which wine64 2>/dev/null) ]] && echo -e "$ERROR_LABEL Missing dependency \033[1;91mwine\033[0m" && exit
[[ -z $(which msiextract 2>/dev/null) ]] && echo -e "$ERROR_LABEL Missing dependency \033[1;91mmsitools\033[0m" && exit 2
# literally every single distro has tar installed, but this check is staying for those that unknowingly removed it
[[ -z $(which tar 2>/dev/null) ]] && echo -e "$ERROR_LABEL Missing dependency \033[1;91mtar\033[0m" && exit 2
[[ -z $(which wget 2>/dev/null) ]] && echo -e "$ERROR_LABEL Missing dependency \033[1;91mwget\033[0m" && exit 2
[[ -z $(which pipewire 2>/dev/null) ]] && echo -e "$ERROR_LABEL Missing dependency \033[1;91mpipewire\033[0m" && exit 2
[[ -z $(which pw-loopback 2>/dev/null) ]] && echo -e "$ERROR_LABEL Missing dependency \033[1;91mpipewire (pw-loopback missing)\033[0m" && exit 2
[[ -z $(which magick 2>/dev/null) ]] && echo -e "$WARN_LABEL Missing optional dependency \033[1;93mimagemagick\033[0m. You will not be able to create the launcher icons for beatmania IIDX INFINITAS."
#[[ -z $(which gamescope 2>/dev/null) ]] && echo -e "$WARN_LABEL Missing optional dependency \033[1;93mgamescope\033[0m. You will not be able to run beatmania IIDX INFINITAS in a gamescope session."
[[ -z $(which gamemoderun 2>/dev/null) ]] && echo -e "$WARN_LABEL Missing optional dependency \033[1;93mgamemode\033[0m. Game performance may be affected."
echo -e "\033[1;92mAll required dependencies satisfied!\033[0m"

MSIEXTRACT="$(which msiextract 2>/dev/null)"
TAR="$(which tar 2>/dev/null)"
WGET="$(which wget 2>/dev/null)"

export WINEDLLOVERRIDES="mscoree,mshtml="	# just so wine doesn't try to install mono and gecko

mkdir -p $tempDir
cd $tempDir

# warn if installing to an existing prefix
if [[ -f "$prefixLocation/system.reg" ]]; then
	if [[ -d "$prefixLocation/dosdevices/c:/Games/beatmania IIDX INFINITAS" ]]; then
		echo -e "$WARN_LABEL An existing installation of beatmania IIDX INFINITAS was detected within this Wineprefix!"
		ynPrompt "Would you like to overwrite the launcher files?" 1
		if [[ $? -ne 0 ]]; then
			echo -e "$ERROR_LABEL Aborting replacement of existing launcher files..."
			echo -e "Tip: If you are looking to just reinstall/repair some parts of your installation (launchers, registry keys, etc.), run \033[1m$0 help\033[0m for a list of useful commands"
			exit 1
		fi
		ynPrompt "Would you also like to remove ALL game files?" 1
		if [[ $? -eq 0 ]]; then
			echo "Removing beatmania IIDX INFINITAS..."
			rm -rf "$prefixLocation/dosdevices/c:/Games/beatmania IIDX INFINITAS" 2>/dev/null
		else
			echo "Removing beatmania IIDX INFINITAS launcher..."
			rm -rf "$prefixLocation/dosdevices/c:/Games/beatmania IIDX INFINITAS/launcher" 2>/dev/null
			rm -rf "$prefixLocation/dosdevices/c:/Games/beatmania IIDX INFINITAS/old" 2>/dev/null
		fi
	else
		echo -e "$WARN_LABEL Installing beatmania IIDX INFINITAS to an existing Wineprefix is NOT recommended!"
	fi
	$WINEBOOT -u 2>/dev/null
else
	$WINEBOOT -i 2>/dev/null
fi

sleep 2
		
# show disclaimer
echo -e $disclaimer
ynPrompt "Do you agree to these terms?"
if [[ "$?" -ne 0 ]]; then
	echo -e "$ERROR_LABEL You have not accepted the agreement. Exiting installer..."
	exit 1
fi

# download game files
echo "Downloading installer for beatmania IIDX INFINITAS..."
if [[ -f "$tempDir/$(basename -- $INFINITAS_LINK)" ]]; then
	echo "Skipped: Found beatmania IIDX INFINITAS installer..."
else
	$WGET "$INFINITAS_LINK"
	if [[ $? -ne 0 ]]; then
		echo -e "$ERROR_LABEL Failed to download beatmania IIDX INFINITAS launcher!"
		exit 2
	fi
fi

# extract gamefiles
echo "Extracting files from installer..."
$MSIEXTRACT "$tempDir/$(basename -- $INFINITAS_LINK)" > /dev/null
mkdir "$tempDir/Games/beatmania IIDX INFINITAS/Resource" 2>/dev/null

# delete unnecessary folders, such as the DirectX 9.0c Redist installer
rm -rf "$tempDir/Win" 2>/dev/null
rm -rf "$tempDir/Games/beatmania IIDX INFINITAS/DirectX 9.0c Redist" 2>/dev/null

# add registry keys
echo "Adding registry keys..."
$WINE reg add 'HKLM\SOFTWARE\KONAMI\beatmania IIDX INFINITAS' /v 'InstallDir' /t 'REG_SZ' /d 'C:\\Games\\beatmania IIDX INFINITAS\\' /f
$WINE reg add 'HKLM\SOFTWARE\KONAMI\beatmania IIDX INFINITAS' /v 'ResourceDir' /t 'REG_SZ' /d 'C:\\Games\\beatmania IIDX INFINITAS\\Resource\\' /f
$WINE reg add 'HKLM\SOFTWARE\Microsoft\DirectDraw' /v 'ForceRefreshRate' /t 'REG_DWORD' /d 00000078 /f
$WINE reg add 'HKCU\SOFTWARE\Wine\Explorer' /v 'Desktops' /t 'REG_SZ' /d 'Default' /f
$WINE reg add 'HKCU\SOFTWARE\Wine\Explorer\Desktops' /v 'Default' /t 'REG_SZ' /d '1920x1080' /f

# download vcr2010
echo "Downloading Microsoft Visual C++ Redist 2010..."
if [[ -f "$tempDir/vcredist_x64.exe" ]]; then
	echo "Skipped: Found vcr2010 installer..."
else
	$WGET "$VCR2010_LINK"
	if [[ "$?" -ne 0 ]]; then
		echo -e "$ERROR_LABEL Failed to download Visual C++ Redist 2010!"
		exit 2
	fi
fi

# install vcr2010
echo "Installing Microsoft Visual C++ Redist 2010..."
$WINE 'vcredist_x64.exe' '/quiet' 2>/dev/null
if [[ $? -ne 0 ]]; then
	echo -e "$ERROR_LABEL Failed to install Visual C++ Redist 2010!"
fi

# install dxvk
echo "Downloading DXVK..."
if [[ "$(which setup_dxvk 2>/dev/null)" || "$(which setup_dxvk.sh 2>/dev/null)" ]] && [[ $useFlatpak == false ]]; then
	echo "Skipped: Found setup_dxvk install script..."
	[[ "$(which setup_dxvk 2>/dev/null)" ]] && dxvk_installer="setup_dxvk"
	[[ "$(which setup_dxvk.sh 2>/dev/null)" ]] && dxvk_installer="setup_dxvk.sh"
	echo "Running $dxvk_installer..."
	$dxvk_installer install > /dev/null
else
	if [[ -f "$tempDir/$(basename -- $DXVK_LINK)" ]]; then
		echo "Skipped: Found DXVK archive..."
	else
		$WGET "$DXVK_LINK"
		if [[ $? -ne 0 ]]; then
			echo -e "$ERROR_LABEL Failed to download DXVK archive!"
			exit 2
		fi
	fi

	# extract dxvk archive
	echo "Extracting DXVK archive..."
	$TAR -zxf $(basename -- $DXVK_LINK) 2>/dev/null
	echo "Moving .dll files..."
	cp -f $tempDir/dxvk*/x64/d3d9.dll "$prefixLocation/dosdevices/c:/windows/system32/"
	cp -f $tempDir/dxvk*/x32/d3d9.dll "$prefixLocation/dosdevices/c:/windows/syswow64/"
	$WINE reg add 'HKCU\Software\Wine\DllOverrides' /v 'd3d9' /d 'native,builtin' /f
	fi

# create icons
create_icons "$(find "$tempDir/Games/beatmania IIDX INFINITAS" -type f -name "*.ico")"
create_launcher

# move game files to prefix
cp -r "$tempDir/Games" "$prefixLocation/dosdevices/c:/"
cat > "$prefixLocation/infinitas" <<EOF
#!/usr/bin/env bash
ERROR_LABEL="\033[1;91m-> ERROR:\033[0m"
WARN_LABEL="\033[1;93m-> WARNING:\033[0m"

# CONFIG:
# this whole thing has been driving me absolutely insane, and i can't stand it anymore.
# so these are the options you're getting, until i get the help i need.
prefix_location="$prefixLocation
use_flatpak_wine=$useFlatpak
pulse_latency=40

LAUNCH_TOKEN="\$1"

# Gamescope blocker
# This part will terminate gamescope if the script detects it's running within gamescope.
# Note: if you want to enable gamescope, do so with INFINITAS_USE_GAMESCOPE=1
if [[ \$GAMESCOPE_WAYLAND_DISPLAY || \$XDG_CURRENT_DESKTOP == 'gamescope' ]]; then
	echo -e "\n\n\t\033[1;91m!!! DO NOT RUN THIS SCRIPT DIRECTLY THROUGH GAMESCOPE !!!\033[0m\n\n"
	killall -ABRT gamescope-wl
	exit 134
fi

# check wine
if [[ \$use_flatpak_wine == true ]]; then
    [[ -z \$(which flatpak 2>/dev/null) ]] && echo -e "\$ERROR_LABEL Flatpak was not found on your system." && exit 2
	[[ -z \$(flatpak list --app --columns=application | grep -w 'org.winehq.Wine') ]] && echo -e "\$ERROR_LABEL Wine (Flatpak) has not been installed to your system." && exit 2
	EXTRA_FLATPAK_ARGS="--env=WINEPREFIX=\$prefix_location --env=WINEDEBUG='-all' --filesystem=\$prefix_location"
	WINE="flatpak run --command=wine64 \$EXTRA_FLATPAK_ARGS org.winehq.Wine"
	WINESERVER="flatpak run --command=wineserver $\EXTRA_FLATPAK_ARGS org.winehq.Wine"
else
    [[ ! -f \$(which wine 2>/dev/null) ]] && echo -e "\$ERROR_LABEL Missing dependency \033[1;91mwine\033[0m" && exit 2
    [[ ! -f \$(which wine64 2>/dev/null) ]] && echo -e "\$ERROR_LABEL Missing dependency \033[1;91mwine (wine64 missing)\033[0m" && exit 2
    [[ ! -f \$(which wineserver 2>/dev/null) ]] && echo -e "\$ERROR_LABEL Missing dependency \033[1;91mwine (wineserver missing)\033[0m" && exit 2

    WINE=\$(which wine64 2>/dev/null)
    WINESERVER=\$(which wineserver 2>/dev/null)

    export WINEPREFIX="\$prefix_location"
    export WINEDEBUG='-all'
fi

# check time
if [[ \$(date -u +%l) -ge 20 && \$(date -u +%l) -lt 22 ]]; then
	approx_time=\$(printf '%(%l:%M%P %Z)T\n' "\$(date +%s -u -d "22:00")")
	if [[ "\${approx_time:0:1}" == ' ' ]]; then
		approx_time="\${approx_time:1}"
	fi
	show_error "e-amusement Cloud servers down" "The e-amusement Cloud servers are currently down for maintenance.\nPlease wait until \$approx_time and try again." 1
	exit 1
fi

if [[ -z \$LAUNCH_TOKEN ]]; then
    export TERM=dumb
    exec xdg-open "https://p.eagate.573.jp/game/infinitas/2/api/login/login.html"
fi

[[ "\${LAUNCH_TOKEN:0:1}" != 'b' ]] && LAUNCH_TOKEN="\${LAUNCH_TOKEN:1:-1}" && echo "fixing login string"
[[ "\${LAUNCH_TOKEN:0:11}" != 'bm2dxinf://' ]] && show_error "Failed to start game" "Invalid login string provided" 2
[[ "\${#LAUNCH_TOKEN}" -ne 89 && "\${#LAUNCH_TOKEN}" -ne 91 ]] && show_error "Failed to start game" "Login string provided is an invalid length" 3
[[ "\${LAUNCH_TOKEN:85}" != 'rel=' && "\${LAUNCH_TOKEN:85}" != 'trial=' ]] && show_error "Failed to start game" "Login string contains an unknown mode: \${LAUNCH_TOKEN:85:-1}" 4

# check for iidx launcher
[[ ! -e "\$prefix_location/system.reg" ]] && show_error_msgbox "Failed to start game" "Invalid Wineprefix provided" 1
[[ ! -e "\$prefix_location/dosdevices/c:/Games/beatmania IIDX INFINITAS" ]] && show_error_msgbox "Failed to start game" "Couldn't find beatmania IIDX INFINITAS" 1
[[ ! -e "\$prefix_location/dosdevices/c:/Games/beatmania IIDX INFINITAS/launcher/modules/bm2dx_launcher.exe" ]] && show_error_msgbox "Failed to start game" "Couldn't find beatmania IIDX INFINITAS Launcher (bm2dx_launcher.exe)" 1
cd "\$prefixLocation/dosdevices/c:/"

# create loopback device
pw-loopback -m '[ FL FR ]' --capture-props='media.class=Audio/Sink node.name=infinitas node.description=infinitas audio.rate=44100' &
export PULSE_SINK='infinitas' # to ensure the wine process defaults to using this loopback instead of your system's defaults.
export PULSE_LATENCY_MSEC=\$pulse_latency

# now to run the game
\$WINESERVER -p5	# keep wineserver alive for a bit
\$WINE 'C:\Games\beatmania IIDX INFINITAS\launcher\modules\bm2dx_launcher.exe' "\$LAUNCH_TOKEN"
\$WINESERVER -w

# kill everything
sleep 1
kill -15 \$(jobs -p)
exit
EOF

chmod a+x $prefixLocation/infinitas
# clean up temp directory
rm -rf $tempDir

sleep 2
echo -e "\033[1;92mbeatmania IIDX INFINITAS has been successfully installed!\033[0m"
echo -e "Find the launcher within your DE/WM, or visit \033[1mhttps://p.eagate.573.jp/game/infinitas/2/api/login/login.html\033[0m in your browser to launch the game!"
exit
