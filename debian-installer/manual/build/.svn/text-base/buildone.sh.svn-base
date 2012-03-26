#!/bin/sh

if [ "$1" = "--help" ]; then
    echo "$0: Generate the Debian Installer Manual in several different formats"
    echo "Usage: $0 [arch] [lang] [format]"
    echo "[format] may consist of multiple formats provided they are quoted (e.g. \"html pdf\")"
    echo "Supported formats: html, ps, pdf, txt"
    exit 0
fi

arch=${1:-i386}
language=${2:-en}
formats=${3:-html}

## Configuration
basedir="$(cd "$(dirname $0)"; pwd)"
manual_path="$(echo $basedir | sed "s:/build$::")"
build_path="$manual_path/build"
cd $build_path

stylesheet_dir="$build_path/stylesheets"
stylesheet_profile="$stylesheet_dir/style-profile.xsl"
if [ ! "$web_build" ]; then
    stylesheet_html="$stylesheet_dir/style-html.xsl"
else
    stylesheet_html="$stylesheet_dir/style-html-web.xsl"
fi
stylesheet_html_single="$stylesheet_dir/style-html-single.xsl"
stylesheet_dsssl="$stylesheet_dir/style-print.dsl"
stylesheet_css="$stylesheet_dir/install.css"

entities_path="$build_path/entities"
source_path="$manual_path/$language"

if [ -z "$destdir" ]; then
    destdir="build.out"
fi

tempdir="build.tmp"
dynamic="${tempdir}/dynamic.ent"

create_profiled () {

    [ -x "`which xsltproc 2>/dev/null`" ] || return 9

    echo "Info: creating temporary profiled .xml file..."

    if [ ! "$official_build" ]; then
        unofficial_build="FIXME;unofficial-build"
    else
        unofficial_build=""
    fi

    if [ -z "$manual_release" ]; then
        manual_release="squeeze"
    fi
    if [ -z "$manual_target" ]; then
        manual_target="for_cd"
    fi

    # Now we source the profiling information for the selected architecture
    [ -f "arch-options/${arch}" ] || {
        echo "Error: unknown architecture '$arch'" >&2
        return 1
    }
    . arch-options/$arch
    os=`dpkg-architecture -a$arch -qDEB_HOST_ARCH_OS 2> /dev/null`
    . arch-options/$os

    # Now we source the profiling information for the current language
    if [ -f "lang-options/${language}" ]; then
	. lang-options/$language
    fi

    # Join all architecture options into one big variable
    condition="$fdisk;$network;$boot;$smp;$frontend;$other;$goodies;$unofficial_build;$status;$manual_release"
    # Add language options
    condition="$condition;$optional_paras"
    # Add build options for the manual
    condition="$condition;$unofficial_build;$status;$manual_release;$manual_target"

    # Write dynamic non-profilable entities into the file
    echo "<!-- arch- and lang-specific non-profilable entities -->" > $dynamic
    echo "<!ENTITY langext \".${language}\">" >> $dynamic
    echo "<!ENTITY architecture \"${arch}\">" >> $dynamic
    echo "<!ENTITY arch-kernel \"${arch_kernel}\">" >> $dynamic
    echo "<!ENTITY arch-listname \"${arch_listname}\">" >> $dynamic
    echo "<!ENTITY arch-porturl \"${arch_porturl}\">" >> $dynamic
    echo "<!ENTITY arch-parttype \"${arch_parttype}\">" >> $dynamic
    echo "<!ENTITY kernelversion \"${kernelversion}\">" >> $dynamic
    echo "<!ENTITY kernelpackage \"${kernelpackage}\">" >> $dynamic
    echo "<!ENTITY smp-config-section \"${smp_config_section}\">" >> $dynamic
    echo "<!ENTITY smp-config-option \"${smp_config_option}\">" >> $dynamic
    echo "<!ENTITY minimum-memory \"${minimum_memory}&notation-megabytes;\">" >> $dynamic
    echo "<!ENTITY minimum-memory-gtk \"${minimum_memory_gtk}&notation-megabytes;\">" >> $dynamic

    sed "s:##SRCPATH##:$source_path:" templates/docstruct.ent >> $dynamic

    sed "s:##LANG##:$language:g" templates/install.xml.template | \
        sed "s:##TEMPDIR##:$tempdir:g" | \
        sed "s:##ENTPATH##:$entities_path:g" | \
        sed "s:##SRCPATH##:$source_path:" > $tempdir/install.${language}.xml

    # Create the profiled xml file
    xsltproc \
        --xinclude \
        --stringparam profile.arch "$archspec" \
        --stringparam profile.condition "$condition" \
        --output $tempdir/install.${language}.profiled.xml \
        $stylesheet_profile \
        $tempdir/install.${language}.xml
    RET=$?; [ $RET -ne 0 ] && return $RET

    return 0
}

create_html () {

    echo "Info: creating .html files..."

    xsltproc \
        --xinclude \
        --stringparam base.dir $destdir/html/ \
        $stylesheet_html \
        $tempdir/install.${language}.profiled.xml 2>&1
    RET=$?; [ $RET -ne 0 ] && return $RET

    # Copy the custom css stylesheet to the destination directory
    cp $stylesheet_css $destdir/html/

    return 0
}

create_text () {

    [ -x "`which w3m 2>/dev/null`" ] || return 9

    echo "Info: creating temporary .html file..."

    xsltproc \
        --xinclude \
        --output $tempdir/install.${language}.html \
        $stylesheet_html_single \
        $tempdir/install.${language}.profiled.xml
    RET=$?; [ $RET -ne 0 ] && return $RET

    # Replace some unprintable characters
    sed "s:–:-:g        # n-dash
         s:—:--:g       # m-dash
         s:“:\&quot;:g  # different types of quotes
         s:”:\&quot;:g
         s:„:\&quot;:g
         s:…:...:g      # ellipsis
         s:™: (tm):g    # trademark" \
        $tempdir/install.${language}.html >$tempdir/install.${language}.corr.html
    RET=$?; [ $RET -ne 0 ] && return $RET

    echo "Info: creating .txt file..."

    # Set encoding for output file
    case "$language" in
        ru)  CHARSET=KOI8-R ;;
        *)   CHARSET=UTF-8 ;;
    esac
    
    HOME=$tempdir w3m -dump $tempdir/install.${language}.corr.html \
        -o display_charset=$CHARSET \
        >$destdir/install.${language}.txt
    RET=$?; [ $RET -ne 0 ] && return $RET
    
    return 0
}

create_dvi () {
    
    [ -x "`which openjade 2>/dev/null`" ] || return 9
    [ -x "`which jadetex 2>/dev/null`" ] || return 9

    # Skip this step if the .dvi file already exists
    [ -f "$tempdir/install.${language}.dvi" ] && return

    echo "Info: creating temporary .tex file..."

    # And use openjade to generate a .tex file
    export SP_ENCODING="utf-8"
    openjade -t tex \
        -b utf-8 \
        -o $tempdir/install.${language}.tex \
        -d $stylesheet_dsssl \
        -V tex-backend declaration/xml.dcl \
        $tempdir/install.${language}.profiled.xml
    RET=$?; [ $RET -ne 0 ] && return $RET

    # some languages need additional macro
    case "$language" in
        ko)
            mv $tempdir/install.${language}.tex \
                $tempdir/install.${language}.orig.tex
            cat templates/header.${language}.tex \
                $tempdir/install.${language}.orig.tex \
                > $tempdir/install.${language}.tex
            rm $tempdir/install.${language}.orig.tex
            ;;
    esac

    echo "Info: creating temporary .dvi file..."

    # Next we use jadetex to generate a .dvi file
    # This needs three passes to properly generate the index (page numbering)
    cd $tempdir
    for PASS in 1 2 3 ; do
        jadetex install.${language}.tex >/dev/null
        RET=$?; [ $RET -ne 0 ] && break
    done
    cd ..
    [ $RET -ne 0 ] && return $RET

    return 0
}

create_pdf() {
    
    [ -x "`which dvipdf 2>/dev/null`" ] || return 9

    create_dvi
    RET=$?; [ $RET -ne 0 ] && return $RET

    echo "Info: creating .pdf file..."

    dvipdf $tempdir/install.${language}.dvi
    RET=$?; [ $RET -ne 0 ] && return $RET
    mv install.${language}.pdf $destdir/

    return 0
}

create_ps() {
    
    [ -x "`which dvips 2>/dev/null`" ] || return 9

    create_dvi
    RET=$?; [ $RET -ne 0 ] && return $RET

    echo "Info: creating .ps file..."

    dvips -q $tempdir/install.${language}.dvi
    RET=$?; [ $RET -ne 0 ] && return $RET
    mv install.${language}.ps $destdir/

    return 0
}

## MAINLINE

# Clean old builds
rm -rf $tempdir
rm -rf $destdir

[ -d "$manual_path/$language" ] || {
    echo "Error: unknown language '$language'" >&2
    exit 1
}

mkdir -p $tempdir
mkdir -p $destdir

# Create profiled XML. This is needed for all output formats.
create_profiled
RET=$?; [ $RET -ne 0 ] && exit 1

BUILD_OK=""
BUILD_FAIL=""
for format in $formats ; do
    case "$language" in
        el|ja|vi|zh_CN|zh_TW)
            if [ "$format" = "pdf" -o "$format" = "ps" ] ; then
                echo "Warning: pdf and ps formats are currently not supported for Chinese, Greek, Japanese and Vietnamese"
                BUILD_SKIP="$BUILD_SKIP $format"
                continue
            fi
            ;;
    esac

    case $format in
        html)  create_html;;
        ps)    create_ps;;
        pdf)   create_pdf;;
        txt)   create_text;;
        *)
            echo "Error: format $format unknown or not yet supported!" >&2
            exit 1
            ;;
    esac

    RET=$?
    case $RET in
        0)
            BUILD_OK="$BUILD_OK $format"
            ;;
        9)
            BUILD_FAIL="$BUILD_FAIL $format"
            echo "Error: build of $format failed because of missing build dependencies" >&2
            if [ "$format" = "pdf" ] ; then
                echo "Error: (make sure you have ghostscript, openjade and jadetex installed for PDF builds)" >&2
            fi
            ;;
        *)
            BUILD_FAIL="$BUILD_FAIL $format"
            echo "Error: build of $format failed with error code $RET" >&2
            ;;
    esac
done

# Clean up
rm -r $tempdir

# Evaluate the overall results
[ -n "$BUILD_SKIP" ] && echo "Info: The following formats were skipped:$BUILD_SKIP"
[ -z "$BUILD_FAIL" ] && exit 0            # Build successful for all formats
echo "Warning: The following formats failed to build:$BUILD_FAIL"
[ -n "$BUILD_OK" ] && exit 2              # Build failed for some formats
exit 1                                    # Build failed for all formats
