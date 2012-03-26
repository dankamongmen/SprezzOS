#! /bin/bash
BASEDIR=~/Work/Debian/
EXTRACT=${BASEDIR}d-i/trunk/scripts/l10n/l10n-spellcheck/extract_msg.pl
SPELLCHECKER=/usr/bin/enchant
WORDLISTPREFIX=${BASEDIR}d-i/trunk/scripts/l10n/l10n-spellcheck/cfg/level
WORDLISTPOSTFIX=/wls/di_common_wl.txt

if [ -f fi_all.po ] ; then
    rm fi_all.po
fi

# no fi_all.po at *.po time
for f in *.po ; do
    ${EXTRACT} -msgstr ${f} > $$.temp1
    tail --lines=+3 $$.temp1 > $$.temp2
    cut --delimiter=\" --fields=2 < $$.temp2 >> fi_all.po
done

rm $$.temp1 $$.temp2

#Combine the di_common_wl.txt files from subdirectories
#of WORDLIST
if [ -f ok_words.txt ] ; then
    rm ok_words.txt
fi
for i in 1 2 3 ; do
  cat ${WORDLISTPREFIX}${i}${WORDLISTPOSTFIX} >> $$.temp4
done
sort $$.temp4 | uniq > ok_words.txt
rm $$.temp4

# Make list of words spellchecker does not accept
${SPELLCHECKER} -l -d fi < fi_all.po > $$.temp3
sort $$.temp3 | uniq --count > finnish_unkn_wl.txt
rm $$.temp3
echo "Tuntemattomia sanoja " `wc -l finnish_unkn_wl.txt`
