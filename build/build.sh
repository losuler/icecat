#!/bin/bash

set -o errexit
set -o errtrace
set -o pipefail

ICECATCOMMIT="4c39c619daf344f36962d958d809f6d42d3fce4e"
FFVERSION="91.10.0"
CLVERSION="RELEASE_8_1_0"

MOZ_FTP="ftp.mozilla.org/pub/firefox/releases"
MOZ_SOURCE="${MOZ_FTP}/${FFVERSION}esr/source"

MOZ_HG="hg.mozilla.org"
GNU_GIT="git.savannah.gnu.org/cgit/gnuzilla.git/snapshot"

usage() {
    echo "Usage: build.sh COMMAND"
    echo "Commands:"
    echo "  download        Downloads and creates the extras archive"
    echo "  create_service  Create/re-create .service for OBS"
    echo "  create_includes Create/re-create include-binaries"
    echo "  reproduce       Extracts extras archive and verifies files"
    echo "  build_deb       Builds the .deb package with debuild (for local builds)"
    echo "  build_source    Builds the source files (for use with external build service)"
    echo "  patch           Creates patch file in debian/patches directory"
}

download() {
    wget "https://${GNU_GIT}/gnuzilla-${ICECATCOMMIT}.tar.gz"
    mv gnuzilla-${ICECATCOMMIT}.tar.gz icecat_${FFVERSION}.orig.tar.gz

    mkdir -p output
    cd output

    wget "https://${MOZ_FTP}/${FFVERSION}esr/source/firefox-${FFVERSION}esr.source.tar.xz"
    wget "https://${MOZ_FTP}/${FFVERSION}esr/source/firefox-${FFVERSION}esr.source.tar.xz.asc"
    wget "https://${MOZ_FTP}/${FFVERSION}esr/KEY"

    tar xf "firefox-${FFVERSION}esr.source.tar.xz" --checkpoint=.1000

    while read line; do
        line=$(echo $line | cut -d ' ' -f1)
        [ $line = "en-US" ] && continue
        wget --content-disposition "https://${MOZ_HG}/l10n-central/$line/archive/tip.zip"
    done < "firefox-$FFVERSION/browser/locales/shipped-locales"

    rm -r firefox-$FFVERSION

    wget --content-disposition "https://${MOZ_HG}/l10n/compare-locales/archive/$CLVERSION.zip"

    cd ..
    tar caf "icecat_$FFVERSION.orig-output.tar.xz" --checkpoint=.1000 output/*

    rm -rf output
}

create_service() {
    rm -f _service

    osc add "https://${GNU_GIT}/gnuzilla-${ICECATCOMMIT}.tar.gz" || true
    osc add "https://${MOZ_SOURCE}/firefox-${FFVERSION}esr.source.tar.xz" || true
    osc add "https://${MOZ_SOURCE}/firefox-${FFVERSION}esr.source.tar.xz.asc" || true
    osc add "https://${MOZ_FTP}/${FFVERSION}esr/KEY" || true
    osc add "https://${MOZ_HG}/l10n/compare-locales/archive/${CLVERSION}.zip" || true

    wget "https://${MOZ_FTP}/${FFVERSION}esr/source/firefox-${FFVERSION}esr.source.tar.xz"
    tar xf "firefox-${FFVERSION}esr.source.tar.xz" --checkpoint=.1000

    while read line; do
        line=$(echo $line | cut -d ' ' -f1)
        [ $line = "en-US" ] && continue
        osc add "https://${MOZ_HG}/l10n-central/$line/archive/tip.zip" || true
    done < "firefox-$FFVERSION/browser/locales/shipped-locales"

    while read line; do
        if [[ $line == $(echo $line | grep l10n-central) ]]; then
            lang=$(echo $line | awk -F '/' '{print $3}')
            sed -i -e "s|$line|$line\n    <param name=\"filename\">$lang.zip</param>|" _service
        fi
    done < "_service"

    rm -r firefox-$FFVERSION*
}

create_includes() {
    PATH="output/icecat-${FFVERSION}"
    echo "${PATH}/firefox-${FFVERSION}esr.source.tar.xz" > ../debian/source/include-binaries
    echo "${PATH}/firefox-${FFVERSION}esr.source.tar.xz.asc" >> ../debian/source/include-binaries
    echo "${PATH}/KEY" >> ../debian/source/include-binaries
}

#reproduce() {
    # find extras/ -mindepth 1 -name "*.zip" -exec echo {} \;
    # TODO: Use filenames to redownload archives to verify.
#}

build_deb() {
    rm *.build *.buildinfo *.changes *.deb *.dsc *.debian.tar.xz || true
    rm -r icecat-${FFVERSION} || true

    if [ ! -e "icecat_${FFVERSION}.orig.tar.gz" ]; then
        wget "https://${GNU_GIT}/gnuzilla-${ICECATCOMMIT}.tar.gz"
        mv gnuzilla-${ICECATCOMMIT}.tar.gz icecat_${FFVERSION}.orig.tar.gz

        mkdir icecat-${FFVERSION}
        cp -r ../debian icecat-${FFVERSION}/
        cd icecat-${FFVERSION}
        dpkg-source -b .

        exit 0
    fi

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
elif [[ "$1" == "create_service" ]]; then
    create_service
elif [[ "$1" == "create_includes" ]]; then
    create_includes
elif [[ "$1" == "reproduce" ]]; then
    reproduce
else
    usage
fi
