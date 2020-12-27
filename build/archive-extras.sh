#!/bin/bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

FFVERSION="78.6.0"
CLVERSION="RELEASE_8_0_0"

download() {
	mkdir -p extras
	cd extras

	wget "https://ftp.mozilla.org/pub/firefox/releases/${FFVERSION}esr/source/firefox-${FFVERSION}esr.source.tar.xz"
	wget "https://ftp.mozilla.org/pub/firefox/releases/${FFVERSION}esr/source/firefox-${FFVERSION}esr.source.tar.xz.asc"
	wget "https://ftp.mozilla.org/pub/firefox/releases/${FFVERSION}esr/KEY"

	while read line; do
		line=$(echo $line | cut -d ' ' -f1)
		[ $line = "en-US" ] && continue
		wget --content-disposition "https://hg.mozilla.org/l10n-central/$line/archive/tip.zip"
	done < "../icecat-$FFVERSION/output/icecat-$FFVERSION/browser/locales/shipped-locales"

	wget --content-disposition "https://hg.mozilla.org/l10n/compare-locales/archive/$CLVERSION.zip"

	cd ..
	tar caf "icecat_$FFVERSION.orig-extras.tar.xz" extras/*
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
