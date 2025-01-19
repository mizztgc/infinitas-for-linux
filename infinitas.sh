#!/usr/bin/env bash

# Infinitas for Linux by Mizzt (mizztgc)

# This is just a barebones script for installing and launching beatmania IIDX INFINITAS, and doesn't include
# special features like custom prefixes/winebuilds, gamescope, etc. I did try to implement them, but I'm not a
# fan of overcomplicating things, so I stripped them out.

# And while I have you here, I would like to inform you that this script is unofficial. It's not endorsed,
# supported, nor affiliated with KONAMI Amusement. This script will NOT grant you access to the full game
# without an active basic course subscription to beatmania IIDX INFINITAS, nor will I allow you to do so (I
# can't afford to have konmai sending the yakuza to my house). Due to the nature of Linux, getting banned from
# the e-amusement Cloud network is a possibility, so play at your own risk.

# Your system will need the following dependencies to use this script:
# (all dependencies listed are the package names on Arch Linux. check your distro's package manager for the
# relevant packages)
# - wine>=9.0 (obviously!)
# - pipewire
# - pipewire-pulse
#     !! Debian users may also need to install pulseaudio-utils for enabling the loopback device !!
# - pipewire-audio
# - libpulse
# - wget
# - xdg-utils
# - zenity
# - icoutils

# Game information
GAME_TITLE='beatmania IIDX INFINITAS'
DIR_TITLE="${GAME_TITLE}"
SIMPLE_NAME="infinitas"
INSTALLER_LINK="https://d1rc4pwxnc0pe0.cloudfront.net/v2/installer/infinitas_installer_2022060800.msi"
LAUNCH_PAGE="https://p.eagate.573.jp/game/infinitas/2/api/login/login.html"
LAUNCHER_NAME='bm2dx_launcher'
URI='bm2dxinf'

# Misc
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PREFIX_LOCATION="$HOME/.local/share/konaste"
SCRIPT_PATH="${PREFIX_LOCATION}/${SIMPLE_NAME}"
DXVK_LINK="https://github.com/doitsujin/dxvk/releases/download/v2.5.3/dxvk-2.5.3.tar.gz"

# Executables
ICOTOOL="$(command -v icotool)"
PW_LOOPBACK="$(command -v pw-loopback)"
PACTL="$(command -v pactl)"
WGET="$(command -v wget)"
WINE="$(command -v wine)"
WINEPATH="$(command -v winepath)"
WINEBOOT="$(command -v wineboot)"
WINESERVER="$(command -v wineserver)"
WINETRICKS="$(command -v winetricks)"

error() {
	printf '\033[1;38;5;9m-> ERROR:\033[0m %s\033[0m\n' "$@" >&2
}

warning() {
	printf '\033[1;38;5;11m-> WARNING:\033[0m %s\033[0m\n' "$@" >&2
}

is_game_installed() {
	echo "Searching for ${GAME_TITLE} launcher..." >&2
	local k="$(WINEDEBUG='-all' "${WINE}" reg query "HKLM\\SOFTWARE\\KONAMI\\${DIR_TITLE}" /v 'InstallDir' '/reg:64' | awk '/REG_/ {print substr($0, index($0,$3))}')"
	if [[ -n "$k" ]]; then
		path="$("${WINEPATH}" -u "${k}")"
		cd "${path:0:-1}"
		[[ -f launcher/modules/"${LAUNCHER_NAME}".exe ]] && {
			echo "Launcher found!" >&2
			echo "$(${WINEPATH} -w launcher/modules/${LAUNCHER_NAME}.exe)"
			return 0
		}
	fi

	return 1
}

run_game() {
	# Check if the argument contains a launch URI and set that as LOGIN_TOKEN
	# If not, open the launch page in a browser
	if [[ -z "$1" || "$1" != "${URI}"://* ]]; then
		error "No URI provided. Opening launch page for ${GAME_TITLE} in default browser..."
		exec xdg-open "${LAUNCH_PAGE}"
		exit 123
	else
		LOGIN_TOKEN="$1"
	fi

	[[ -z "$LAUNCHER" ]] && LAUNCHER="$(is_game_installed)"

	# Dependency check time~!
	[[ -z "${PW_LOOPBACK}" ]] && error "Missing PipeWire executable: pw-loopback" && exit 1
	[[ -z "${PACTL}" ]] && error "Missing dependency: libpulse" && exit 1

	# Enable the loopback device if needed
	# I may have had help from ChatGPT for this part (damn regular expressions...)
	current_samplerate=$($PACTL info | grep -w 'Default Sample Specification:' | sed 's/.* \([0-9]*\)Hz/\1/')
	if [[ "$current_samplerate" -ne 44100 ]]; then
		warning "Audio sample rate detected at ${current_samplerate}Hz. Enabling loopback device..."
		$PW_LOOPBACK -m '[ FL FR ]' --capture-props='media.class=Audio/Sink node.name=konaste node.description=Konaste audio.rate=44100' &
		[[ $? -eq 0 ]] && echo "Successfully enabled PipeWire loopback device" && export PULSE_SINK=konaste
	fi
	unset current_samplerate

	# Cut down on how much DXVK logs things
	export DXVK_LOG_LEVEL='error'

	# Start the game.
	"${WINE}" start '/high' '/wait' "${LAUNCHER}" "$LOGIN_TOKEN"
	if [[ $? -eq 0 ]]; then
		"${WINESERVER}" -w # Wait for the Wineserver to end
	else
		error "Failed to start ${GAME_TITLE}"
		"${WINESERVER}" -k
		[[ $(jobs | wc -l) -gt 0 ]] && kill -15 $(jobs -p)
		exit 1
	fi

	sleep 1
	# Kill the loopback device if it is in use
	if [[ $(jobs | wc -l) -gt 0 ]]; then
		kill -15 $(jobs -p)
		if [[ $? -eq 0 ]]; then
			echo "Terminated PipeWire loopback device"
		fi
	fi

	[[ "$SIMPLE_NAME" == 'infinitas' ]] && echo -e "\n\033[1;95mThank you for playing...\033[0m\n"
	exit 0
}

main() {
	export WINEPREFIX="${PREFIX_LOCATION}"
	export WINEDLLOVERRIDES="mshtml=d;winemenubuilder.exe=d"

	[[ $EUID -eq 0 ]] && {
		if [[ -n "$SUDO_USER" ]]; then
			error "This script is not meant to be ran with sudo"
			exit 127
		else
			warning "Avoid running this script as root"
		fi
	}

	# Check for Wine executables
	[[ -z "${WINE}" ]] && error "Missing dependency: wine" && exit 1
	[[ -z "${WINEBOOT}" ]] && error "Missing Wine executable: wineboot" && exit 1
	[[ -z "${WINEPATH}" ]] && error "Missing Wine executable: winepath" && exit 1
	[[ -z "${WINESERVER}" ]] && error "Missing Wine executable: wineserver" && exit 1

	# Check the version of Wine
	local v="$($WINE --version | cut -d'-' -f2 | cut -d'.' -f1)"
	if [[ $v -lt 9 ]]; then
		error "Wine 9.0 or later is required for this script"
		exit 2
	fi
	unset v

	# Create the Wineprefix if it doesn't exist
	if [[ ! -d "${PREFIX_LOCATION}" || ! -f "${PREFIX_LOCATION}/system.reg" ]]; then
		mkdir -pv "${PREFIX_LOCATION}"
		$WINEBOOT -i 2>/dev/null
	fi

	cd "${WINEPREFIX}"
	LAUNCHER="$(is_game_installed)"
	if [[ -n "$LAUNCHER" ]]; then
		# Launch the game (or open its launch page in a browser)
		echo "Starting ${GAME_TITLE}..."
		run_game "$@"
	else
		# Install the game
		echo "Unable to find ${GAME_TITLE} launcher. Starting installation process..."
		#sleep 10

		# Check for needed dependencies before continuing
		[[ -z "${WGET}" ]] && error "Missing dependency: wget" && exit 1
		[[ -z "${ICOTOOL}" ]] && error "Missing dependency: icoutils" && exit 2

		# Install cjkfonts if winetricks is present on the user's system
		if [[ -x "${WINETRICKS}" ]]; then
			echo "Winetricks found; installing cjkfonts..."
			"${WINETRICKS}" cjkfonts
		fi

		# Disable ieframe.dll
		export WINEDLLOVERRIDES="${WINEDLLOVERRIDES};ieframe=d"

		# Download the installer
		echo "Downloading installer for ${GAME_TITLE}..."
		"$WGET" -t 3 -O "${WINEPREFIX}/drive_c/$(basename -- $INSTALLER_LINK)" "$INSTALLER_LINK"
		if [[ $? -ne 0 ]]; then
			error "Failed to download installer for ${GAME_TITLE}!"
			exit 3
		fi

		# Run the installer
		echo "Running installer for ${GAME_TITLE}..."
		"${WINE}" msiexec '/i' "C:\\\\$(basename -- $INSTALLER_LINK)" '/L*' "C:\\\\${SIMPLE_NAME}_install.log"
		case $? in
			0)  ;;
			1)  error "The ${GAME_TITLE} installer was terminated unexpectedly" && exit 4 ;;
			66) error "The ${GAME_TITLE} installer was cancelled by the user" && exit 5 ;;
			67) error "${GAME_TITLE} failed to install. Check the log at \033[1;4m${WINEPREFIX}/drive/c/${SIMPLE_NAME}_install.log\033[22;24m to find out what happened" && exit 6 ;;
			*)  error "An unknown error occurred while installing ${GAME_TITLE}. Check the log at \033[1;4m${WINEPREFIX}/drive/c/${SIMPLE_NAME}_install.log\033[22;24m to find out what happened" && exit 7 ;;
		esac

		# Install DXVK
		echo "Downloading DXVK..."
		"${WGET}" -t 3 -O "${WINEPREFIX}/drive_c/$(basename -- $DXVK_LINK)" "$DXVK_LINK"
		if [[ $? -ne 0 ]]; then
			error "Failed to download DXVK archive. The ${GAME_TITLE} installer will continue without it..."
		else
			echo "Extracting DXVK archive..."
			tar -C "${WINEPREFIX}/drive_c" -xf "${WINEPREFIX}"/drive_c/dxvk-*.tar.gz

			# Backup the built-in DirectX .dll files
			# There's probably a simpler way of doing this, but my ideas will more than likely not work out at all
			echo "Backing up built-in DirectX .dll files..."
			cd "${WINEPREFIX}/drive_c/windows/system32"
			if [[ -f {d3d8,d3d9,d3d10core,d3d11,dxgi}.dll.old ]]; then
				rm {d3d8,d3d9,d3d10core,d3d11,dxgi}.dll
			else
				mv d3d8.dll d3d8.dll.old
				mv d3d9.dll d3d9.dll.old
				mv d3d10core.dll d3d10core.dll.old
				mv d3d11.dll d3d11.dll.old
				mv dxgi.dll dxgi.dll.old
			fi
			mv ../../dxvk-*/x64/*.dll .

			cd "${WINEPREFIX}/drive_c/windows/syswow64"
			if [[ -f {d3d8,d3d9,d3d10core,d3d11,dxgi}.dll.old ]]; then
				rm {d3d8,d3d9,d3d10core,d3d11,dxgi}.dll
			else
				mv d3d8.dll d3d8.dll.old
				mv d3d9.dll d3d9.dll.old
				mv d3d10core.dll d3d10core.dll.old
				mv d3d11.dll d3d11.dll.old
				mv dxgi.dll dxgi.dll.old
			fi
			mv ../../dxvk-*/x32/*.dll .

			# Set registry keys for DirectX
			echo "Setting .dll overrides for DXVK..."
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d8' /t 'REG_SZ' /d 'native' /f '/reg:64' 2>/dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d8' /t 'REG_SZ' /d 'native' /f 2>/dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d9' /t 'REG_SZ' /d 'native' /f '/reg:64' 2>/dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d9' /t 'REG_SZ' /d 'native' /f 2>/dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d10core' /t 'REG_SZ' /d 'native' /f '/reg:64' 2>/dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d10core' /t 'REG_SZ' /d 'native' /f 2>/dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d11' /t 'REG_SZ' /d 'native' /f '/reg:64' 2>/dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d11' /t 'REG_SZ' /d 'native' /f 2>/dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'dxgi' /t 'REG_SZ' /d 'native' /f '/reg:64' 2>/dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'dxgi' /t 'REG_SZ' /d 'native' /f 2>/dev/null

			unset DXVK_LINK
		fi

		# Set extra registry keys
		"${WINE}" reg add 'HKCU\SOFTWARE\Wine\X11 Driver' /v 'UseXRandR' /t 'REG_SZ' /d 'Y' /f '/reg:64' 2>/dev/null				# automatically adjusts your resolution and refresh rate if on Xorg (X11)
		"${WINE}" reg add 'HKLM\SOFTWARE\Microsoft\DirectDraw' /v 'ForceRefreshRate' /t 'REG_DWORD' /d 120 /f '/reg:64' 2>/dev/null	# (hopefully) forces IIDX INFINITAS to run at 120fps

		# Create the icons for the game
		[[ -x "$ICOTOOL" ]] && {
			echo "Creating icons for ${GAME_TITLE}..."
			iconDir="$HOME/.local/share/icons/hicolor"
			icon="$(find ${WINEPREFIX}/drive_c/Games -type f -name "${DIR_TITLE}.ico")"
			numIcons=$($ICOTOOL -l "${icon}" | wc -l)

			for i in $(seq 1 $numIcons); do
				# Get the size of the icons
				size="$($ICOTOOL -i $i -l "${icon}" | cut -d' ' -f 3 | cut -d'=' -f 2)"

				# Create the directory if necessary
				[[ ! -e "${iconDir}/${size}x${size}/apps" ]] && mkdir -pv "${iconDir}/${size}x${size}/apps" 2>/dev/null
				[[ ! -e "${iconDir}/${size}x${size}/mimetypes" ]] && mkdir -pv "${iconDir}/${size}x${size}/mimetypes" 2>/dev/null

				# Now extract the icon
				"${ICOTOOL}" -i $i -x "${icon}" -o "${iconDir}/${size}x${size}/apps/${SIMPLE_NAME}.png"
				"${ICOTOOL}" -i $i -x "${icon}" -o "${iconDir}/${size}x${size}/mimetypes/x-scheme-handler-${URI}.png"
			done

			unset iconDir icon numIcons size i
		}

		# Create the mimetype and .desktop entries for the game
		echo "Creating mimetype for ${GAME_TITLE}..."
		mkdir -pv "$HOME/.local/share/applications" 2>/dev/null
cat > "$HOME/.local/share/mime/packages/x-scheme-handler-${URI}.xml"<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
    <mime-type type="x-scheme-handler/${URI}">
        <comment>${GAME_TITLE} Launcher</comment>
        <icon name="x-scheme-handler-${URI}"/>
        <glob-deleteall/>
        <glob pattern="${URI}://*"/>
    </mime-type>
</mime-info>
EOF

	echo "Creating desktop entries for ${GAME_TITLE}..."
	mkdir -pv "$HOME/.local/share/applications" 2>/dev/null
cat > "$HOME/.local/share/applications/${SIMPLE_NAME}.desktop" <<EOF
[Desktop Entry]
Name=${GAME_TITLE}
Type=Application
Categories=Game;
# may need to change this for bonga
GenericName=Rhythm Game
Icon=$SIMPLE_NAME
Exec=xdg-open $LAUNCH_PAGE
EOF

cat > "$HOME/.local/share/applications/${SIMPLE_NAME}-launcher.desktop" <<EOF
[Desktop Entry]
Name=${GAME_TITLE} Launcher
Type=Application
Icon=$SIMPLE_NAME
Exec=${SCRIPT_PATH} %u
MimeType=x-scheme-handler/$URI
NoDisplay=true
EOF
	fi

	echo "Updating desktop and mime databases..."
	[[ -x $(command -v update-desktop-database) ]] && update-desktop-database "$HOME/.local/share/applications"
	[[ -x $(command -v update-mime-database) ]] && update-mime-database "$HOME/.local/share/mime"

	# Copy this script to the Wineprefix
	cp "${SCRIPT_DIR}/$(basename -- $0)" "${WINEPREFIX}/${SIMPLE_NAME}"
	chmod +x "${WINEPREFIX}/${SIMPLE_NAME}"

	# Why not also symlink the launcher desktop entry to the desktop? :3
	ln -s "$HOME/.local/share/applications/${SIMPLE_NAME}.desktop" "$HOME/Desktop/"

	echo -e "\033[1;38;5;10mInstallation is complete!\033[0m"
	[[ "${SIMPLE_NAME}" == 'infinitas' ]] && warning "Be sure to set your audio mode to \033[1mWASAPI Shared Mode\033[22m, otherwise you will have \033[1;3;4;38;5;1mNO\033[22;23;24;39m sound!"
	if [[ $# -eq 0 || "$1" != "${URI}"://* ]]; then
		echo -e "Look for \033[1;38;5;14m${GAME_TITLE}\033[0m within your DE/WM to start playing!"
		exit 0
	else
		echo "Executing ${GAME_TITLE} launcher..."
		run_game "$1"
	fi
}

main "$@"
