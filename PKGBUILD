# Maintainer: nullstacked
pkgname=kvmd-fullscreen
pkgver=1.0.1
pkgrel=1
pkgdesc="Floating browser-fullscreen button for PiKVM Web UI (so Alt+Tab etc. go to the target)"
arch=('any')
url="https://github.com/nullstacked/kvmd-fullscreen"
license=('GPL3')
depends=('kvmd')
install=kvmd-fullscreen.install

package() {
    install -Dm644 "$srcdir/../files/apply-patches.sh" "$pkgdir/usr/share/kvmd-fullscreen/apply-patches.sh"
    chmod +x "$pkgdir/usr/share/kvmd-fullscreen/apply-patches.sh"
    install -Dm644 "$srcdir/../files/fullscreen.css" "$pkgdir/usr/share/kvmd-fullscreen/fullscreen.css"
    install -Dm644 "$srcdir/../kvmd-fullscreen.hook" "$pkgdir/etc/pacman.d/hooks/kvmd-fullscreen.hook"
}
