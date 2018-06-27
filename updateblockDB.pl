#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use Carp;
use Getopt::Long;
use LWP::Simple;
use URI;

# Database connection details
my $database = "<DB>";
my $dbuser   = "<DBUSER>";
my $dbpass   = "<DBPASS>";
my $dbhost   = "localhost";
my $dbport   = 3306;

# default URL for blocklist updates
my $blocklist_URL
    = "http://pgl.yoyo.org/adservers/serverlist.php?hostformat=nohtml\&mimetype=plaintext";

my $dsn = "DBI:mysql:database=$database;host=$dbhost;port=$dbport";
my $dbh = DBI->connect( $dsn, $dbuser, $dbpass );
my $sth;
unless ($dbh) {
    croak "Database connection failed, aborting\n";
}

my $fetch = 0;
my $datafile;
my $help;
GetOptions(
    'help|?' => \$help,
    'fetch!' => \$fetch,
    'url=s'  => \$blocklist_URL,
    'file=s' => \$datafile
);

if ($help) { &usage; }

unless ( ($datafile) || ($fetch) ) { &usage; }

my $bl_host;
my @records;
if ($fetch) {
    if ( $blocklist_URL =~ m@://([\w.-]*)/@ ) { $bl_host = $1; }
    print "Updating blocklist from $bl_host\n";
    my $uri      = URI->new($blocklist_URL);
    my $response = get($uri);
    if ( $response =~ m/\w/ ) {
        @records = split /\n/, $response;
    }
}

elsif ( -f $datafile ) {
    open IN, "<$datafile" or croak "Failed to read $datafile\n";
    while (<IN>) {
        chomp;
        push( @records, $_ );
    }
}

my %entry;
my $dup    = 0;
my $exists = 0;
my $rec;

# read in the domains list, load into a hash to
# remove duplicates

foreach my $item (@records) {
    $rec++;
    next if ( $item =~ m@^(\s*)?(#|//|;|')@ );
    unless ( $item =~ m/[a-z0-9-]*\.[a-z0-9-]*/i ) {
        print "line $rec domain '$item' invalid, skipping\n";
    }
    if ( $entry{$item} ) { $dup++; }
    $entry{$item} = $item;
}

my $rows;
my $ok = 0;
my $fail = 0;
my $query;
foreach my $domain ( sort keys %entry ) {
    $query = "select count(id) from blocklist where domain = '$domain'";
    $sth   = $dbh->prepare($query);
    $sth->execute();
    $rows = $sth->fetchrow();
    if ( $rows == 0 ) {

        # entry doesn't exist in the table yet, insert it
        $query
            = "INSERT INTO blocklist (domain,timestamp) VALUES ('$domain',NOW())";
        $sth = $dbh->prepare($query);
        $sth->execute();
        $rows = $sth->rows();
        if ( $rows != 1 ) {
            print "insert failed for $domain\n";
            $fail++;
        }
        else { $ok++; }
    }

    # entry already exists in DB
    else { $exists++; }
}
print
    "$dup duplicates, $exists already in db, $ok entries added, $fail failed to insert\n";

sub usage {
    print "usage: $0 [options]\n";
    print "  --help		print this usage and exit\n";
    print "  --fetch		update blocklist from URL\n";
    print "  --url URL		use URL as source for fetch update\n";
    print "  --file FILE		update blocklist from file FILE\n";
    print "\n\n";
    exit(0);
}
