#!/usr/bin/env bash

# Konaste Linux (formerly Infinitas for Linux) by Mizzt

# This is just a barebones script for installing and launching KONAMI Amusement Game Station (Konaste) games and
# doesn't include special features. It doesn't provide many workarounds that may be necessary for each game to
# function without any issues, other than an audio fix for the BEMANI games and DXVK.

# And while I have you here, I would like to inform you that this script is unofficial. It's not endorsed,
# supported, nor affiliated with KONAMI Amusement. This script will NOT grant you access to the full game
# without an active basic course subscription to each game, if necessary, nor will I allow you to do so (I
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
# - icoutils OR imagemagick

# WARNING: I HAVE NOT TESTED ANY GAMES OTHER THAN IIDX INFINITAS, SDVX, AND BOMBERGIRL
# YOUR MILEAGE MAY VARY DEPENDING ON YOUR HARDWARE AND DISTRO OF CHOICE

WINE="$(command -v wine)"
WINEBOOT="$(command -v wineboot)"
WINEPATH="$(command -v winepath)"
WINESERVER="$(command -v wineserver)"
WINETRICKS="$(command -v winetricks)"
PW_LOOPBACK="$(command -v pw-loopback)"
PACTL="$(command -v pactl)"
WGET="$(command -v wget)"
MSIEXTRACT="$(command -v msiextract)"
ICOTOOL="$(command -v icotool)"
MAGICK="$(command -v magick)"
MAGICK_ALT="$(command -v convert)"
GAMEMODE="$(command -v gamemoderun)"
GAMESCOPE="$(command -v gamescope)"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

error() {
	printf '\033[1;38;5;9m-> ERROR:\033[0m %s\033[0m\n' "$@" >&2
}

warning() {
	printf '\033[1;38;5;11m-> WARNING:\033[0m %s\033[0m\n' "$@" >&2
}

info() {
	printf '\033[1m-> %s\033[0m\n' "$@" >&2
}

ok() {
	printf '\033[1;38;5;10m-> %s\033[0m\n' "$@" >&2
}

show_help() {
read -rd '' help <<EOF
Usage: $(basename -- $0) <game ID|command> <command> ...

\033[1mCommands: \033[0m
  init:          Initialize the Wineprefix at ~/.local/share/konaste
  install:       Install a game
  list:          List installed games
  help:          Show this message

\033[1mInstall/Initialization Flags:\033[0m
  --silent:      Perform a silent install of a game (requires msitools)
  --no-dxvk:     Do not install DXVK to the Wineprefix (not recommended)

\033[1mPost-install Commands:\033[0m
  * fix-icons:   Regenerate the icons for a game
  * fix-launcher Fix the desktop and mime entries for a game
  open-page:     Opens the launch page for a game in your browser
  update-script: Replace the 'konaste' script in the prefix with this version

  * Not yet implemented

\033[1mList of usable game IDs:\033[0m
  iidx:          \033[1mbeatmania IIDX \033[38;5;81mINFINITAS\033[0m
  sdvx:          \033[1mSOUND VOLTEX \033[38;5;123mEXCEED\033[0m \033[38;5;199mGEAR\033[0m \033[1;38;5;196mコナステ\033[0m
  ddr:           \033[1mDanceDanceRevolution \033[38;5;212mGRAND PRIX\033[0m
  gitadora:      \033[1;38;5;214mGI\033[38;5;226mTA\033[38;5;118mDO\033[38;5;39mRA\033[0m \033[1;38;5;196mコナステ\033[0m
  nostalgia:     \033[1;38;5;141mノスタルジア\033[0m
  popn:          \033[1;38;5;226mpop'n music\033[0m \033[1;38;5;27mL\033[38;5;208mi\033[38;5;82mv\033[38;5;214me\033[38;5;177ml\033[38;5;198my\033[0m
  bombergirl:    \033[1;38;5;220mボンバーガール\033[0m

---------------------------------------------------------------------------------------------------

\033[1mLAUNCHING A GAME:\033[0m

To start a game's launcher, a login token is passed to this script as an argument. This token is
generated from the game's respective launch page.

For beatmania IIDX INFINITAS, the login token will look similar to this:
bm2dxinf://login?tk=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX&trial=
bm2dxinf://login?tk=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX&rel=

For all other Konaste games, the login token will look similar to this:
konaste.<game>://XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX

EOF

echo -e "${help}\n"
exit
}

####################################################################################################
####################################################################################################
####################################################################################################

parse_flags() {
	if [[ $# -gt 0 ]]; then
		while [[ $# -gt 0 ]]; do
			case "$1" in
				help) show_help ;;
				iidx|sdvx|ddr|gitadora|nostalgia|popn|bombergirl) [[ -z "$toPlay" ]] && toPlay="$1" ;;
				bm2dxinf://*|konaste.*://*)
					if [[ -n "$toPlay" ]]; then
						if [[ -n "$(grep -Eo $(get_game_information uri) <(echo $1))" ]]; then
							declare -gr cmd='start' 2>/dev/null
							launchUri="$1"
						else
							error "$(get_title) cannot be launched with a $(echo $1 | sed 's/:\/\/.*//') URI"
							exit 2
						fi
					else
						# Guess what the URI is for
						if [[ -z "$cmd" ]]; then
							case "$1" in
								bm2dxinf://*) [[ -z "$toPlay" ]] && toPlay='iidx' ;;
								konaste.sdvx://*) [[ -z "$toPlay" ]] && toPlay='sdvx' ;;
								konaste.ddr://*) [[ -z "$toPlay" ]] && toPlay='ddr' ;;
								konaste.gitadora://*) [[ -z "$toPlay" ]] && toPlay='gitadora' ;;
								konaste.nostalgia://*) [[ -z "$toPlay" ]] && toPlay='nostalgia' ;;
								konaste.popn-music://*) [[ -z "$toPlay" ]] && toPlay='popn' ;;
								konaste.bomber-girl://*) [[ -z "$toPlay" ]] && toPlay='bombergirl' ;;
								konaste.*://*)
									error "Invalid Konaste URI specified: $1"
									exit 2
									;;
								*)
									error "Unknown URI specified: $1"
									exit 2
									;;
							esac

							#info "Detected Login URI for $(get_title)"
							launchUri="$1"
							declare -gr cmd='start' 2>/dev/null
						elif [[ "$cmd" != 'start' ]]; then
							error "Please specify the game you would like to specifically work with instead of its URI."
							exit 1
						fi
					fi
					;;
				init) declare -gr cmd='init' 2>/dev/null ;;
				install)
					if [[ -z "${toPlay}" ]]; then
						error "A game ID must be specified before 'install'"
						exit 1
					else
						declare -gr cmd='install' 2>/dev/null
					fi
					;;
				list|list-games) declare -gr cmd='list' 2>/dev/null ;;
				fix-icons) declare -gr cmd='icon' 2>/dev/null ;;
				fix-launcher) declare -gr cmd='launcher' 2>/dev/null ;;
				open-page|open-webpage) declare -gr cmd='launch' 2>/dev/null ;;
				update|update-script) declare -gr cmd='update' 2>/dev/null ;;
				# Flags
				--silent) declare -gr silentInstall=1 2>/dev/null ;;
				--no-dxvk) declare -gr noDXVK=1 2>/dev/null ;;
				--gamescope) declare -gr useGamescope=1 2>/dev/null ;; # TODO: Configuration file?
				*)
					case "${LANG}" in
						ja*) UNKNOWN_CMD="不明なコマンドまたはゲーム識別子： $1" ;;
						*)   UNKNOWN_CMD="Unknown command or game identifier: $1" ;;
					esac
					error "${UNKNOWN_CMD}"
					exit 1
					;;
			esac
			shift
		done
	else
		error "No command provided"
		echo -e "Run \033[1m$(basename -- $0) help\033[0m for a list of usable commands"
		exit 1
	fi
}

####################################################################################################
####################################################################################################
####################################################################################################

function get_launcher_for_game() {
	[[ -z "$toPlay" ]] && return 1
	local k="$(WINEDEBUG='-all' "${WINE}" reg query "HKLM\\SOFTWARE\\KONAMI\\$(get_game_information dirtitle)" /v 'InstallDir' '/reg:64' | awk '/REG_/ {print substr($0, index($0,$3))}')"
	if [[ -n "$k" ]]; then
		path="$("${WINEPATH}" -u "${k}")"
		cd "${path:0:-1}" 2>/dev/null
		[[ -f launcher/modules/"$(get_game_information launcher)".exe ]] && {
			echo "$(${WINEPATH} -w launcher/modules/$(get_game_information launcher).exe)"
			return 0
		}
	fi

	return 1
}

function get_title() {
	# This function is to get a proper localized title for the game
	[[ -z "$toPlay" ]] && return 1
	if [[ "${LANG}" != ja* ]]; then
		if [[ -n "$(get_game_information entitle)" ]]; then
			echo "$(get_game_information entitle)"
		else
			echo "$(get_game_information title)"
		fi
	else
		echo "$(get_game_information title)"
	fi
}

function get_game_information() {
	if [[ -z "$2" ]]; then
		if [[ -n "$toPlay" ]]; then
			obtain="$toPlay"
		else
			return 1
		fi
	else
		obtain="$2"
	fi

	case "$obtain" in
		iidx)
			GAME_TITLE='beatmania IIDX INFINITAS'
			DIR_TITLE="${GAME_TITLE}"
			SIMPLE_NAME="infinitas"
			INSTALLER_LINK="https://d1rc4pwxnc0pe0.cloudfront.net/v2/installer/infinitas_installer_2022060800.msi"
			LAUNCH_PAGE="https://p.eagate.573.jp/game/infinitas/2/api/login/login.html"
			LAUNCHER_NAME='bm2dx_launcher'
			URI='bm2dxinf'
			;;
		sdvx)
			GAME_TITLE='SOUND VOLTEX EXCEED GEAR コナステ'
			EN_TITLE='SOUND VOLTEX EXCEED GEAR'
			DIR_TITLE='SOUND VOLTEX EXCEED GEAR'
			SIMPLE_NAME="sdvx-exceedgear"
			INSTALLER_LINK="https://dks1q2aivwkd6.cloudfront.net/vi/installer/sdvx_installer_2022011800.msi"
			LAUNCH_PAGE="https://p.eagate.573.jp/game/konasteapp/API/login/login.html?game_id=sdvx"
			LAUNCHER_NAME='launcher'
			URI='konaste.sdvx'
			;;
		ddr)
			GAME_TITLE='DanceDanceRevolution GRAND PRIX'
			DIR_TITLE='DanceDanceRevolution'
			SIMPLE_NAME="ddr-gp"
			INSTALLER_LINK="https://d2el0dli9l0x2p.cloudfront.net/installer/ddr_installer_2022012601.msi"
			LAUNCH_PAGE="http://p.eagate.573.jp/game/konasteapp/API/login/login.html?game_id=ddr"
			LAUNCHER_NAME='launcher'
			URI='konaste.ddr'
			;;
		gitadora)
			GAME_TITLE='GITADORA コナステ'
			EN_TITLE='GITADORA'
			DIR_TITLE='GITADORA'
			SIMPLE_NAME="gitadora"
			INSTALLER_LINK="https://d1omkh45tn6edw.cloudfront.net/inst/GITADORA_installer.msi"
			LAUNCH_PAGE="http://p.eagate.573.jp/game/konasteapp/API/login/login.html?game_id=gitadora"
			LAUNCHER_NAME='launcher'
			URI='konaste.gitadora'
			;;
		nostalgia)
			GAME_TITLE='ノスタルジア'
			EN_TITLE='NOSTALGIA'
			DIR_TITLE='NOSTALGIA'
			SIMPLE_NAME="nostalgia"
			INSTALLER_LINK="https://d26kzmeiv4899f.cloudfront.net/installer/NOSTALGIA_installer.msi"
			LAUNCH_PAGE="http://p.eagate.573.jp/game/konasteapp/API/login/login.html?game_id=NOSTALGIA"
			LAUNCHER_NAME='launcher'
			URI='konaste.nostalgia'
			;;
		popn)
			GAME_TITLE="pop'n music Lively"
			DIR_TITLE="${GAME_TITLE}"
			SIMPLE_NAME="popn"
			INSTALLER_LINK="https://d1twxdn5j8sbm3.cloudfront.net/installer/popn_installer_2021021801.msi"
			LAUNCH_PAGE="https://p.eagate.573.jp/game/konasteapp/API/login/login.html?game_id=popn-music"
			LAUNCHER_NAME='launcher'
			URI='konaste.popn-music'
			;;
		bombergirl)
			GAME_TITLE='ボンバーガール'
			EN_TITLE='BOMBERGIRL'
			DIR_TITLE='BomberGirl'
			SIMPLE_NAME="bombergirl"
			INSTALLER_LINK="https://d1q1iflay6y5jj.cloudfront.net/Installer/2021122200_b37bc853/BomberGirl_Installer.msi"
			LAUNCH_PAGE="https://p.eagate.573.jp/game/konasteapp/API/login/login.html?game_id=bomber-girl"
			LAUNCHER_NAME='launcher'
			URI='konaste.bomber-girl'
			;;
		*)
			#error "Invalid game specified: $1" >&2
			return 1
			;;
	esac

	# Determine what we need
	case "$1" in
		title)		echo -n "${GAME_TITLE}" ;;
		entitle)	echo -n "${EN_TITLE}" ;;
		dirtitle)	echo -n "${DIR_TITLE}" ;;
		simple) 	echo -n "${SIMPLE_NAME}" ;;
		installer)	echo -n "${INSTALLER_LINK}" ;;
		webpage)	echo -n "${LAUNCH_PAGE}" ;;
		launcher)	echo -n "${LAUNCHER_NAME}" ;;
		uri)		echo -n "${URI}" ;;
		*) ;;
	esac

	unset GAME_TITLE EN_TITLE DIR_TITLE SIMPLE_NAME INSTALLER_LINK LAUNCH_PAGE LAUNCHER_NAME obtain
	return 0
}

####################################################################################################
####################################################################################################
####################################################################################################

list_games() {
	get() {
		toPlay="$1"
		echo -n "$(get_title) "
		if [[ -n "$(get_launcher_for_game)" ]]; then
			echo -en '\033[38;5;10m✓\033[0m\n' >&2
		else
			echo -en '\033[38;5;9m🗙\033[0m\n' >&2
		fi
	}

	echo "List of available games:" >&2
	get 'iidx'
	get 'sdvx'
	get 'ddr'
	get 'gitadora'
	get 'popn'
	get 'nostalgia'
	get 'bombergirl'
	exit 0
}

prepare_wineprefix() {
	# Create the Wineprefix if it does not exist
	if [[ ! -e "${WINEPREFIX}" && ! -f "${WINEPREFIX}/system.reg" ]]; then
		info "Wineprefix at ${WINEPREFIX} was not found. Creating one now..." >&2
		mkdir -p "${WINEPREFIX}"
		"${WINEBOOT}" -i 2>/dev/null
	else
		warning "Existing Wineprefix detected. Starting initialization process..."
		"${WINEBOOT}" -u 2>/dev/null
	fi

	DXVK_LINK="https://github.com/doitsujin/dxvk/releases/download/v2.5.3/dxvk-2.5.3.tar.gz"
	VCR2010_LINK="https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe"

	# Add the fonts so Japanese/Chinese characters render properly
	if [[ -d '/usr/share/fonts/noto-cjk' ]]; then
		# If the Noto CJK font family is present on the system, use it
		if [[ ! -f "${WINEPREFIX}/drive_c/windows/Fonts/sourcehansans.ttc" ]]; then
			info 'Found Noto Sans CJK in system' >&2
			info 'Setting registry entries to use for CJK fonts...' >&2
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'MS Gothic' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'MS PGothic' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'MS UI Gothic' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'MS Mincho' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'MS PMincho' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'Meiryo' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'Meiryo UI' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'メイリオ' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'ＭＳ ゴシック' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'ＭＳ Ｐゴシック' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'Microsoft JhengHei' /t 'REG_SZ' /d 'Noto Sans CJK TC' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'Microsoft JhengHei UI' /t 'REG_SZ' /d 'Noto Sans CJK TC' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'Microsoft YaHei' /t 'REG_SZ' /d 'Noto Sans CJK SC' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'Microsoft YaHei UI' /t 'REG_SZ' /d 'Noto Sans CJK SC' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'MingLiU' /t 'REG_SZ' /d 'Noto Sans CJK TC' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'MingLiU-ExtB' /t 'REG_SZ' /d 'Noto Sans CJK TC' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'ＭＳ 明朝' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'ＭＳ Ｐゴシック' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'ＭＳ Ｐ明朝' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'Yu Gothic' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'Yu Gothic UI' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Fonts\Replacements' /v 'Yu Mincho' /t 'REG_SZ' /d 'Noto Sans CJK JP' /f > /dev/null
		fi
	elif [[ ! -f "${WINEPREFIX}/drive_c/windows/Fonts/sourcehansans.ttc" && -x "${WINETRICKS}" ]]; then
		# If Source Han Sans isn't present within the prefix, install it
		info 'Using Winetricks to install CJK fonts...' >&2
		"${WINETRICKS}" cjkfonts
	fi

	cd "${WINEPREFIX}/drive_c"

	info 'Downloading Microsoft Visual C++ Redist 2010...' >&2
	"${WGET}" -qt 3 -O "${WINEPREFIX}/drive_c/$(basename -- $VCR2010_LINK)" "$VCR2010_LINK"
	if [[ $? -ne 0 ]]; then
		error "Failed to install Microsoft Visual C++ Redist 2010!"
		exit 3
	else
		info 'Installing Microsoft Visual C++ Redist 2010...' >&2
		"${WINE}" 'C:\vcredist_x64.exe' '/quiet' 2>/dev/null
		if [[ $? -ne 0 ]]; then
			error "Failed to install Microsoft Visual C++ Redist 2010!"
			exit 4
		fi

		rm "$(basename -- $VCR2010_LINK)"
	fi

	if [[ -z "$noDXVK" && "$noDXVK" -ne 1 ]]; then
		info 'Downloading DXVK...' >&2
		"${WGET}" -qt 3 -O "${WINEPREFIX}/drive_c/$(basename -- $DXVK_LINK)" "$DXVK_LINK"
		if [[ $? -ne 0 ]]; then
			error "Failed to install DXVK. The setup process will continue without it..."
		else
			info "Extracting DXVK archive..." >&2
			tar -xf dxvk-*.tar.gz

			info "Moving DXVK files to Windows directory..." >&2
			mv -b dxvk-*/x32/*.dll windows/syswow64/
			mv -b dxvk-*/x64/*.dll windows/system32/

			info "Setting DLL overrides for DXVK..." >&2
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d8' /t 'REG_SZ' /d 'native' /f '/reg:64' > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d8' /t 'REG_SZ' /d 'native' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d9' /t 'REG_SZ' /d 'native' /f '/reg:64' > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d9' /t 'REG_SZ' /d 'native' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d10core' /t 'REG_SZ' /d 'native' /f '/reg:64' > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d10core' /t 'REG_SZ' /d 'native' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d11' /t 'REG_SZ' /d 'native' /f '/reg:64' > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'd3d11' /t 'REG_SZ' /d 'native' /f > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'dxgi' /t 'REG_SZ' /d 'native' /f '/reg:64' > /dev/null
			"${WINE}" reg add 'HKCU\SOFTWARE\Wine\DllOverrides' /v 'dxgi' /t 'REG_SZ' /d 'native' /f > /dev/null

			# Clean up remaining files
			rm -rf dxvk-*
		fi
	fi

	info "Creating additional registry keys..." >&2
	"${WINE}" reg add 'HKCU\SOFTWARE\Wine\X11 Driver' /v 'UseXRandR' /t 'REG_SZ' /d 'Y' /f '/reg:64' > /dev/null
	"${WINE}" reg add 'HKLM\SOFTWARE\Microsoft\DirectDraw' /v 'ForceRefreshRate' /t 'REG_DWORD' /d 120 /f '/reg:64' > /dev/null
	"${WINE}" reg add 'HKCU\SOFTWARE\Wine\FileOpenAssociations' /v 'Enable' /d 'N' /f > /dev/null
	"${WINE}" reg add 'HKCU\SOFTWARE\Wine\Explorer\Desktops' /v 'Konaste' /d '1920x1080' /f > /dev/null

	# Copy this script to the prefix and make it executable
	cd "${SCRIPT_DIR}"
	cp "$0" "${WINEPREFIX}/konaste"
	chmod a+x "${WINEPREFIX}/konaste"

	case "${LANG}" in
		ja*) PREFIX_INIT="Wineprefixは初期化され、コナステで使用できるようになりました" ;;
		*)   PREFIX_INIT="Wineprefix has been initialized and is ready to use for Konaste" ;;
	esac
	ok "${PREFIX_INIT}" >&2
}

launch_game() {
	info "Launching $(get_title)..."

	# Cut down on DXVK messages in your terminal
	export DXVK_LOG_LEVEL='error'

	declare -a launchParams=( )
	if [[ -x "${GAMEMODE}" ]]; then
		info "Using gamemoderun"
		launchParams+=( "${GAMEMODE}" )
	else
		warning "Unable to locate binary for gamemoderun. While not required, it is recommended to have to maximize performance"
	fi

	if [[ "$useGamescope" -eq 1 ]]; then
		if [[ -x "${GAMESCOPE}" ]]; then
			info "Using gamescope"
			launchParams+=( "${GAMESCOPE}" -W 1280 -H 720 -w 1920 -h 1080 )
			case "$toPlay" in
				iidx|sdvx|ddr) launchParams+=( -r 120 --framerate-limit 120 ) ;;
				bombergirl)    launchParams+=( -r 60 --adaptive-sync ) ;; # since bonga is a unity game
				*)             launchParams+=( -r 60 --framerate-limit 60 ) ;;

			esac
			launchParams+=( -b -- )
		else
			warning "--gamescope flag provided, but gamescope was not found on your system. Running normally..."
		fi
	fi

	# The BEMANI games require a loopback device for audio to work.
	# Bomber Girl uses a proper game engine (Unity) and doesn't need such workarounds.
	# Thanks for making things difficult, konmai!
	if [[ "$toPlay" != 'bombergirl' ]]; then
		[[ -z "${PW_LOOPBACK}" ]] && error "Missing PipeWire executable: pw-loopback" && exit 1
		[[ -z "${PACTL}" ]] && error "Missing dependency: libpulse" && exit 1

		# I may have had help from ChatGPT for this part (damn regular expressions...)
		current_samplerate=$($PACTL info | grep -w 'Default Sample Specification:' | sed 's/.* \([0-9]*\)Hz/\1/')
		if [[ "$current_samplerate" -ne 44100 ]]; then
			warning "Audio sample rate detected at ${current_samplerate}Hz. Enabling loopback device..."
			"${PW_LOOPBACK}" -m '[ FL FR ]' --capture-props='media.class=Audio/Sink node.name=konaste node.description=Konaste audio.rate=44100' &
			[[ $? -eq 0 ]] && echo "Successfully enabled PipeWire loopback device" >&2 && export PULSE_SINK=konaste
		else
			echo "Audio sample rate detected at 44100Hz. Not creating loopback device..." >&2
		fi
		unset current_samplerate
	fi

	launchParams+=( "${WINE}" start '/high' '/wait' )
	if [[ "$useGamescope" -eq 1 && -x "${GAMESCOPE}" ]]; then
		launchParams+=( explorer '/desktop=Konaste,1920x1080' )
	fi

	# The time has finally come.
	LANG='ja_JP.UTF-8' "${launchParams[@]}" "${launcher}" "${launchUri}"
	"${WINESERVER}" -w

	if [[ $(jobs | wc -l) -gt 0 ]]; then
		kill -15 $(jobs -p)
		if [[ $? -eq 0 ]]; then
			echo "Terminated PipeWire loopback device"
		fi
	fi

	[[ "$toPlay" == 'iidx' ]] && echo -e "\n\033[1;95mThank you for playing...\033[0m\n"
	exit 0
}

install_game() {
	[[ -z "${WGET}" ]] && error "Missing dependency: wget" && exit 1

	installer="$(get_game_information installer)"
	dir_title="$(get_game_information dirtitle)"
	simplename="$(get_game_information simple)"
	uri="$(get_game_information uri)"

	cd "${WINEPREFIX}/drive_c"

	if [[ ! -f "$(basename -- $installer)" ]]; then
		info "Downloading installer for $(get_title)..." >&2
		"${WGET}" -qt 3 -O "${WINEPREFIX}/drive_c/$(basename -- $installer)" "$installer"
		if [[ $? -ne 0 ]]; then
			error "Failed to download installer for $(get_title)!"
			exit 3
		fi
	fi

	if [[ "$silentInstall" -eq 1 ]]; then
		info "Performing silent install..." >&2
		if [[ -z "${MSIEXTRACT}" ]]; then
			case "${LANG}" in
				ja*) NO_MSITOOLS="$(get_title)のサイレントインストールを実行するにはmsitoolsが必要です。" ;;
				*)   NO_MSITOOLS="msitools is required to perform a silent installation of $(get_title)"
			esac
			error "${NO_MSITOOLS}"
			exit 1
		fi

		info "Extracting files from installer..." >&2
		"${MSIEXTRACT}" "$(basename -- $installer)" > /dev/null
		mkdir -p Games/"$(get_game_information dirtitle)"/Resource # make this folder so the game won't complain

		[[ -d System64 ]] && {
			mv -n System64/* windows/system32
			rm -rf System64
			}
		[[ -d Win ]] && {
			mv -n Win/System64/* windows/system32
			rm -rf Win
		}
		# This is actually important, so we need to install this.
		# It "probably" won't replace the DXVK libraries, otherwise I will cry
		if [[ -d Games/"${dir_title}"/'DirectX 9.0c Redist' ]]; then
			info "Installing bundled DirectX 9.0c Runtime..." >&2
			"${WINE}" ./Games/"${dir_title}"/'DirectX 9.0c Redist'/DXSETUP.exe '/silent'
			if [[ $? -ne 0 ]]; then
				case "${LANG}" in
					ja*) DX_FAIL="バンドルされた DirectX ランタイムのインストールに失敗しました。重大な問題が発生する可能性があります。" ;;
					*)   DX_FAIL="Failed to install bundled DirectX runtime! You may encounter severe issues" ;;
				esac
				error "${DX_FAIL}" >&2
				unset DX_FAIL
			else
				# Nuke it, too.
				rm -rf Games/"${dir_title}"/'DirectX 9.0c Redist' 2>/dev/null
			fi
		fi

		info "Creating registry keys for $(get_title)..." >&2
		"${WINE}" reg add "HKLM\\SOFTWARE\\KONAMI\\${dir_title}" /v 'InstallDir' /t 'REG_SZ' /d "C:\Games\\${dir_title}\\" /f '/reg:64' > /dev/null
		"${WINE}" reg add "HKLM\\SOFTWARE\\KONAMI\\${dir_title}" /v 'ResourceDir' /t 'REG_SZ' /d "C:\Games\\${dir_title}\\Resource\\" /f '/reg:64' > /dev/null
	else
		info "Performing interactive install..." >&2
		export WINEDLLOVERRIDES="${WINEDLLOVERRIDES};ieframe=d"
		LANG='ja_JP.UTF-8' "${WINE}" msiexec '/i' "C:\\\\$(basename -- $installer)" '/L*' "C:\\\\${simplename}_install.log"
		case $? in
			0)  ;;
			1)  error "The $(get_title) installer was terminated unexpectedly" && exit 4 ;;
			66) error "The $(get_title) installer was cancelled by the user" && exit 5 ;;
			67) error "$(get_title) failed to install. Check the log at \033[1;4m${WINEPREFIX}/drive/c/${simplename}_install.log\033[22;24m to find out what happened" && exit 6 ;;
			*)  error "An unknown error occurred while installing $(get_title). Check the log at \033[1;4m${WINEPREFIX}/drive/c/${simplename}_install.log\033[22;24m to find out what happened" && exit 7 ;;
		esac
	fi

	info "Creating icons..." >&2
	icon="$(find ${WINEPREFIX}/drive_c/Games/"${dir_title}" -type f -name '*.ico')"
	iconDir="$HOME/.local/share/icons/hicolor"
	if [[ -x "${ICOTOOL}" ]]; then
		info "Using icoutils to create icons..." >&2
		numIcons=$($ICOTOOL -l "${icon}" | wc -l)

		for i in $(seq 1 $numIcons); do
			# Get the size of the icons
			size="$($ICOTOOL -i $i -l "${icon}" | cut -d' ' -f 3 | cut -d'=' -f 2)"

			# Create the directory if necessary
			[[ ! -e "${iconDir}/${size}x${size}/apps" ]] && mkdir -pv "${iconDir}/${size}x${size}/apps" 2>/dev/null
			[[ ! -e "${iconDir}/${size}x${size}/mimetypes" ]] && mkdir -pv "${iconDir}/${size}x${size}/mimetypes" 2>/dev/null

			# Now extract the icon
			"${ICOTOOL}" -i $i -x "${icon}" -o "${iconDir}/${size}x${size}/apps/${simplename}.png"
			"${ICOTOOL}" -i $i -x "${icon}" -o "${iconDir}/${size}x${size}/mimetypes/x-scheme-handler-${uri}.png"
		done
	else
		warning "icoutils was not found. Attempting to use magick/convert..."
		if [[ -z "${MAGICK}" && -x "${MAGICK_ALT}" ]]; then
			warning "magick binary not found; using convert..."
			MAGICK="${MAGICK_ALT}"
			unset MAGICK_ALT
		fi

		if [[ -n "${MAGICK}" ]]; then
			mkdir tmpIconDir
			cd tmpIconDir

			$MAGICK "$icon" icon.png
			if [[ $? -ne 0 ]]; then
				log "Failed to create icons!" err
			else
				for i in $(seq 0 $(( $(ls -1 | wc -l) - 1)) ); do
					size=$(file icon-${i}.png | grep -Eo "[[:digit:]]+ *x *[[:digit:]]+")
					size="${dimens% x*}"

					[[ ! -e "${iconDir}/${size}x${size}/apps" ]] && mkdir -pv "${iconDir}/${size}x${size}/apps" 2>/dev/null
					[[ ! -e "${iconDir}/${size}x${size}/mimetypes" ]] && mkdir -pv "${iconDir}/${size}x${size}/mimetypes" 2>/dev/null

					mv -f icon-${i}.png "${iconDir}/${size}x${size}/apps/${simplename}.png" 2>/dev/null
					mv -f icon-${i}.png "${iconDir}/${size}x${size}/mimetypes/x-scheme-handler-${uri}.png" 2>/dev/null
				done
				cd ..
				rm -rf tmpIconDir

				[[ $(command -v gtk-update-icon-cache 2>/dev/null) ]] && gtk-update-icon-cache
			fi
		else
			error "No binaries for creating icons were found. $(get_title) will not have any icons"
		fi
	fi

	unset icon iconDir size i numIcons

	mkdir -p "$HOME/.local/share/applications"
	mkdir -p "$HOME/.local/share/mime/packages"
	if [[ -n $(get_game_information entitle) ]]; then
		comment="$(get_game_information entitle)"
	else
		comment="$(get_game_information title)"
	fi

	info 'Creating MimeType entry...' >&2
cat > "$HOME/.local/share/mime/packages/x-scheme-handler-${uri}.xml"<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
    <mime-type type="x-scheme-handler/${uri}">
        <comment>${comment} Launcher</comment>
        <icon name="x-scheme-handler-${uri}"/>
        <glob-deleteall/>
        <glob pattern="${uri}://*"/>
    </mime-type>
</mime-info>
EOF

	unset comment

	info 'Creating .desktop entries...' >&2
	launcherA="$HOME/.local/share/applications/$(get_game_information simple).desktop"
	launcherB="$HOME/.local/share/applications/$(get_game_information simple)-launcher.desktop"

	# Create the .desktop launchers
	echo '[Desktop Entry]' > "$launcherA"
	if [[ -n $(get_game_information entitle) ]]; then
		echo "Name=$(get_game_information entitle)" >> "$launcherA"
		echo "Name[ja]=$(get_game_information title)" >> "$launcherA"
		echo "Name[ko]=$(get_game_information title)" >> "$launcherA"
	else
		echo "Name=$(get_game_information title)" >> "$launcherA"
	fi
	echo 'Type=Application' >> "$launcherA"
	echo 'Categories=Game' >> "$launcherA"
	if [[ "toPlay" == 'bombergirl' ]]; then
		# I "think" bonga is a strategy game. feel free to correct me if i'm wrong
		echo "GenericName=Strategy Game" >> "$launcherA"
		echo "GenericName[ja]=戦略ゲーム" >> "$launcherA"
		echo "GenericName[ko]=전략 게임" >> "$launcherA"
	else
		echo "GenericName=Rhythm Game" >> "$launcherA"
		echo "GenericName[ja]=音ゲー" >> "$launcherA"
		echo "GenericName[ko]=음악 게임" >> "$launcherA"
	fi
	echo "Icon=${simplename}" >> "$launcherA"
	echo "Exec=xdg-open $(get_game_information webpage)" >> "$launcherA"

	echo '[Desktop Entry]' > "$launcherB"
	if [[ -n $(get_game_information entitle) ]]; then
		echo "Name=$(get_game_information entitle) Launcher" >> "$launcherB"
	else
		echo "Name=$(get_game_information title) Launcher" >> "$launcherB"
	fi
	echo "Icon=${simplename}" >> "$launcherB"
	echo "MimeType=x-scheme-handler/${uri}" >> "$launcherB"
	echo 'NoDisplay=true' >> "$launcherB"
	echo "Exec=${WINEPREFIX}/konaste $toPlay %u" >> "$launcherB"

	info "Updating desktop and mime databases..." >&2
	[[ -x $(command -v update-desktop-database) ]] && update-desktop-database "$HOME/.local/share/applications"
	[[ -x $(command -v update-mime-database) ]] && update-mime-database "$HOME/.local/share/mime"

	sleep 2
	if [[ -z "${launchUri}" ]]; then
		echo -e "\033[1;38;5;10m$(get_title) has been successfully installed. Look for the launcher within your DE/WM to start playing!\033[0m"
		exit 0
	else
		unset dir_title simplename installer uri DXVK_LINK ICOTOOL MAGICK MAGICK_ALT WINEBOOT WINETRICKS
		launcher="$(get_launcher_for_game)"
		launch_game
	fi
}








main() {
	export WINEPREFIX="$HOME/.local/share/konaste"
	export WINEDLLOVERRIDES="mshtml=d;winemenubuilder.exe=d"
	parse_flags "$@"

	if [[ ! -e "${WINEPREFIX}" || ! -f "${WINEPREFIX}/system.reg" ]]; then
		if [[ "$cmd" == 'init' ]]; then
			prepare_wineprefix
			exit
		fi

		error "Wineprefix has not been initialized"
		echo -e "Run \033[1m$(basename -- $0) init\033[0m to initialize the prefix"
		exit 1
	fi

	case "$cmd" in
		init) prepare_wineprefix && exit ;;
		update)
			case "${LANG}" in
				ja*)
					UPDATE_START="起動スクリプトを更新しています"
					UPDATE_SUCCESS="起動スクリプトを更新しました"
				;;
				*)
					UPDATE_START="Updating launch script..."
					UPDATE_SUCCESS="Updated launch script"
				;;
			esac
			info "${UPDATE_START}"
			rm "${WINEPREFIX}/konaste"
			cp "$0" "${WINEPREFIX}/konaste"
			chmod a+x "${WINEPREFIX}/konaste"

			ok "${UPDATE_SUCCESS}"
			exit
			;;
		list) list_games ;;
		start|install|icon|entry|launch)
			launcher="$(get_launcher_for_game)"
			case "$cmd" in
				start)
					if [[ -z "$launcher" ]]; then
						case "${LANG}" in
							ja*) NOT_INSTALLED="$(get_title)がインストールされていません" ;;
							*)   NOT_INSTALLED="$(get_title) is not installed" ;;
						esac
						error "${NOT_INSTALLED}"
						exit 2
					fi

					launch_game
					;;
				install)
					if [[ -n "$launcher" ]]; then
						case "${LANG}" in
							ja*) ALREADY_INSTALLED="$(get_title)はすでにインストールされています" ;;
							*)   ALREADY_INSTALLED="$(get_title) is already installed"
						esac
						error "${ALREADY_INSTALLED}"
						exit 2
					fi

					install_game
					;;
				icon) error "Not yet implemented" && exit 2 ;;
				entry) error "Not yet implemented" && exit 2 ;;
				launch) exec xdg-open "$(get_game_information webpage)" ;;
			esac
			;;
		*)
			error "No action provided for $(get_title)"
			exit 1
			;;
	esac
}

main "$@"
