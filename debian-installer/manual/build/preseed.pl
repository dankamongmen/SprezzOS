#!/usr/bin/perl -w

# Script parses the XML file for the appendix on preseeding and extracts
# example snippts to form the raw preseed example file. Section titles are
# added as headers.
# The script will include all text between <informalexample> tags that have
# the attribute 'role="example"' set, except if a 'condition' attribute is
# in force that does not match the specified release or if an 'arch' attribute
# is in force that does not match the specified architecture.

# Define module to use
use HTML::Parser();
use Getopt::Std;

local %tagstatus;
local %example;
local %ignore;
local $prevtag = '';
local $titletag;
local $settitle = 0;

$example{'print'} = 0;
$example{'in_sect'} = 0;
$example{'first'} = 1;
$example{'new'} = 0;

getopts('hda:r:') || die "Unknown command line arguments! Try $0 -h\n";
use vars qw($opt_h $opt_d $opt_a $opt_r);

if ($opt_h) {
	print <<END;
preseed.pl: parses preseed appendix xml file to extract preseed example file

Usage: $0 [-hdac] <xml-file>

Options:
        -h              display this help information
        -d              debug mode
        -a <arch>       architecture for which to generate the example
                        (default: i386)
        -r <release>    release for which to generate the example (required)
END
	exit 0;
}

die "Must specify release for which to generate example.\n" if ! $opt_r;

my $xmlfile = shift;
die "Must specify XML file to parse!\n" if ! $xmlfile;
die "Specified XML file \"$xmlfile\" not found.\n" if ! -f $xmlfile;

my $arch = $opt_a ? "$opt_a" : "i386";
my $release = $opt_r;


# Create instance
$p = HTML::Parser->new(
	start_h => [\&start_rtn, 'tagname, text, attr'],
	text_h => [\&text_rtn, 'text'],
	end_h => [\&end_rtn, 'tagname']);

# Start parsing the specified file
$p->parse_file($xmlfile);

# Replace entities in examples
# FIXME: should maybe be extracted from entity definition
sub replace_entities {
	my $text = shift;

	$text =~ s/&archive-mirror;/http.us.debian.org/g;
	$text =~ s/&releasename;/$release/g;
	$text =~ s/&kernelpackage;/linux-image/g;
	$text =~ s/&kernelversion;/2.6.32/g;
	$text =~ s/&gt;/>/g;
	$text =~ s/&lt;/</g;


	# Any unrecognized entities?
	if ( $text =~ /(&[^ ]+;)/ ) {
		die "Error: unrecognized entity '$1'\n"
	}

	return $text;
}

# Execute when start tag is encountered
sub start_rtn {
	my ($tagname, $text, $attr) = @_;
	print STDERR "\nStart: $tagname\n" if $opt_d;

	if ( $tagname =~ /appendix|sect1|sect2|sect3|para|informalexample|phrase/ ) {
		$tagstatus{$tagname}{'count'} += 1;
		print STDERR "$tagname  $tagstatus{$tagname}{'count'}\n" if $opt_d;

		if ( ! exists $ignore{'tag'} ) {
			# FIXME: this ignores that 'contition' is used for many
			# other things than the release; should be OK in practice
			# for the preseed appendix though.
			if ( exists $attr->{condition} ) {
				print STDERR "Condition: $attr->{condition}\n" if $opt_d;
				if ( $attr->{condition} ne $release ) {
					$ignore{'tag'} = $tagname;
					$ignore{'depth'} = $tagstatus{$tagname}{'count'};
					print STDERR "Start ignore because of condition" if $opt_d;
				}
			}
			if ( exists $attr->{arch} ) {
				print STDERR "Architecture: $attr->{arch}\n" if $opt_d;
				if ( $attr->{arch} ne $arch ) {
					$ignore{'tag'} = $tagname;
					$ignore{'depth'} = $tagstatus{$tagname}{'count'};
					print STDERR "Start ignore because of architecture" if $opt_d;
				}
			}
		}
	}

	# Assumes that <title> is the first tag after a section tag
	if ( $prevtag =~ /sect1|sect2|sect3/ ) {
		$settitle = ( $tagname eq 'title' );
		$titletag = $prevtag;
		$example{'in_sect'} = 0;
	}
	$prevtag = $tagname;
	if ( $tagname eq 'informalexample' && ! exists $ignore{'tag'} ) {
		if ( exists $attr->{role} && $attr->{role} eq "example" ) {
			$example{'print'} = 1;
			$example{'new'} = 1;
		}
	}
}
 
# Execute when text is encountered
sub text_rtn {
	my ($text) = @_;

	if ( $settitle ) {
		# Clean leading and trailing whitespace for titles
		$text =~ s/^[[:space:]]*//;
		$text =~ s/[[:space:]]*$//;

		$text = replace_entities($text);
		$tagstatus{$titletag}{'title'} = $text;
		$settitle = 0;
	}

	if ( $example{'print'} && ! exists $ignore{'tag'} ) {
		# Print section headers
		for ($s=1; $s<=3; $s++) {
			my $sect="sect$s";
			if ( $tagstatus{$sect}{'title'} ) {
				print "\n" if ( $s == 1 && ! $example{'first'} );
				for ( $i = 1; $i <= 5 - $s; $i++ ) { print "#"; };
				print " $tagstatus{$sect}{'title'}\n";
				delete $tagstatus{$sect}{'title'};
			}
		}

		# Clean leading whitespace
		if ( $example{'new'} ) {
			$text =~ s/^[[:space:]]*//;
		}

		$text = replace_entities($text);
		print "$text";

		$example{'first'} = 0;
		$example{'new'} = 0;
		$example{'in_sect'} = 1;
	}
}

# Execute when the end tag is encountered
sub end_rtn {
	my ($tagname) = @_;
	print STDERR "\nEnd: $tagname\n" if $opt_d;

	# Set of tags must match what's in start_rtn
	if ( $tagname =~ /appendix|sect1|sect2|sect3|para|informalexample|phrase/ ) {
		my $ts = $tagstatus{$tagname}{'count'};
		$tagstatus{$tagname}{'count'} -= 1;
		print STDERR "$tagname  $tagstatus{$tagname}{'count'}\n" if $opt_d;
		die "Invalid XML file: negative count for tag <$tagname>!\n" if $tagstatus{$tagname}{'count'} < 0;

		if ( exists $ignore{'tag'} ) {
			if ( $ignore{'tag'} eq $tagname && $ignore{'depth'} == $ts ) {
				delete $ignore{'tag'};
			}
			return
		}
	}

	if ( $tagname eq 'informalexample' ) {
		$example{'print'} = 0;
	}

	if ( $tagname =~ /appendix|sect1|sect2|sect3|para/ ) {
		delete $tagstatus{$tagname}{'title'} if exists $tagstatus{$tagname}{'title'};

		if ( $example{'in_sect'} ) {
			print "\n";
			$example{'in_sect'} = 0;
		}
	}
}
