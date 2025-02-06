# Maintainer: Mizzt <mizztgc@gmail.com>
pkgname=konaste-linux
pkgver=0.1
pkgrel=1
epoch=
pkgdesc="Unofficial script for playing KONAMI Amusement Game Station (Konaste) games on Linux, using Wine"
arch=('x86_64')
url="https://github.com/mizztgc/konaste-linux"
license=('GPL')
groups=()
depends=( 'bash' 'wine>=9.0' 'wine-mono>=9.3.0' 'noto-fonts-cjk'
		  'pipewire' 'pipewire-pulse' 'pipewire-audio'
		  'libpulse' 'wget' 'xdg-utils' 'hicolor-icon-theme' )
makedepends=()
checkdepends=()
optdepends=(
	"gamemode: run with better performance"
	"gamescope: run games through a gamescope compositor"
	)
provides=()
conflicts=()
replaces=()
backup=()
options=()
install="$pkgname.install"
changelog=
source=("konastelinux-v${pkgver}.tar.gz")
noextract=()
sha256sums=('39f30f178505b84e440500bbee287937c81efef7591bfa79666ecfc7457754bf')
validpgpkeys=()

prepare() {
	tar -xf "konastelinux-v${pkgver}.tar.gz"
}

package() {
	# MimeTypes
	echo 'Installing mimetypes...'
	for u in "$srcdir"/uri/*; do
		install -Dm644 "$u" "$pkgdir/usr/share/mime/packages/$(basename -- $u)"
	done

	# Icons
	echo 'Installing icons...'
	for i in "$srcdir"/icon/*; do
		for a in "$i"/apps/*; do
			install -Dm644 "$a" "$pkgdir/usr/share/icons/hicolor/$(basename -- $i)/apps/$(basename -- $a)"
		done

		for m in "$i"/mimetypes/*; do
			install -Dm644 "$m" "$pkgdir/usr/share/icons/hicolor/$(basename -- $i)/mimetypes/$(basename -- $m)"
		done
	done

	# Launchers
	echo 'Installing desktop entries...'
	for l in "$srcdir"/apps/*; do
		install -Dm644 "$l" "$pkgdir/usr/share/applications/$(basename -- $l)"
	done

	# And finish with the launcher
	echo 'Installing script...'
	install -Dm755 "$srcdir"/konaste "$pkgdir/usr/bin/konaste"
}
