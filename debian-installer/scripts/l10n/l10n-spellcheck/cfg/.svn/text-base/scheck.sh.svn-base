#!/bin/sh
export PATH=${HOME}/d-i/trunk/scripts/l10n/l10n-spellcheck:$PATH

case "$1" in
man)
	l10n-spellcheck.sh ~/d-i/trunk/scripts/l10n/l10n-spellcheck/cfg/manual_d-i
	;;
l1)
	l10n-spellcheck.sh ~/d-i/trunk/scripts/l10n/l10n-spellcheck/cfg/level1
	;;
l2)
	l10n-spellcheck.sh ~/d-i/trunk/scripts/l10n/l10n-spellcheck/cfg/level2
	;;
l3)
	l10n-spellcheck.sh ~/d-i/trunk/scripts/l10n/l10n-spellcheck/cfg/level3
	;;
l4)
	l10n-spellcheck.sh ~/d-i/trunk/scripts/l10n/l10n-spellcheck/cfg/level4
	;;
l5)
	l10n-spellcheck.sh ~/d-i/trunk/scripts/l10n/l10n-spellcheck/cfg/level5
	;;
all)
	l10n-spellcheck.sh ~/d-i/trunk/scripts/l10n/l10n-spellcheck/cfg/manual_d-i
	l10n-spellcheck.sh ~/d-i/trunk/scripts/l10n/l10n-spellcheck/cfg/level1
	l10n-spellcheck.sh ~/d-i/trunk/scripts/l10n/l10n-spellcheck/cfg/level2
	l10n-spellcheck.sh ~/d-i/trunk/scripts/l10n/l10n-spellcheck/cfg/level3
	l10n-spellcheck.sh ~/d-i/trunk/scripts/l10n/l10n-spellcheck/cfg/level4
	l10n-spellcheck.sh ~/d-i/trunk/scripts/l10n/l10n-spellcheck/cfg/level5
	;;
*)
	echo "Unknown parameter. Here's the list of known parameters:"
	echo ""
	echo "all - useful to force a re-run of the spellcheck"
	echo "man"
	echo "l1"
	echo "l2"
	echo "l3"
	echo "l4"
	echo "l5"
	;;
esac
