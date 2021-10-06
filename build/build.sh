#!/bin/bash

set -o errexit
set -o errtrace
set -o pipefail

ICECATCOMMIT="857afe0e546d0fb9bca6e2d2f79f0cbd44e6a5a3"
FFVERSION="78.15.0"

CLVERSION="RELEASE_8_0_0"

usage() {
    echo "Usage: build.sh COMMAND"
    echo "Commands:"
    echo "  download       Downloads and creates the extras archive"
    echo "  reproduce      Extracts extras archive and verifies files"
    echo "  build_deb      Builds the .deb package with debuild (for local builds)"
    echo "  build_source   Builds the source files (for use with external build service)"
    echo "  patch          Creates patch file in debian/patches directory"
}

download() {
    wget "https://git.savannah.gnu.org/cgit/gnuzilla.git/snapshot/gnuzilla-${ICECATCOMMIT}.tar.gz"
    mv gnuzilla-${ICECATCOMMIT}.tar.gz icecat_${FFVERSION}.orig.tar.gz

    mkdir -p output
    cd output

    wget "https://ftp.mozilla.org/pub/firefox/releases/${FFVERSION}esr/source/firefox-${FFVERSION}esr.source.tar.xz"
    wget "https://ftp.mozilla.org/pub/firefox/releases/${FFVERSION}esr/source/firefox-${FFVERSION}esr.source.tar.xz.asc"
    wget "https://ftp.mozilla.org/pub/firefox/releases/${FFVERSION}esr/KEY"

    tar xf "firefox-${FFVERSION}esr.source.tar.xz" --checkpoint=.1000

    while read line; do
        line=$(echo $line | cut -d ' ' -f1)
        [ $line = "en-US" ] && continue
        wget --content-disposition "https://hg.mozilla.org/l10n-central/$line/archive/tip.zip"
    done < "firefox-$FFVERSION/browser/locales/shipped-locales"

    rm -r firefox-$FFVERSION

    wget --content-disposition "https://hg.mozilla.org/l10n/compare-locales/archive/$CLVERSION.zip"

    cd ..
    tar caf "icecat_$FFVERSION.orig-output.tar.xz" --checkpoint=.1000 output/*

    rm -rf output
}

#reproduce() {
    # find extras/ -mindepth 1 -name "*.zip" -exec echo {} \;
    # TODO: Use filenames to redownload archives to verify.
#}

build_deb() {
    rm *.build *.buildinfo *.changes *.deb *.dsc *.debian.tar.xz || true
    rm -r icecat-${FFVERSION} || true
    
    tar xf icecat_${FFVERSION}.orig.tar.gz --checkpoint=.1000
    mv gnuzilla-${ICECATCOMMIT} icecat-${FFVERSION}
    
    mkdir icecat-${FFVERSION}/output
    tar -C icecat-${FFVERSION}/output --strip-components=1 \
        -xf icecat_${FFVERSION}.orig-output.tar.xz --checkpoint=.1000
    
    cp -r ../debian icecat-${FFVERSION}
    cd icecat-${FFVERSION}

    if [[ "$1" == false ]]; then
        dpkg-source -b .
    else
        debuild -us -uc
    fi
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
    build_deb
elif [[ "$1" == "build_source" ]]; then
    build_deb false
elif [[ "$1" == "download" ]]; then
    download
elif [[ "$1" == "reproduce" ]]; then
    reproduce
else
    usage
fi
