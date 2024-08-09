#!/usr/bin/env bash

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

# TODO: rewrite this entire damn thing. maybe in a real programming language, too.
[[ $UID -eq 0 ]] && echo "This script should not be ran as root." && exit 127

# check dependencies before starting
[[ -z $(which wine 2>/dev/null) ]] && echo "Missing dependency: wine" && exit 2

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PREFIX_LOCATION="$HOME/.local/share/infinitas"
ERROR_LABEL="\033[1;91m-> ERROR:\033[0m"
WARN_LABEL="\033[1;92m-> WARNING:\033[0m"

export WINEDLLOVERRIDES="mscoree,mshtml="	# just so wine doesn't try to install mono and gecko

# this is the entire game launcher, right here.
read -rd '' launcher <<EOF
#!/usr/bin/env bash
[[ \$UID -eq 0 ]] && echo "This script should not be ran as root." && exit 127
[[ -z \$(which kdialog 2>/dev/null) ]] && echo "Missing dependency: kdialog" && exit 2
[[ -z \$(which wine 2>/dev/null) ]] && echo "Missing dependency: wine" && exit 2
[[ -z \$(which pipewire 2>/dev/null) ]] && echo "Missing dependency: pipewire" && exit 2

show_error_msgbox() {
    kdialog --title "ERROR" --error "\$1" 2>/dev/null
}

LOGIN_TOKEN="\$1"
INFINITAS_LAUNCHER='C:\\Games\\beatmania IIDX INFINITAS\\launcher\\modules\\bm2dx_launcher.exe'
export WINEDLLOVERRIDES="mscoree,mshtml="	# just so wine doesn't try to install mono and gecko
export WINEPREFIX="$PREFIX_LOCATION"

WINE="\$(which wine 2>/dev/null)"
validate_prefix() {
    [[ ! -e "\$WINEPREFIX" ]] && show_error_msgbox "Couldn't find Wineprefix" && exit 1
    [[ ! -e "\$WINEPREFIX/system.reg" ]] && show_error_msgbox "The Wineprefix is corrupted." && exit 2
    [[ ! -e "\$WINEPREFIX/drive_c/Games/beatmania IIDX INFINITAS/launcher/modules/bm2dx_launcher.exe" ]] && show_error_msgbox "Couldn't find beatmania IIDX INFINITAS Launcher." && exit 3
    return 0
}

validate_launch_string() {
    [[ -z \$LOGIN_TOKEN ]] && show_error_msgbox "No login token provided." && exit 1
    # Fix the launch string if it's surrounded by quote marks (firefox moment lol).
    [[ "\${LOGIN_TOKEN:0:1}" != 'b' ]] && LOGIN_TOKEN="\${LOGIN_TOKEN:1:-1}" && echo "fixing login string"
    [[ "\${LOGIN_TOKEN:0:11}" != 'bm2dxinf://' ]] && show_error_msgbox "Invalid login string provided" && exit 2
    [[ "\${#LOGIN_TOKEN}" -ne 89 && "\${#LOGIN_TOKEN}" -ne 91 ]] && show_error_msgbox "Login string provided is an invalid length" && exit 3
    [[ "$\{LOGIN_TOKEN:85}" != 'rel=' && "\${LOGIN_TOKEN:85}" != 'trial=' ]] && show_error_msgbox "Login string contains an unknown mode: \${LOGIN_TOKEN:85:-1}" && exit 4
    return 0
}

# check if INFINITAS_USE_GAMESCOPE is set to 1
# the if statement below will not stop this check
if [[ -n \$INFINITAS_USE_GAMESCOPE && \$INFINITAS_USE_GAMESCOPE -eq 1 ]]; then
	if [[ -n \$(which gamescope 2>/dev/null) ]]; then
		echo "Using gamescope"
		GS_CMD="\$(which gamescope) -h 1080 -w 1920 -r 120 --framerate-limit 120 -f --"
		exit # so this script won't try to launch the game again,
	else
		[[ \$(which notify-send 2>/dev/null) ]] && notify-send "Gamescope not found!" -i "infinitas" -a "beatmania IIDX INFINITAS" "Environment variable INFINITAS_USE_GAMESCOPE is set, but gamescope was not found on your system."
    fi
fi

# Gamescope blocker
# This part will terminate gamescope if the script detects it's running within gamescope.
# Note: if you want to enable gamescope, do so with INFINITAS_USE_GAMESCOPE=1
if [[ \$GAMESCOPE_WAYLAND_DISPLAY || \$XDG_CURRENT_DESKTOP == 'gamescope' ]]; then
	echo -e "\n\n\t\033[1;91m!!! DO NOT RUN THIS SCRIPT DIRECTLY THROUGH GAMESCOPE !!!\033[0m\n\n"
	killall -ABRT gamescope-wl
	exit 134
fi

# Time check
# This is absolutely necessary to prevent the player from trying to access the game whenever the e-amusement cloud
# servers are down for maintenance (between 20:00~22:00 UTC).
if [[ \$(date -u +%l) -ge 20 && \$(date -u +%l) -lt 22 ]]; then
	approx_time=\$(printf '%(%l:%M%P %Z)T\n' "\$(date +%s -u -d "22:00")")
	if [[ "\${approx_time:0:1}" == ' ' ]]; then
		approx_time="\${approx_time:1}"
	fi
	show_error_msgbox "The e-amusement Cloud servers are currently down for maintenance.\nPlease wait until \$approx_time and try again."
	exit 1
fi

validate_launch_string
#validate_wine
validate_prefix

# create loopback device
pw-loopback -m '[ FL FR ]' --capture-props='media.class=Audio/Sink node.name=infinitas node.description=infinitas audio.rate=44100' &
export PULSE_SINK='infinitas' # to ensure the wine process defaults to using this loopback instead of your system's defaults.
export PULSE_LATENCY_MSEC=45  # to ensure the game audio doesn't summon demons
# and now we run the game.
if [[ -n "\$GS_CMD" ]]; then
	"\$GS_CMD" \$WINE explorer "/desktop=INFINITAS,1920x1080" "\$INFINITAS_LAUNCHER" "\$LOGIN_TOKEN"
else
	\$WINE explorer "/desktop=INFINITAS,1920x1080" "\$INFINITAS_LAUNCHER" "\$LOGIN_TOKEN"
fi

sleep 1
killall -15 pw-loopback # kill loopback device
exit
EOF

install_cmd() {
	[[ -z $(which msiextract 2>/dev/null) ]] && echo "Missing dependency: msitools" && exit 2
	[[ -z $(which tar 2>/dev/null) ]] && echo "Missing dependency: tar" && exit 2
	[[ -z $(which wget 2>/dev/null) ]] && echo "Missing dependency: wget" && exit 2
	[[ -z $(which magick 2>/dev/null) ]] && echo "Missing dependency: imagemagick" && exit 2
 	[[ -z \$(which kdialog 2>/dev/null) ]] && echo "Missing dependency: kdialog" && exit 2
	[[ -z \$(which wine 2>/dev/null) ]] && echo "Missing dependency: wine" && exit 2
	[[ -z \$(which pipewire 2>/dev/null) ]] && echo "Missing dependency: pipewire" && exit 2
	DXVK_LINK="https://github.com/doitsujin/dxvk/releases/download/v2.4/dxvk-2.4.tar.gz"
	INFINITAS_LINK="https://d1rc4pwxnc0pe0.cloudfront.net/v2/installer/infinitas_installer_2022060800.msi"
	VCS2010_LINK="https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe"
	
	TEMP_DIRECTORY="/tmp/iidx"

	# installer variables
	INSTALL_LOCATION="$HOME/.local/share/infinitas"
	WINE_EXE=$(which wine 2>/dev/null)
	WINE64_EXE=$(which wine64 2>/dev/null)
	WINEBOOT_EXE=$(which wineboot 2>/dev/null)
	MSIEXTRACT_EXE=$(which msiextract 2>/dev/null)
	WGET_EXE=$(which wget 2>/dev/null)
	TAR_EXE=$(which tar 2>/dev/null)
	MAGICK_EXE=$(which magick 2>/dev/null)

	show_disclaimer() {
		echo -e "\n\033[1;4;91mDISCLAIMER: READ BEFORE CONTINUING\033[0;1;91m"
cat <<'EOM'

This script is in no way affiliated with, endorsed, nor supported by KONAMI. In order to access the full game outside
of trial mode, you must be subscribed to the beatmania IIDX INFINITAS Basic Course. This script will NOT allow you to
gain access to things you aren't paying for, nor will the script developer assist you with such actions.

Like most online games today, getting banned for playing the game on GNU/Linux (outside of what the developers
intended) is a possibility. The script developer is not to be held responsible, should you receive any bans from use of
this script.

Play at your own risk.
EOM
		echo -e "$disclaimer\033[0m"
		while true; do
			read -p "$(printf "\033[0;1mContinue with the installation\?\033[0m [\033[92mY\033[0m/\033[91mN\033[0m] \033[1;96m")" ch
			if [[ -n "$ch" ]]; then
				if [[ "$ch" == [Yy] || "$ch" == [Yy][Ee][Ss] ]]; then
					echo -en "\033[0m\n\033[92mYou have accepted the disclaimer. Continuing...\033[0m\n"
					break
				elif [[ "$ch" == [Nn] || "$ch" == [Nn][Oo] ]]; then
					echo -en "\033[0m\n\033[92mYou have declined the disclaimer. Quitting...\033[0m\n"
					exit 1
				else
                	echo -e "Invalid option: \033[1m$ch\033[0m"
				fi
			else
				echo -e "Please specify either \033[92myes\033[0m or \033[91mno\033[0m"
			fi
		done
	}

    infinitas_install() {
		echo "Downloading beatmania IIDX INFINITAS installer..."
		$WGET_EXE "$INFINITAS_LINK"
		if [[ $? -ne 0 ]]; then
			echo -e "$ERROR_LABEL to download beatmania IIDX INFINITAS installer!"
			cleanup
			exit 2
		fi

		# extract files from installer and move them to prefix
		echo "Extracting files from beatmania IIDX INFINITAS installer..."
		$MSIEXTRACT_EXE "infinitas_installer_2022060800.msi" > /dev/null
		rm -rf "$TEMP_DIRECTORY/Win"	# remove this dir
		rm -rf "$TEMP_DIRECTORY/Games/beatmania IIDX INFINITAS/DirectX 9.0c Redist" # and this.
		mkdir "$TEMP_DIRECTORY/Games/beatmania IIDX INFINITAS/Resource" # and make this so the game can store data
		mv "$TEMP_DIRECTORY/Games" "$INSTALL_LOCATION/drive_c/Games" # now move it to the prefix

		# add registry keys so the launcher doesn't 5-1601-0013 (no registry keys)
		# obviously have to use wine64 (lulz)
		echo "Applying registry keys..."
		$WINE64_EXE reg add 'HKLM\SOFTWARE\KONAMI\beatmania IIDX INFINITAS' /v 'InstallDir' /t 'REG_SZ' /d 'C:\\Games\\beatmania IIDX INFINITAS\\' /f
		$WINE64_EXE reg add 'HKLM\SOFTWARE\KONAMI\beatmania IIDX INFINITAS' /v 'ResourceDir' /t 'REG_SZ' /d 'C:\\Games\\beatmania IIDX INFINITAS\\Resource\\' /f
	}

	vcr2010_install() {
		echo "Downloading Microsoft Visual C++ Redist 2010..."
		$WGET_EXE "$VCS2010_LINK"
		if [[ $? -ne 0 ]]; then
			echo -e "$ERROR_LABEL Failed to download vcr2010.exe!"
			cleanup
			exit 2
		fi

		echo "Installing Microsoft Visual C++ Redist 2010..."
		$WINE_EXE $TEMP_DIRECTORY/vcredist*.exe '/quiet'
		if [[ $? -ne 0 ]]; then
			echo -e "$ERROR_LABEL Failed to install vcr2010!"
			cleanup
			exit 2
		fi
	}

	dxvk_install() {
		echo "Downloading DXVK..."
		$WGET_EXE "$DXVK_LINK"
		if [[ $? -ne 0 ]]; then
			echo -e "$ERROR_LABEL Failed to download DXVK!"
			cleanup
			exit 2
		fi


		echo "Extracting DXVK archive..."
		$TAR_EXE -zxf "$TEMP_DIRECTORY/dxvk-2.4.tar.gz"

		echo "Moving .dll files..."
		cp -f $TEMP_DIRECTORY/dxvk*/x64/d3d9.dll "$INSTALL_LOCATION/drive_c/windows/system32/"
		cp -f $TEMP_DIRECTORY/dxvk*/x32/d3d9.dll "$INSTALL_LOCATION/drive_c/windows/syswow64/"

		echo "Setting overrides..."
		$WINE64_EXE reg add 'HKCU\Software\Wine\DllOverrides' /v 'd3d9' /d 'native,builtin' /f
		# i'll add these anyways, even though they're unnecessary, since infinitas runs in DX9.0c
		#$WINE64_EXE reg add 'HKCU\Software\Wine\DllOverrides' /v 'd3d10core' /d 'native,builtin' /f > /dev/null
		#$WINE64_EXE reg add 'HKCU\Software\Wine\DllOverrides' /v 'd3d11' /d 'native,builtin' /f > /dev/null
		#$WINE64_EXE reg add 'HKCU\Software\Wine\DllOverrides' /v 'd3xgi' /d 'native,builtin' /f > /dev/null
	}

	set_default_settings() {
		echo "Applying default game settings..."
		mkdir -p "$INSTALL_LOCATION/drive_c/Games/beatmania IIDX INFINITAS/Resource/config/"

cat >> "$INSTALL_LOCATION/drive_c/Games/beatmania IIDX INFINITAS/Resource/config/1000_cf.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<SettingDatas xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <Parameters>
    <KeyValuePair>
      <Key>
        <string>DisplaySettings</string>
      </Key>
      <Value>
        <string>0</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>AudioPlaySettings</string>
      </Key>
      <Value>
        <string>1</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>FPSSettings</string>
      </Key>
      <Value>
        <string>0</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig1P_1</string>
      </Key>
      <Value>
        <string>256</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig1P_2</string>
      </Key>
      <Value>
        <string>257</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig1P_3</string>
      </Key>
      <Value>
        <string>258</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig1P_4</string>
      </Key>
      <Value>
        <string>259</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig1P_5</string>
      </Key>
      <Value>
        <string>260</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig1P_6</string>
      </Key>
      <Value>
        <string>261</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig1P_7</string>
      </Key>
      <Value>
        <string>262</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig1P_CW</string>
      </Key>
      <Value>
        <string>263</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig1P_CCW</string>
      </Key>
      <Value>
        <string>264</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig1P_E1</string>
      </Key>
      <Value>
        <string>266</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig1P_E2</string>
      </Key>
      <Value>
        <string>265</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig1P_E3</string>
      </Key>
      <Value>
        <string>267</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig1P_E4</string>
      </Key>
      <Value>
        <string>268</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig2P_1</string>
      </Key>
      <Value>
        <string>256</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig2P_2</string>
      </Key>
      <Value>
        <string>257</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig2P_3</string>
      </Key>
      <Value>
        <string>258</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig2P_4</string>
      </Key>
      <Value>
        <string>259</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig2P_5</string>
      </Key>
      <Value>
        <string>260</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig2P_6</string>
      </Key>
      <Value>
        <string>261</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig2P_7</string>
      </Key>
      <Value>
        <string>262</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig2P_CW</string>
      </Key>
      <Value>
        <string>263</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig2P_CCW</string>
      </Key>
      <Value>
        <string>264</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig2P_E1</string>
      </Key>
      <Value>
        <string>265</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig2P_E2</string>
      </Key>
      <Value>
        <string>266</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig2P_E3</string>
      </Key>
      <Value>
        <string>267</string>
      </Value>
    </KeyValuePair>
    <KeyValuePair>
      <Key>
        <string>KeyConfig2P_E4</string>
      </Key>
      <Value>
        <string>268</string>
      </Value>
    </KeyValuePair>
  </Parameters>
</SettingDatas>
EOF
    }

    create_icons() {
		iconLocation="$(find "$INSTALL_LOCATION/drive_c/Games/beatmania IIDX INFINITAS" -type f -name "*.ico")"
		mkdir tmpIconDir
		cd tmpIconDir
		$MAGICK_EXE "$iconLocation" icon.png
		for index in {0..4}; do
			dimens=$(file icon-${index}.png | grep -Eo "[[:digit:]]+ *x *[[:digit:]]+")
			dimens="${dimens% x*}"
			dest="$HOME/.local/share/icons/hicolor/${dimens}x${dimens}"
			[[ ! -e "$dest" ]] && mkdir -p "$dest"
			[[ ! -e "$dest/apps" ]] && mkdir -p "$dest/apps"
			[[ ! -e "$dest/mimetypes" ]] && mkdir -p "$dest/mimetypes"
			cp icon-${index}.png "$dest/apps/infinitas.png" 2>/dev/null
			cp icon-${index}.png "$dest/mimetypes/x-scheme-handler-bm2dxinf.png" 2>/dev/null
		done
		unset iconLocation dimens dest index
		cd ..
		rm -rf tmpIconDir
	}

    create_desktop_file() {
# launcher that will handle opening the actual game
cat > $HOME/.local/share/applications/infinitas.desktop <<EOF
[Desktop Entry]
MimeType=x-scheme-handler/bm2dxinf
Exec=$WINEPREFIX/infinitas %u
Icon=infinitas
NoDisplay=true
Name=beatmania IIDX INFINITAS Launcher
Type=Application
EOF

# launcher that will open the website
cat > $HOME/.local/share/applications/infinitas-launcher.desktop <<EOF
[Desktop Entry]
Categories=Application;Game;
Comment=Launch beatmania IIDX INFINITAS
GenericName=Rhythm Game
Exec=xdg-open https://p.eagate.573.jp/game/infinitas/2/api/login/login.html
Icon=infinitas
Name=beatmania IIDX INFINITAS
Type=Application
EOF
        update-desktop-database $HOME/.local/share/applications
    }

    create_mimetype() {
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
        update-mime-database $HOME/.local/share/mime
    }

	cleanup() {
		rm -rf $TEMP_DIRECTORY
		wineserver -k
	}

	mkdir -p $INSTALL_LOCATION 2>/dev/null
	export WINEPREFIX="$INSTALL_LOCATION"

	mkdir $TEMP_DIRECTORY
	cd $TEMP_DIRECTORY

	$WINEBOOT_EXE -i 2>/dev/null

    show_disclaimer         # make sure konmai won't sue me for what you do
	infinitas_install		# download the infinitas launcher and install the files
	vcr2010_install			# download and install visual c++ runtime 2010 to the prefix
	dxvk_install			# install dxvk to the prefix
	set_default_settings	# changes game settings to set audio mode to WASAPI (shared) and video mode to automatic
	create_icons            # creates the icons for the game
	create_desktop_file     # create the desktop launcher
	create_mimetype         # create the handler for the bm2dxinf:// URI
	cleanup					# clean up temp files.

	echo "$launcher" > "$WINEPREFIX/infinitas" # copy the launcher script to the prefix
	chmod +x "$WINEPREFIX/infinitas"

	echo -e "\033[1;92mbeatmania IIDX INFINITAS has been successfully installed!\033[0m"
	echo -e "Visit \033[1mhttps://p.eagate.573.jp/game/infinitas/2/api/login/login.html\033[0m in your browser to start playing!"
	exit
}

# TODO: allow the user to add arguments for reinstalling registry keys, dxvk, etc.
install_cmd
