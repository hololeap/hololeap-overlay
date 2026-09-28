# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_P="berry--yarnpkg-cli-${PV}"

DESCRIPTION="Fast, reliable, and secure node dependency management"
HOMEPAGE="https://yarnpkg.com"
SRC_URI="https://github.com/yarnpkg/berry/archive/refs/tags/@yarnpkg/cli/${PV}.tar.gz
	-> ${P}.tar.gz"

S="${WORKDIR}/${MY_P}"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc64 ~x86"

RDEPEND="net-libs/nodejs"
DEPEND="${RDEPEND}"

RESTRICT="strip"

src_prepare() {
	default
	sed -i 's/"installationMethod": "tar"/"installationMethod": "portage"/g' "${S}/package.json" || die
}

src_install() {
	local install_dir="/usr/$(get_libdir)/node_modules/yarn" path shebang
	insinto "${install_dir}"
	doins -r .
	dosym "../$(get_libdir)/node_modules/yarn/scripts/bin/yarn" "/usr/bin/yarn"
	dosym "../$(get_libdir)/node_modules/yarn/scripts/bin/yarnpkg" "/usr/bin/yarnpkg"

	for e in "${ED}/usr/lib64/node_modules/yarn/scripts/bin/*"; do
		fperms +x "${e}"
	done
}
