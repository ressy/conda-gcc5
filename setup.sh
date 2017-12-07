#!/usr/bin/env bash
set -Ee

envname=${1:-gcc5}
NJOBS=8
GCC_VER="5.5.0"
URL="https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.gz"

function setup {
	# Setup Anaconda environment
	conda env list | grep ^"$envname " || \
		conda env create --file environment.yml --name "$envname" | tee conda_env_create.log
	source activate "$envname"
	mkdir -p "$CONDA_PREFIX/etc/conda/activate.d"
	mkdir -p "$CONDA_PREFIX/etc/conda/deactivate.d"
	cp gcc_env_activate.sh "$CONDA_PREFIX/etc/conda/activate.d"
	cp gcc_env_deactivate.sh "$CONDA_PREFIX/etc/conda/deactivate.d"
	source gcc_env_activate.sh

	# Setup GCC
	tarball=$(basename "$URL")
	dst=${tarball%%.tar.gz}
	if [ ! -e "$dst" ]; then
		wget "$URL"
		tar xzvf "$tarball"
	fi
	pushd "$dst"
	# We'll set the install prefix to the Anaconda environment root
	./configure --disable-multilib --prefix="$CONDA_PREFIX" | tee ../configure.log
	make -j $NJOBS | tee ../make.log
	make install | tee ../make_install.log
	popd
}

function catch {
	echo ""
	echo "Error during setup"
	exit 1
}

function post_setup {
echo
echo "To use:"
echo "$ source activate $envname"
echo "$ gcc --help"
}

trap catch ERR
setup
post_setup
