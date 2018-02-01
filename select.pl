#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;
use Glib qw/TRUE FALSE/;
use JSON;
use LWP::UserAgent;
use HTTP::Request;
use Number::Format;
use Data::Dumper;
use DBI;

my $driver = "SQLite";
my $database = "crypto_data/test.db";
my $dsn = "DBI:$driver:dbname=$database";
my $dbh = DBI->connect($dsn) or die $DBI::errstr;
print "Opened database successfully\n";

my $select_stmt = qq(
	SELECT * 
	FROM results ORDER BY rank) ;

#
my $sth = $dbh->prepare($select_stmt);
my $rv = $sth->execute() or die $DBI::errstr;
while (my @row = $sth->fetchrow_array()){
	foreach my $i (@row) {
		print ("$i, ");
		};
	print ("\n");
}		
$dbh->disconnect();
