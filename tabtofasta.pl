#!/usr/bin/perl
#a script pretty much ripped off from the Bioperl web page SeqIO HOWTO suggestions: 
#http://bioperl.open-bio.org/wiki/HOWTO:SeqIO
#author (ish): Bela Tiwari, NEBC
use strict;
use warnings;
use Bio::SeqIO;

my $format1 = "tab";
my $format2 = "Fasta";
my $file = shift || die "Usage: tabtofasta.pl <filename>\n";
open (FILEIN, "$file");

    my $in  = Bio::SeqIO->newFh(-format => $format1, -fh => \*FILEIN );
    my $out = Bio::SeqIO->newFh(-format => $format2 );
    print $out $_ while <$in>;

close FILEIN;