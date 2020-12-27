#!/bin/bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

FFVERSION="78.6.0"

build_deb() {
    rm *.build *.buildinfo *.changes *.deb *.dsc *.debian.tar.xz || true
    
    tar xf icecat_${FFVERSION}.orig.tar.gz
    find . -mindepth 1 -name "gnuzilla-*" -prune -type d -exec mv {} icecat-${FFVERSION} \;
    
    mkdir icecat-${FFVERSION}/extras
    tar -C icecat-${FFVERSION}/extras --strip-components=1 -xf icecat_${FFVERSION}.orig-extras.tar.xz
    
    cp -r debian icecat-${FFVERSION}
    cd icecat-${FFVERSION}
    
    debuild -us -uc
}

build_source() {
    build_deb()
    
    if [[ $(basename "$PWD") != "icecat-${FFVERSION}" ]]; then
        cd icecat-${FFVERSION}
    fi
    
    dpkg-source -b .
}

#patch() {
    # TODO: Complete this function
	# See https://www.debian.org/doc/manuals/maint-guide/modify.en.html
	# alias dquilt="quilt --quiltrc=${HOME}/.quiltrc-dpkg"
	# complete -F _quilt_completion -o filenames dquilt
	# dquilt new test-patch.patch
	# dquilt add makeicecat
    # patch -p1 < ../debian/patches/offline-sources.patch
	# dquilt refresh
	# dquilt header -e
#}

if [[ "$1" == "build_deb" ]]; then
    build_deb()
elif [[ "$1" == "build_source" ]]; then
    build_source()
else
    echo "Input required"
fi
