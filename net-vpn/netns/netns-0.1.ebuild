# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=9

# Short one-line description of this package.
DESCRIPTION="Scripts and symlinks to run commands in different network namcespaces"

# Homepage, not used by Portage directly but handy for developer reference
#HOMEPAGE="https://foo.example.org/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE="tor"

RDEPEND="
	net-analyzer/macchanger
	net-dns/dnscrypt-proxy
	net-vpn/openvpn
	tor? ( net-vpn/tor )
"

S="${WORKDIR}" # Nothing to unpack

src_configure() {
	main_user="$(getent passwd 1000 | cut -d: -f1)" || die
	default
}

src_compile() {
	:
}

# The following src_install function is implemented as default by portage, so
# you only need to call it, if you need different behaviour.
src_install() {
	exeinto "/usr/libexec"
	doexe "${FILESDIR}/exec-in-netns"
	doexe "${FILESDIR}/netns"

	local namespaces=( vpn )
	use tor && namespaces+=( tor )
	for ns in "${namespaces[@]}"; do
		dosym -r "${EPREFIX}/usr/libexec/netns" "${EPREFIX}/usr/bin/netns-${ns}"
		insinto "/etc/netns/${ns}/"
		newins "${FILESDIR}/etc-netns-resolv.conf" "resolv.conf"
	done

	insinto "/etc/sudoers.d"
	doins "${FILESDIR}/99_netns"
	sed -i -e "s/MAINUSER/${main_user}/g" "${D}/etc/sudoers.d/99_netns" || die
}
