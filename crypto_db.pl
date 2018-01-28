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

# some global variables
#First some global constants
my $baseURL = "https://api.coinmarketcap.com/v1/ticker/?limit=0";
my @tickers;
my @qtys;
my @buy_price_data;
my $driver = "SQLite";
my $database = "crypto_data/test.db";
my $dsn = "DBI:$driver:dbname=$database";

# read in the coin data from a data file.
load_coindata();

my $USDtoHKD = 7.82; #Estimate for conversion rate
my $cash_input_hkd = 126000;
my $cash_input_usd = $cash_input_hkd / $USDtoHKD;
my $rows = @tickers ;

my $ua = LWP::UserAgent->new(
	ssl_opts=> { verify_hostname => 0 },
	cookie_jar => {}
);

# Look for command line params
my $sortOrder = $ARGV[0];
if (!$sortOrder) { 
	$sortOrder = "rowid"
}; 
print $sortOrder . "\n";

# Open a connection to the database and truncate the table
# We are only using the db for sorting the rows 
my $dbh = DBI->connect($dsn) or die $DBI::errstr;

my $stmt = qq(DELETE FROM results;);
my $rv = $dbh->do($stmt) or die $DBI::errstr;

#load_initial_values();
refresh_values ();

sub refresh_values {
	my $total_value = 0;
	my $request = HTTP::Request->new("GET" => $baseURL); # get the data, all in one page
	my $response = $ua->request($request);
	if (!$response->is_success()) { die "Get call failed" };
	my $msg = $response->content;
	my @json_obj=decode_json($msg);

	my $idx = 0; 
	my @result_set;
	for (my $i=0; $i < $rows; $i++) {
		my $target = $tickers[$i]; 	
		$idx = 0; 
		# run through the returned result set looking for our ticker.
		while (defined ($json_obj[0][$idx])) {
			if ($target eq $json_obj[0][$idx]->{"id"}) {
				last;
			};
			$idx++;
		}

		#create temp variables to hold values
		my $t_id = $json_obj[0][$idx]->{"id"};
		my $t_name = $json_obj[0][$idx]->{"name"};
		my $t_symbol = $json_obj[0][$idx]->{"symbol"};
		my $t_rank = $json_obj[0][$idx]->{"rank"};
		my $t_price_usd = $json_obj[0][$idx]->{"price_usd"};
		my $t_qty = $qtys[$i];
		my $t_buy_price = $buy_price_data[$i];
		my $t_value_usd = $qtys[$i] * $t_price_usd;
		$total_value+=$t_value_usd;
		my $t_change_pct= (($t_price_usd-$buy_price_data[$i])/$buy_price_data[$i])*100; 
		my $t_change_usd = ($t_price_usd-$buy_price_data[$i]) * $qtys[$i];
		my $t_change_1h = $json_obj[0][$idx]->{"percent_change_1h"};
		my $t_change_24h = $json_obj[0][$idx]->{"percent_change_24h"};
		my $t_change_7d = $json_obj[0][$idx]->{"percent_change_7d"};

		my $ins_stmt = qq(
		INSERT INTO results (
			rowid,
			id, 
			name,
			symbol,
			rank,
			price_usd,
			qty,
			value_usd,
			buy_price,
			change_pct,
			change_usd,
			change_1h,
			change_24h,
			change_7d )
			VALUES (
			$i,
			\"$t_id\",
			\"$t_name\",
			\"$t_symbol\",
			$t_rank,
			$t_price_usd,
			$t_qty,
			$t_value_usd,
			$t_buy_price,
			$t_change_pct,
			$t_change_usd,
			$t_change_1h,
			$t_change_24h,
			$t_change_7d ));

		$rv = $dbh->do($ins_stmt) or die $DBI::errstr;
		} ;
		# We have now loaded all data into the database

		my $select_stmt = qq (SELECT * FROM results ORDER BY $sortOrder);
		my $sth = $dbh->prepare($select_stmt);
		$rv = $sth->execute() or die $DBI::errstr;

		open (PRICEDATA, ">crypto_data/pricedata_db") or die "Could not open data file: $!";
		while (my @row = $sth->fetchrow_array()) {
			print PRICEDATA $row[2] . "/" ; # Name
			print PRICEDATA $row[3] . "/" ; # Symbol
			print PRICEDATA $row[4] . "/" ; # Rank
			print PRICEDATA Number::Format::format_number($row[5],2,2) . "/" ; # Price USD
			print PRICEDATA Number::Format::format_number($row[8],2,2) . "/" ; # Buy Price
			print PRICEDATA Number::Format::format_number($row[9],2,2) . "/" ; # Change Pct
			print PRICEDATA Number::Format::format_number($row[6],2,2) . "/" ; # Qty
			print PRICEDATA Number::Format::format_number($row[7],2,2) . "/" ; # Value USD
			my $t = $row[7] * $USDtoHKD;
			print PRICEDATA Number::Format::format_number($t,2,2) . "/" ; # Value HKD
			print PRICEDATA Number::Format::format_number($row[10],2,2) . "/" ; # Change USD
			print PRICEDATA Number::Format::format_number($row[11],2,2) . "/" ; # Change 1h
			print PRICEDATA Number::Format::format_number($row[12],2,2) . "/" ; # Change 24h
			print PRICEDATA Number::Format::format_number($row[13],2,2) . "/" ; # Change 7d 
			print PRICEDATA "\n";
		};

		$dbh->disconnect();

	close PRICEDATA;

	open (SUMMARY, ">crypto_data/summarydata") or die "Could not open data file: $!";
	printf SUMMARY "Total USD/" . Number::Format::format_number($total_value,2,2) . "\n"; # total USD
	printf SUMMARY "Total HKD/" . Number::Format::format_number($total_value * $USDtoHKD,2,2) . "\n"; # total HKD
	my $diff = (($total_value - $cash_input_usd)/$cash_input_usd)*100; 
	printf SUMMARY "Percent change/" . Number::Format::format_number($diff) . "\n"; #percent increase
	$diff = $total_value - $cash_input_usd;
	printf SUMMARY "USD Change/" . Number::Format::format_number($diff) . "\n"; # USD change
	printf SUMMARY "HKD Change/" . Number::Format::format_number($diff*$USDtoHKD) . "\n" ; # HKD Change
#	$change_value_b->set_text(Number::Format::format_number($diff));
#	$change_value_hkd_b->set_text(Number::Format::format_number($diff*$USDtoHKD));
	my @ta = localtime();
	my $time_str= ($ta[5]+1900) . "-" . sprintf("%02d",($ta[4]+1)) . "-" . sprintf("%02d",$ta[3]) . "\t" . sprintf("%02d",$ta[2]) . ":"  . sprintf("%02d",$ta[1]);
	printf SUMMARY "Last Refresh" . "/" . $time_str;
	close SUMMARY;
} # end of sub refresh_values

#load coin data from coindata file.
sub load_coindata {
	open (COINDATA, "<crypto_data/coindata") or die "Could not open data file: $!";
	my $idx = 0;
	my $tmp_t; my $tmp_q; my $tmp_p;
	while (<COINDATA>) {
		chomp($_);
		($tmp_t,$tmp_q,$tmp_p) = split /,/, $_;
		push (@tickers, $tmp_t);
		push (@qtys, $tmp_q);
		push (@buy_price_data, $tmp_p);
	}
}
