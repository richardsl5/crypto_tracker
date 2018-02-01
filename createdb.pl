#!/usr/bin/perl
# Version info
# 1.1 add buy date 

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

my $stmt = qq(create table results (
	rowid		INT		PRIMARY KEY,
	id 			TEXT	NOT NULL,
	name 		TEXT	NOT NULL,
	symbol		TEXT	NOT NULL,
	rank		INT		NOT NULL,
	price_USD	real	NOT NULL,
	qty			real	NOT NULL,
	value_usd	real	NOT NULL,
	buy_price	real	NOT NULL,
	change_pct	real	NOT NULL,
	change_usd	real	NOT NULL,
	change_1h	real	NOT NULL,
	change_24h	real	NOT NULL,
	change_7d	real 	NOT NULL,
	buy_date	text	NOT NULL);
	);
	
my $rv = $dbh->do($stmt);
if ($rv < 0) {
	print $DBI::errstr;
} else {
	print "Table created successfully\n";
}
