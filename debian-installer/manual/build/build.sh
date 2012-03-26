#!/bin/sh

set -e

[ -r ./po_functions ] || exit 1
. ./po_functions

manual_release=${manual_release:=squeeze}

if [ -z "$languages" ]; then
    # Buildlist of languages
    # Note: this list is no longer being maintained; see debian/langlist instead
    languages="en de fr ja pt"
fi

if [ -z "$architectures" ]; then
    # Note: this list is no longer being maintained; see debian/archlist instead
    architectures="amd64 armel hppa i386 ia64 mips mipsel powerpc s390 sparc"
fi

if [ -z "$destination" ]; then
    destination="/tmp/manual"
fi

if [ -z "$formats" ]; then
    #formats="html pdf ps txt"
    formats="html pdf txt"
fi

[ -e "$destination" ] || mkdir -p "$destination"

if [ "$official_build" ]; then
    # Propagate this to children.
    export official_build
fi

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
                destsuffix="${lang}.${arch}"
        fi
        ./buildone.sh "$arch" "$lang" "$formats"
        mkdir -p "$destination/$destsuffix"
        for format in $formats; do
            if [ "$format" = html ]; then
                mv ./build.out/html/* "$destination/$destsuffix"
            else
                # Do not fail because of missing PDF support for some languages
                mv ./build.out/install.$lang.$format "$destination/$destsuffix" 2>/dev/null || true
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
