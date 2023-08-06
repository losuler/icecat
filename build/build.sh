#!/bin/bash

set -o errexit
set -o errtrace
set -o pipefail

ICECATCOMMIT="ac19d793c76732f9e5623e25fbf31287255a4ae7"
FFVERSION="102.14.0"
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
    echo "  update_package  Updates version strings and add changelog entry."
}

check_depends() {
    if ! command -v "$1" &> /dev/null
    then
        echo "The command \"$1\" could not be found."
        exit
    fi
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

    while read -r line; do
        line=$(echo "$line" | cut -d ' ' -f1)
        [ "$line" = "en-US" ] && continue
        wget --output-document "$line".zip "https://${MOZ_HG}/l10n-central/$line/archive/tip.zip"
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

    while read -r line; do
        line=$(echo "$line" | cut -d ' ' -f1)
        [ "$line" = "en-US" ] && continue
        osc add "https://${MOZ_HG}/l10n-central/$line/archive/tip.zip" || true
    done < "firefox-$FFVERSION/browser/locales/shipped-locales"

    while read -r line; do
        if [[ "$line" == $(echo "$line" | grep l10n-central) ]]; then
            lang=$(echo "$line" | awk -F '/' '{print $3}')
            sed -i -e "s|$line|$line\n    <param name=\"filename\">$lang.zip</param>|" _service
        fi
    done < "_service"

    rm -r firefox-$FFVERSION*
}

create_includes() {
    SRC_PATH="output/icecat-${FFVERSION}"
    echo "${SRC_PATH}/firefox-${FFVERSION}esr.source.tar.xz" > ../debian/source/include-binaries
    echo "${SRC_PATH}/firefox-${FFVERSION}esr.source.tar.xz.asc" >> ../debian/source/include-binaries
    echo "${SRC_PATH}/KEY" >> ../debian/source/include-binaries
}

build_deb() {
    rm ./*.build ./*.buildinfo ./*.changes ./*.deb ./*.dsc ./*.debian.tar.xz || true
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

update_package() {
    git clone https://git.savannah.gnu.org/git/gnuzilla.git
    cd gnuzilla

    LATEST_ICECATCOMMIT=$(git log -n 1 --pretty=format:"%H")

    if [[ "$LATEST_ICECATCOMMIT" != "$ICECATCOMMIT" ]]; then
        sed -i "0,/ICECATCOMMIT=.*/{s/ICECATCOMMIT=.*/ICECATCOMMIT=\"$LATEST_ICECATCOMMIT\"/}" ../build.sh
        echo "Updated ICECATCOMMIT in build.sh"
    else
        echo "No new commits."
        exit 1
    fi

    FFMAJOR=$(grep -oP "FFMAJOR=\K\w+" makeicecat)
    FFMINOR=$(grep -oP "FFMINOR=\K\w+" makeicecat)
    FFSUB=$(grep -oP "FFSUB=\K\w+" makeicecat)

    LATEST_FFVERSION="$FFMAJOR.$FFMINOR.$FFSUB"

    if [[ "$LATEST_FFVERSION" != "$FFVERSION" ]]; then
        sed -i "0,/FFVERSION=.*/{s/FFVERSION=.*/FFVERSION=\"$LATEST_FFVERSION\"/}" ../build.sh
        echo "Updated FFVERSION in build.sh"
        sed -i "0,/FFVERSION = .*/{s/FFVERSION = .*/FFVERSION = $LATEST_FFVERSION/}" ../../debian/rules
        echo "Updated FFVERSION in ../debian/rules"
    else
        echo "Did not update FFVERSION."
    fi

    LATEST_CLVERSION=$(grep -oP "L10N_CMP_REV=\K\w+" makeicecat)

    cd ..
    rm -rf gnuzilla

    if [[ "$LATEST_CLVERSION" != "$CLVERSION" ]]; then
        sed -i "0,/CLVERSION=.*/{s/CLVERSION=.*/CLVERSION=\"$LATEST_CLVERSION\"/}" build.sh
        echo "Updated CLVERSION aka L10N_CMP_REV in build.sh"
        sed -i "0,/CLVERSION = .*/{s/CLVERSION = .*/CLVERSION = $LATEST_CLVERSION/}" ../debian/rules
        echo "Updated CLVERSION aka L10N_CMP_REV in ../debian/rules"
    else
        echo "Did not update CLVERSION."
    fi

    CHANGELOG_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S %z")

    cat >> changelog-head<< EOF
icecat ($LATEST_FFVERSION-1) unstable; urgency=medium

  * debian/rules: Update to $LATEST_FFVERSION.

 -- losuler <losuler@posteo.net>  $CHANGELOG_DATE

EOF

    cp ../debian/changelog changelog-tail
    cat changelog-head changelog-tail > ../debian/changelog
    rm changelog-head changelog-tail

    echo "Added changelog entry to ../debian/changelog"

    INCLUDES=$(grep -oPm 1 '(?<=output/icecat-)\K.*(?=\/)' ../debian/source/include-binaries)

    if [[ "$LATEST_FFVERSION" != "$INCLUDES" ]]; then
        create_includes
        echo "Updated ../debian/source/include-binaries"
    else
        echo "Did not update ../debian/source/include-binaries"
    fi
}

if [[ "$1" == "build_deb" ]]; then
    check_depends dpkg-source
    check_depends debuild
    check_depends tar
    check_depends wget
    build_deb
elif [[ "$1" == "build_source" ]]; then
    check_depends dpkg-source
    check_depends debuild
    check_depends tar
    check_depends wget
    build_deb false
elif [[ "$1" == "download" ]]; then
    check_depends tar
    check_depends wget
    download
elif [[ "$1" == "create_service" ]]; then
    check_depends tar
    check_depends wget
    check_depends osc
    create_service
elif [[ "$1" == "create_includes" ]]; then
    create_includes
elif [[ "$1" == "update_package" ]]; then
    update_package
else
    usage
fi
