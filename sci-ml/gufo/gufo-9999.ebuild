# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# This ebuild was generated in part by Claude Code

EAPI=8

# Upstream builds with ROCm 10.1 but documents runs on 7.2.x too, and
# nothing in the build asks for a newer one. 6.4 might work as well (the
# first version in ::gentoo offering gfx1151 kernels), but it's untested.
ROCM_VERSION="7.2"

inherit cmake git-r3

DESCRIPTION="LLM inference engine for AMD Strix Halo (gfx1151)"
HOMEPAGE="
	https://gufo.blog
	https://github.com/gufo-org/gufo
"
EGIT_REPO_URI="https://github.com/gufo-org/gufo.git"

LICENSE="MIT Apache-2.0 BSD"
SLOT="0"

ROCM_DEPS="
	>=dev-util/hip-${ROCM_VERSION}:=[video_cards_amdgpu]
	>=sci-libs/hipBLAS-${ROCM_VERSION}:=[amdgpu_targets_gfx1151]
	>=sci-libs/hipBLASLt-${ROCM_VERSION}:=[amdgpu_targets_gfx1151]
	>=sci-libs/rocBLAS-${ROCM_VERSION}:=[amdgpu_targets_gfx1151]
"
RDEPEND="
	${ROCM_DEPS}
	dev-libs/icu:=
	dev-libs/openssl:=
	media-libs/libjpeg-turbo:=
	media-libs/libpng:=
	media-libs/libsndfile
	media-libs/libwebp:=
	media-libs/soxr
	media-video/ffmpeg:=
	net-misc/curl
"
DEPEND="
	${RDEPEND}
	>=sci-libs/hipCUB-${ROCM_VERSION}
	>=sci-libs/rocPRIM-${ROCM_VERSION}
	>=sci-libs/rocWMMA-${ROCM_VERSION}
"
BDEPEND="
	>=dev-util/hip-${ROCM_VERSION}[video_cards_amdgpu]
	virtual/pkgconfig
"

# The test suite needs the GPU.
RESTRICT="test"

PATCHES=(
	"${FILESDIR}"/${PN}-9999-qwen-kernels-link-qwen-hip.patch
)

src_prepare() {
	# Upstream picks up ccache on its own if it is installed; leave that to
	# FEATURES=ccache instead.
	sed -i '/^include(cmake\/CompilerCache\.cmake)$/d' CMakeLists.txt || die
	grep -q 'CompilerCache' CMakeLists.txt && die "failed to drop CompilerCache"

	cmake_src_prepare
}

src_configure() {
	local hipclangpath
	hipclangpath=$(hipconfig --hipclangpath) || die "hipconfig --hipclangpath failed"

	# Like upstream: host C++ goes through the normal toolchain, only HIP
	# sources through ROCm's clang.
	local mycmakeargs=(
		-DBUILD_TESTING=OFF
		-DGUFO_BUILD_TOOLS=OFF
		-DENGINE_ENABLE_HIP=ON
		-DCMAKE_HIP_ARCHITECTURES=gfx1151
		-DCMAKE_HIP_COMPILER="${hipclangpath}/clang++"
		-DGUFO_EXTENSIONS_FROM_LOCK=ON
		-DGUFO_RELEASE_VERSION="$(<version.txt)-live"
		-DGUFO_REVISION="${EGIT_VERSION}"
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install
	rm -r "${ED}/usr/share/licenses" || die # Remove unwanted license files
}

pkg_postinst() {
	elog "Your user needs access to /dev/kfd and /dev/dri/renderD* (usually"
	elog "the 'render' and 'video' groups) to use the GPU."
}
