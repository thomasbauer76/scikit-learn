#!/bin/bash

set -e
set -x

UNAMESTR=`uname`
N_CORES=`nproc --all`

# defines the get_dep and show_installed_libraries functions
source build_tools/shared.sh

setup_ccache() {
    echo "Setting up ccache"
    mkdir /tmp/ccache/
    which ccache
    for name in gcc g++ cc c++ x86_64-linux-gnu-gcc x86_64-linux-gnu-c++; do
      ln -s $(which ccache) "/tmp/ccache/${name}"
    done
    export PATH="/tmp/ccache:${PATH}"
    # Unset ccache limits
    ccache -F 0
    ccache -M 0
}

setup_ccache

python --version

# Disable the build isolation and build in the tree so that the same folder can be
# cached between CI runs.
pip install --verbose --no-build-isolation .

# Report cache usage
ccache -s --verbose

micromamba list

# Changing directory not to have module resolution use scikit-learn source
# directory but to the installed package.
cd /tmp
python -c "import sklearn; sklearn.show_versions()"
python -m threadpoolctl --import sklearn
# Test using as many workers as available cores
pytest --pyargs -n $N_CORES sklearn
