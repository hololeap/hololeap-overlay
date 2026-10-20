# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# This ebuild was generated in part by Claude Code

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
BDEPEND="${RDEPEND}"

RESTRICT="strip"

PATCHES=(
	"${FILESDIR}"/${PN}-4.18.0-disable-telemetry.patch
)

src_compile() {
	# Build the CLI bundle from source. All build dependencies are vendored in
	# .yarn/cache and the bundler is esbuild-wasm, so this works offline.
	# Upstream's committed packages/yarnpkg-cli/bin/yarn.js is a reproducible
	# build of the same sources.
	local -x YARN_ENABLE_TELEMETRY=0
	node scripts/run-yarn.js build:cli || die
}

src_install() {
	local install_dir="/usr/$(get_libdir)/node_modules/yarn"

	exeinto "${install_dir}"/bin
	doexe packages/yarnpkg-cli/bundles/yarn.js

	dosym -r "${install_dir}"/bin/yarn.js /usr/bin/yarn
	dosym -r "${install_dir}"/bin/yarn.js /usr/bin/yarnpkg
}
