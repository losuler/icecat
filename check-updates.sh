#!/bin/bash

# Uncomment for debugging use
# set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

PREV_RELEASE="115.9.0"

LATEST_RELEASE=$(curl --silent https://git.savannah.gnu.org/cgit/gnuzilla.git/log | \
    grep -oP '(?<=Update to )[0-9.]+' | \
    head -n 1 | \
    cut -d'.' -f1-3)

function print_release {
    if [[ "${LATEST_RELEASE}" != "${PREV_RELEASE}" ]]; then
        if [[ "$1" != "version-only" ]]; then
            echo "There's a new release of GNU IceCat."
            echo "https://git.savannah.gnu.org/cgit/gnuzilla.git/log"
        fi
        echo "${LATEST_RELEASE} > ${PREV_RELEASE}."
    else
        if [[ "$1" != "version-only" ]]; then
            echo "There's no new release of GNU IceCat."
            echo "https://git.savannah.gnu.org/cgit/gnuzilla.git/log"
        fi
        echo "${LATEST_RELEASE} == ${PREV_RELEASE}."
    fi
}

case "$@" in
    --version-only)
        print_release "version-only"
        ;;
    *)
        print_release ""
        ;;
esac
