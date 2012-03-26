#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Make a list of words that enchant spell checker does not
approve. Words are parsed from the files given as arguments.
One or more word list files can be given, those words are deemed
OK even if enchant would flag them wrong.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Library General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

Author: Tapio Lehtonen <tale@debian.org> 
"""

def handleCommandLine():
    """ Get arguments and options from command line. """
    from optparse import OptionParser

    usage = """usage: %prog [options] filename
Print out unknown words found in filename. Options
-p and --wordlist can be given several times."""
    lhelpstr = """What language is the text to proofread? For example fi_FI."""
    lonlyhelpstr = """List only the misspellings. This is the default, but
added this option to be compatible with enchant."""
    parser = OptionParser(usage=usage)
    parser.set_defaults(verbose=False, listonly=True, wordlists=[])
    parser.add_option("-p", "--wordlist", 
                      action="append", type="string", dest="wordlists",
                      help="File with OK words one per line.",
                      metavar="Wordlist")
    parser.add_option("-d", "--language", 
                      action="store", type="string", dest="language",
                      help=lhelpstr)
    parser.add_option("-l", "--listonly", 
                      action="store_true", dest="listonly",
                      help=lonlyhelpstr)
    parser.add_option("-v", action="store_true", dest="verbose",
                      help="Be verbose.")
    parser.add_option("-q", action="store_false", dest="verbose",
                      help="Be quiet (the default).")

    (options, args) = parser.parse_args()
    if len(args) != 1:
        parser.error("incorrect number of arguments, filename missing")
    if options.verbose:
        if (options.wordlists == [] or options.wordlists == None):
            print "No extra wordlist files."
        else:
            print "Extra wordlists: ",
            for f in options.wordlists:
                print f + " ",
            print
        if options.language:
            print "Proofreading using language ", options.language, "."
        else:
            print "Proofreading using default language."
    
    return (options, args)


if __name__ == "__main__":
    """Use like this
    ./find-unkn-words.py -p pwl -d fi_FI fi_all.po > fi_unkn_wl.txt
    where pwl is name of file containing OK words"""

    from enchant.checker import SpellChecker
    import sys

    o, a = handleCommandLine()
    if o.verbose:
        print "options   ", o
        print "arguments ", a

    #Try opening filename, if file can not be read we exit
    #right now since nothing to do.
    try:
        textF = open(a[0], "r")
    except IOError, value:
        print "Can't open filename, can not do anything.", value
        sys.exit(4)

    if o.verbose:
        import sys
        print "Language is", o.language
        print "STDOUT encoding ", sys.stdout.encoding
        print "sys default encoding ", sys.getdefaultencoding()
    checker = SpellChecker(o.language)
    if o.verbose:
        if checker.wants_unicode:
            print "Checker wants Unicode text to check."
        else:
            print "Checker wants normal strings text to check."
    #Read in Personal word lists, may be several files
    for pN in o.wordlists:
        try:
            pF = open(pN, "r")
        except IOError, value:
            print "Error, personal word list could not be opened for reading ", pN
            sys.exit(5)
        for word in pF.readlines():
            if len(word) > 0: # Don't add empty words
                if (word[0] != "#" and word[0] != " "): #Don't add comment lines
                    # Workaroud for Debian bug #545848
                    checker.dict.add(word)
                    # When bug is fixed, replace above line with
                    # checker.add(word)

        pF.close()

    unknWords={}
    #Find unknown words and count number of occurrences for each.
    for text in textF.readlines():
        utext = unicode(text, "utf-8")
        if o.verbose:
            print "Text as read:"
            print text 
            print "Text to check is:"
            for u in utext:
                print u.encode("utf-8"),
            print
        checker.set_text(utext)
        for err in checker:
            if o.verbose:
                print "isinstance basestring", isinstance(err.word, basestring)
                print "isinstance str", isinstance(err.word, str)
                print "isinstance unicode", isinstance(err.word, unicode)
                print err.word.encode("utf-8")
            if unknWords.has_key(err.word):
                unknWords[err.word] += 1
            else:
                unknWords[err.word] = 1
    textF.close()
    
    #Sort alphabetically and print out as count word
    wlist = unknWords.keys()
    wlist.sort()
    for w in wlist:
        print str(unknWords[w]).rjust(6).encode("utf-8"), u" ",
        print w.encode("utf-8")
