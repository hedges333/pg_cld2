#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use LWP::UserAgent;
use HTML::TableExtract;
use HTML::Entities;
use YAML;

use open qw( :std :encoding(UTF-8) );
binmode(STDOUT, ":encoding(UTF-8)");
binmode(STDERR, ":encoding(UTF-8)");

# Create a user agent object
my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;

# URL of the Wikipedia page
my $url = 'https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes';

# Make the HTTP request
my $response = $ua->get($url);

# Check for HTTP response errors
die "HTTP GET error: ", $response->status_line unless $response->is_success;

# Get the content of the response
my $content = $response->decoded_content;

my @headers = qw(
    language
    iso_639_1
    iso_639_2_t
    iso_639_2_b
    iso_639_3
    scope
    type
    endonym
    other_names
    notes
);

print qq{CREATE TABLE IF NOT EXISTS pg_cld2_language_names (
    language        VARCHAR(12),
    iso_639_1       VARCHAR(3)

# Parse the table
my $te = HTML::TableExtract->new(attribs => { id => 'Table' });
$te->parse($content);

# Write the SQL insert statements
foreach my $ts ($te->tables) {
    print qq{INSERT INTO iso_language_names (}.join(q{, }, @headers).qq{) VALUES\n};
    foreach my $row ($ts->rows) {
        warn Dump($row);
        print '(', join(q{, },
            map qq{'$_'},
            map { s/'/''/g; $_ }
            map { defined $_ ? decode_entities($_) : 'NULL' }
            @$row
        ), ")\n";
    }
}

# print "SQL insert statements have been generated and saved to 'iso_language_names_insert.sql'\n";
