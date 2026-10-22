# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# This ebuild was generated in part by Claude Code

EAPI=8

CHROMIUM_LANGS="af am ar bg bn ca cs da de el en-GB es es-419 et fa fi fil fr gu he
	hi hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr
	sv sw ta te th tr uk ur vi zh-CN zh-TW"

inherit chromium-2 desktop linux-info optfeature pax-utils unpacker xdg

DESCRIPTION="Desktop application for Claude.ai, including Claude Code"
HOMEPAGE="https://claude.ai/download"
BASE_URI="https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/${PN}"
SRC_URI="
	amd64? ( ${BASE_URI}/${PN}_${PV}_amd64.deb )
	arm64? ( ${BASE_URI}/${PN}_${PV}_arm64.deb )
"
S="${WORKDIR}"

# The application itself is proprietary; Electron is MIT, and the bundled
# Chromium carries its own set (see LICENSES.chromium.html).
LICENSE="all-rights-reserved BSD MIT Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="cowork gnome"
RESTRICT="bindist mirror strip"

# Libraries taken from the NEEDED entries of the bundled ELF objects,
# plus dlopen()ed/runtime-only helpers.
RDEPEND="
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	app-misc/ca-certificates
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	media-video/pipewire
	net-print/cups
	sys-apps/dbus
	sys-libs/libcap-ng
	sys-libs/libseccomp
	virtual/libudev
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon
	x11-libs/libXrandr
	x11-libs/pango
	x11-misc/xdg-utils
	cowork? (
		app-emulation/qemu
		arm64? ( sys-firmware/edk2-bin )
	)
	gnome? ( dev-libs/gjs )
"

DIR="/opt/${PN}"
QA_PREBUILT="${DIR#/}/*"

pkg_pretend() {
	chromium_suid_sandbox_check_kernel_config

	if use cowork && [[ ${MERGE_TYPE} != buildonly ]]; then
		CONFIG_CHECK="~VHOST_VSOCK"
		WARNING_VHOST_VSOCK="CONFIG_VHOST_VSOCK is required for Cowork to talk to its virtual machine"
		check_extra_config
	fi
}

src_prepare() {
	default

	pushd usr/lib/${PN}/locales >/dev/null || die
	chromium_remove_language_paks
	popd >/dev/null || die
}

src_install() {
	local app=usr/lib/${PN}

	pax-mark m "${app}/${PN}"

	# Everything under usr/lib/claude-desktop is the Electron bundle; move it
	# to /opt as is customary for prebuilt blobs. Use cp rather than doins so
	# the executable bits of the many bundled helpers are preserved.
	mkdir -p "${ED}${DIR}" || die
	cp -r "${app}"/. "${ED}${DIR}" || die
	fperms 4711 "${DIR}/chrome-sandbox"

	dosym -r "${DIR}/${PN}" /usr/bin/${PN}

	domenu usr/share/applications/com.anthropic.Claude.desktop

	# .mcpb/.dxt (desktop extensions) and .skill; upstream's postinst copies
	# this into place.
	insinto /usr/share/mime/packages
	doins "${app}"/resources/linux-mime/com.anthropic.Claude.xml

	local size
	for size in 16 32 48 128 256; do
		doicon -s ${size} usr/share/icons/hicolor/${size}x${size}/apps/${PN}.png
	done

	if use gnome; then
		local sp="${app}/resources/gnome-search-provider"

		insinto /usr/share/gnome-shell/search-providers
		doins "${sp}"/com.anthropic.Claude.search-provider.ini

		# Upstream hardcodes the Debian install location.
		sed -e "s|/usr/lib/${PN}|${EPREFIX}${DIR}|" \
			"${sp}"/com.anthropic.Claude.SearchProvider.service \
			> "${T}"/com.anthropic.Claude.SearchProvider.service || die
		insinto /usr/share/dbus-1/services
		doins "${T}"/com.anthropic.Claude.SearchProvider.service
	fi
}

pkg_postinst() {
	xdg_pkg_postinst

	optfeature "desktop notifications" x11-libs/libnotify
	optfeature "tray icon support" dev-libs/libayatana-appindicator
	optfeature "keyring support" virtual/secret-service
	optfeature "Claude Code sandboxing" "sys-apps/bubblewrap net-misc/socat"
	optfeature "SSH connections" virtual/openssh
}
