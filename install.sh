#!/bin/sh

copy_files() {
	set -e
	echo -e "\033[1mInstalling files, please wait...\033[0m"
	hicolor_dir="/usr/share/icons/hicolor"
	pkgfldr="$(pwd)/src"
cat > "/usr/share/mime/packages/x-scheme-handler-bm2dxinf.xml" <<EOF
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
	# create uri handler, copy script, and desktop file
	chmod 644 "/usr/share/mime/packages/x-scheme-handler-bm2dxinf.xml"
	install -Dm755 "$pkgfldr/infinitas" "/usr/bin/infinitas"
	install -Dm644 "$pkgfldr/infinitas.desktop" "/usr/share/applications/infinitas.desktop"

	# copy icons
	hicolor_dir="/usr/share/icons/hicolor"
	for dir in $pkgfldr/icons/hicolor/*; do
		bn1=$(basename -- "$dir") # 256x256, 128x128, etc.
		for dir2 in $dir/*; do
			bn2=$(basename -- "$dir2") # apps, mimetypes
			for dir3 in $dir2/*; do
				bn3=$(basename -- "$dir3") # infinity-beat.png, etc.
				install -Dm644 "$pkgfldr/icons/hicolor/$bn1/$bn2/$bn3" "$hicolor_dir/$bn1/$bn2/$bn3"
			done
		done
	done

	# reset everything
	update-desktop-database /usr/share/applications
	update-mime-database /usr/share/mime
	echo -e "\033[1mInstallation complete!\033[0m"
	echo -e "To complete the installation, you must run \033[1minfinitas install\033[0m."
    return 0
}

check_deps() {
	[[ -z $(which kdialog 2>/dev/null) ]] && echo "Missing dependency: kdialog" && exit 2
	[[ -z $(which wine 2>/dev/null) ]] && echo "Missing dependency: wine" && exit 2
	[[ -z $(which msiextract 2>/dev/null) ]] && echo "Missing dependency: msitools" && exit 2
	[[ -z $(which pipewire 2>/dev/null) ]] && echo "Missing dependency: pipewire" && exit 2
	[[ -z $(which tar 2>/dev/null) ]] && echo "Missing dependency: tar" && exit 2
	[[ -z $(which wget 2>/dev/null) ]] && echo "Missing dependency: wget" && exit 2
	[[ -z $(which gamescope 2>/dev/null) ]] && echo "Missing optional dependency: kdialog"
	echo "All required dependencies satisfied."
	return 0
}

check_deps
exec sudo sh -c "$(declare -f copy_files); copy_files"
