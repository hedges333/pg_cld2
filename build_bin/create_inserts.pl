#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use YAML;

use FindBin;

my %postguess;

open my $csv_fh, '<', "$FindBin::Bin/postgres_encoding_guesses.csv" || die $@;
while (my $csv_line = <$csv_fh>) {
    chomp($csv_line);
    my ($cld2_encoding, $postgres_encoding) = split q{,}, $csv_line;
    $postguess{$cld2_encoding} = $postgres_encoding;
}
close $csv_fh;

my $encodings_h_filepath = $ARGV[0];

die "whoops" if !$encodings_h_filepath;

open my $encodings_fh, '<', $encodings_h_filepath || die $@;

print "INSERT INTO pg_cld2_encodings VALUES\n";

my $maxlen = 0;
my @values;
my $preline_notes;
while (my $line = <$encodings_fh>) {
    chomp($line);
    #print "line='$line'\n";
    if ($line =~ m{ \A \s* ([A-Z_0-9]+) \s* = \s* (\d+) , (?: \s* // \s+ (.*?) )? \z }mxs) {
        my ($constant, $value, $notes) = ($1, $2, $3);
        next if $constant eq 'NUM_ENCODINGS';
        #$maxlen = length($notes) if length($notes) > $maxlen;
        #print "constant='$constant', value='$value', notes='$notes'\n";
        #print "****************************\n";
        if ($preline_notes && !$notes) {
            $notes = $preline_notes;
            $preline_notes = '';
        }
        push @values, {
            constant => $constant,
            const_value => $value,
            notes => $notes,
        };
        #print "constant='$constant' notes='$notes'\n";
    }
    elsif ( $line =~ m{ \A \s{5}\s* // \s* ([^\w] .*?) \z }mxs ) {
        my $extra_notes = $1;
        #warn "******** '$extra_notes'\n";
        $values[$#values]{notes} .= $extra_notes;
    }
    elsif ($line =~ m{ \A \s\s // \s (\S .*?) \z }mxs ) {
        my $more_preline_notes = $1;
        #warn "mpn='$more_preline_notes'\n";
        $preline_notes .= ' ' if $preline_notes;
        $preline_notes .= $more_preline_notes;
    }

    if (@values && $values[$#values]{notes}) {
        $values[$#values]{notes} =~ s{ \s \s+ }{ }mxs 
    }

}

#exit;

my @print_values = map {
    '('
    ."'$_->{constant}', "
    .($postguess{$_->{constant}} ? "'$postguess{$_->{constant}}', " : 'NULL, ')
    ."$_->{const_value}, "
    .($_->{notes} ? "'$_->{notes}'" : 'NULL')
    .')';
} @values;
print join(",\n", @print_values), ";\n";
#print "-- $maxlen\n";
