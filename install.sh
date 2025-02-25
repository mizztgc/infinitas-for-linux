#!/bin/bash

# change pwd to the directory the script is in
cd "$(dirname -- $(realpath -- $0))"

# Parse flags
[[ $# -gt 0 ]] && while [[ $# -gt 0 ]]; do
	case "$1" in
		-h|--help|help) show_help=1 ;;
		-u|--uninstall) uninstall=1 ;;
		-I|--no-icons) noIcons=1 ;;
		-R|--no-refresh) noRefresh=1 ;;
		-p|--prefix) shift; pfx="$(realpath -- $1)" ;;
		-g|--games)
			shift
			[[ -z "$1" ]] && {
				echo -e "\033[38;5;9merror:\033[0m No games specified"
				echo 'Allowed IDs are: iidx, sdvx, ddr, gitadora, nostalgia, popn, bombergirl'
				exit 1
			}
			declare -a toInstall=( )
			counter=1
			while true; do
				id="$(cut -d',' -f${counter} <(echo "$1"))"
				[[ -z "$id" ]] && break

				case "$id" in
					iidx|beatmania|infinitas) toInstall+=( 'iidx' ) ;;
					sdvx|exceed-gear|sdvx-exceedgear) toInstall+=( 'sdvx' ) ;;
					ddr|ddr-gp|dancedancerevolution) toInstall+=( 'ddr' ) ;;
					gitadora) toInstall+=( 'gitadora' ) ;;
					nostalgia|ノスタルジア) toInstall+=( 'nostalgia' ) ;;
					popn|popn-music) toInstall+=( 'popn' ) ;;
					bombergirl|bomber-girl|bonga|ボンバーガール) toInstall+=( 'bombergirl' ) ;;
					*)
						echo -e "\033[38;5;9merror:\033[0m Unknown game: $id"
						exit 1
						;;
				esac

				if [[ "$1" =~ \, ]]; then
					counter=$(( $counter + 1 ))
				else
					break
				fi
			done

			unset id counter
			;;
		--*|-*|*)
			echo -e "\033[38;5;9merror:\033[0m Unrecognized command/flag: $1"
			exit 1
			;;
	esac
	shift
done

if [[ "$show_help" -eq 1 ]]; then
cat <<EOF
Konaste Linux - install.sh Help:

  -g|--games        Declare what games to install
                    (This installs ALL games if this flag is not provided)
  -h|--help         Show this message
  -I|--no-icons     Do not include icons
  -R|--no-refresh   Do not refresh the .desktop and Mime databases
  -p|--prefix       Installs all files to a certain directory
                    Will default to either:
                    - ~/.local (if ran as local user)
                    - /usr (if ran as root/sudo)

Multiple games can be specified for installation, separated by commas (,).
example: ./install.sh -g 'iidx,sdvx'

EOF
	exit 0
fi

# Check if $pfx is filled
if [[ -z "$pfx" ]]; then
	if [[ $(id -u) -eq 0 ]]; then
		# Install to /usr
		pfx='/usr'
	else
		# Install to /home/<you>/.local
		pfx="$HOME/.local"
	fi
else
	if [[ ! -e "${pfx}" ]]; then
		mkdir -p "${pfx}"
		if [[ $? -ne 0 ]]; then
			echo -e "\033[38;5;9merror:\033[0m Failed to create directories at ${pfx}"
			exit 1
		fi
	else
		if [[ $(id -u) -ne 0 ]]; then
			if [[ ! -r "${pfx}" ]]; then
				echo -e "\033[38;5;9merror:\033[0m You do not have permission to read from ${pfx}"
				exit 1
			elif [[ ! -w "${pfx}" ]]; then
				echo -e "\033[38;5;9merror:\033[0m You do not have permission to write to ${pfx}"
				exit 1
			fi
		fi
	fi
fi

if [[ ! -d icon ]]; then
	echo -e "\033[38;5;11mwarn:\033[0m Local icon directory not found!"
	noIcons=1
fi

# just install every game
if [[ -z "${toInstall}" ]]; then
	declare -a toInstall=( 'iidx' 'sdvx' 'ddr' 'gitadora' 'nostalgia' 'popn' 'bombergirl' )
fi

echo "Setting pfx to ${pfx}"
binDir="${pfx}/bin"
appDir="${pfx}/share/applications"
iconDir="${pfx}/share/icons/hicolor"
mimeDir="${pfx}/share/mime"
manDir="${pfx}/share/man"

mkdir -p "${binDir}"
mkdir -p "${appDir}"
mkdir -p "${iconDir}"
mkdir -p "${mimeDir}"/packages
mkdir -p "${manDir}"/man{1,6}

for g in "${toInstall[@]}"; do
	case "$g" in
		iidx)
			iconAppsName='infinitas.png'
			iconMimeName='x-scheme-handler-bm2dxinf.png'
			mimeName='x-scheme-handler-bm2dxinf.xml'
			desktopName='infinitas.desktop'
			iconSizes=( 16 32 64 128 256 )
			;;
		sdvx)
			iconAppsName='sdvx-exceedgear.png'
			iconMimeName='x-scheme-handler-konaste.sdvx.png'
			mimeName='x-scheme-handler-konaste.sdvx.xml'
			desktopName='sdvx-exceedgear.desktop'
			iconSizes=( 16 32 64 128 256 )
			;;
		ddr)
			iconAppsName='ddr-gp.png'
			iconMimeName='x-scheme-handler-konaste.ddr.png'
			mimeName='x-scheme-handler-konaste.ddr.xml'
			desktopName='ddr-grandprix.desktop'
			iconSizes=( 16 24 32 48 64 128 256 )
			;;
		gitadora)
			iconAppsName='gitadora.png'
			iconMimeName='x-scheme-handler-konaste.gitadora.png'
			mimeName='x-scheme-handler-konaste.gitadora.xml'
			desktopName='gitadora.desktop'
			iconSizes=( 16 24 32 48 64 128 256 )
			;;
		nostalgia)
			iconAppsName='nostalgia.png'
			iconMimeName='x-scheme-handler-konaste.nostalgia.png'
			mimeName='x-scheme-handler-konaste.nostalgia.xml'
			desktopName='nostalgia.desktop'
			iconSizes=( 16 32 64 128 256 )
			;;
		popn)
			iconAppsName='popn-music.png'
			iconMimeName='x-scheme-handler-konaste.popn-music.png'
			mimeName='x-scheme-handler-konaste.popn-music.xml'
			desktopName='popn-music.desktop'
			iconSizes=( 16 32 64 128 256 )
			;;
		bombergirl)
			iconAppsName='bombergirl.png'
			iconMimeName='x-scheme-handler-konaste.bomber-girl.png'
			mimeName='x-scheme-handler-konaste.bomber-girl.xml'
			desktopName='bombergirl.desktop'
			iconSizes=( 16 32 64 128 256 )
			;;
	esac

	echo "Installing ${g}..."
	# Install icons (only available in archive)
	# I'm unsure if I can add the icons to the GitHub repo, so if you just cloned
	# the repository, then the icon directory will not be found.
	[[ "$noIcons" -ne 1 ]] && for i in "${iconSizes[@]}"; do
		install -Dm644 icon/"${i}"x"${i}"/"$iconAppsName" "${iconDir}/${i}x${i}/apps/${iconAppsName}"
		install -Dm644 icon/"${i}"x"${i}"/"$iconAppsName" "${iconDir}/${i}x${i}/mimetypes/${iconMimeName}"
	done
	unset i iconAppsName iconMimeName

	install -Dm644 uri/"${mimeName}" "${mimeDir}/packages/${mimeName}"
	# If running as a local user, change the Exec line in the desktop files to the
	# value of $binDir.
	# If there's a better way of doing this, I'd like to know.
	[[ $(id -u) -ne 0 ]] && sed -i 's:^Exec=konaste:Exec='"${binDir}"'/konaste:' apps/"${desktopName}"
	install -Dm644 apps/"${desktopName}" "${appDir}/${desktopName}"
	unset desktopName mimeName

	# Copy the man pages
	[[ -f man/${g}.6 ]] && install -Dm644 man/${g}.6 "${manDir}/man6/${g}.6"
done

# Install the script and its man page
[[ ! -e "${binDir}/konaste" ]] && install -Dm755 bin/konaste "${binDir}/konaste"
install -Dm644 man/konaste.1 "${manDir}/man1/konaste.1"

if [[ "$noRefresh" -ne 1 ]]; then
	update-desktop-database "${appDir}"
	update-mime-database "${mimeDir}"
	gtk-update-icon-cache
	mandb -u 2>/dev/null
else
	echo -e "\033[38;5;11mwarn:\033[0m Not updating desktop/mime databases"
fi

echo 'Done.'
[[ ! $(command -v konaste) ]] && echo -e "\033[38;5;10mtip:\033[0m Add ${binDir} to your PATH environment variable for easy access to the Konaste script!"
exit 0
