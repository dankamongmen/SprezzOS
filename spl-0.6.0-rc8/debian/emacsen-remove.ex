#!/bin/sh -e
# /usr/lib/emacsen-common/packages/remove/spl-modules-3.3.3-1-amd64-di

FLAVOR=$1
PACKAGE=spl-modules-3.3.3-1-amd64-di

if [ ${FLAVOR} != emacs ]; then
    if test -x /usr/sbin/install-info-altdir; then
        echo remove/${PACKAGE}: removing Info links for ${FLAVOR}
        install-info-altdir --quiet --remove --dirname=${FLAVOR} /usr/share/info/spl-modules-3.3.3-1-amd64-di.info.gz
    fi

    echo remove/${PACKAGE}: purging byte-compiled files for ${FLAVOR}
    rm -rf /usr/share/${FLAVOR}/site-lisp/${PACKAGE}
fi
