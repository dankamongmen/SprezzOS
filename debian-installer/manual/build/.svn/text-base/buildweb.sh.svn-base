#!/bin/sh

set -e

[ -r ./po_functions ] || exit 1
. ./po_functions

manual_release=${manual_release:=squeeze}

if [ -z "$languages" ]; then
    # Buildlist of languages to be included on the official website
    # Based on list of languages used in official builds
    languages="$(cd ../debian; ./getfromlist langlist)"
fi

if [ -z "$architectures" ]; then
    # Based on list of architectures used in official builds
    architectures="$(cd ../debian; ./getfromlist archlist)"
fi

if [ -z "$destination" ]; then
    destination="/tmp/manual"
fi

if [ -z "$formats" ]; then
    formats="html pdf txt"
fi

[ -e "$destination" ] || mkdir -p "$destination"

export official_build="1"
export web_build="1"
export manual_target="for_wdo"

# Delete any old generated XML files
clear_xml

# We need to merge the XML files for English and update the POT files
export PO_USEBUILD="1"
update_templates

for lang in $languages; do
    echo "Language: $lang";

    # Update PO files and create XML files
    if [ ! -d ../$lang ] && uses_po; then
        generate_xml
    fi
    
    for arch in $architectures; do
        echo "Architecture: $arch"
        if [ -n "$noarchdir" ]; then
            destsuffix="$lang"
        else
            destsuffix="${arch}"
        fi
        ./buildone.sh "$arch" "$lang" "$formats"
        mkdir -p "$destination/$destsuffix"
        for format in $formats; do
            if [ "$format" = html ]; then
                mv -f ./build.out/html/* "$destination/$destsuffix"
            else
                # Do not fail because of missing PDF support for some languages
                mv -f ./build.out/install.$lang.$format "$destination/$destsuffix/install.$format.$lang" || true
            fi
        done

        ./clear.sh
    done
done

PRESEED="../en/appendix/preseed.xml"
if [ -f $PRESEED ] && [ -f preseed.pl ] ; then
    ./preseed.pl -r $manual_release $PRESEED >$destination/example-preseed.txt
fi

# Delete temporary PO files and generated XML files
clear_po
clear_xml
