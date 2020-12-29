#!/bin/bash

set -o errexit
set -o errtrace
set -o pipefail

ICECATCOMMIT="a43514623e93d4f3fe6d61f5b2f82c5ef29bf518"
FFVERSION="78.6.0"
CLVERSION="RELEASE_8_0_0"

download() {
	wget "https://git.savannah.gnu.org/cgit/gnuzilla.git/snapshot/gnuzilla-${ICECATCOMMIT}.tar.gz"
	mv gnuzilla-${ICECATCOMMIT}.tar.gz icecat_${FFVERSION}.orig.tar.gz

	mkdir -p extras
	cd extras

	wget "https://ftp.mozilla.org/pub/firefox/releases/${FFVERSION}esr/source/firefox-${FFVERSION}esr.source.tar.xz"
	wget "https://ftp.mozilla.org/pub/firefox/releases/${FFVERSION}esr/source/firefox-${FFVERSION}esr.source.tar.xz.asc"
	wget "https://ftp.mozilla.org/pub/firefox/releases/${FFVERSION}esr/KEY"

	tar xf "firefox-${FFVERSION}esr.source.tar.xz"

	while read line; do
		line=$(echo $line | cut -d ' ' -f1)
		[ $line = "en-US" ] && continue
		wget --content-disposition "https://hg.mozilla.org/l10n-central/$line/archive/tip.zip"
	done < "firefox-$FFVERSION/browser/locales/shipped-locales"

	rm -r firefox-$FFVERSION

	wget --content-disposition "https://hg.mozilla.org/l10n/compare-locales/archive/$CLVERSION.zip"

	cd ..
	tar caf "icecat_$FFVERSION.orig-extras.tar.xz" extras/*

	rm -rf extras
}

reproduce() {
	find extras/ -mindepth 1 -name "*.zip" -exec echo {} \;
	
	# TODO: Use filenames to redownload archives to verify.
}

if [[ "$1" == "download" ]]; then
	download
elif [[ "$1" == "reproduce" ]]; then
	reproduce
else
	echo "Input required"
fi
