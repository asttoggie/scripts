#!/usr/bin/perl -w 
# Backup by telnet from Huawei switches

use strict;

use Net::Telnet;
use POSIX qw(strftime);

my @nethost = ("______");
my $netport = "23";
my $prompt = '/\S+>|]$/';
my $h_log = "______";
my $h_pass = '______';

my $cur_date = strftime "%G%m%d", localtime;

my $dir = "______";
my $d_perm = "0755";
my $f_perm = "644";

unless (-d "$dir/$cur_date") {
  mkdir "$dir/$cur_date", oct($d_perm);
}

for (my $j = 0; $j <= $#nethost; $j++) {
 my $ts = Net::Telnet->new(Timeout => 60,  Prompt => $prompt);
 $ts->open(Host => $nethost[$j], Port => $netport);
 $ts->login($h_log,$h_pass);
 $ts->cmd("screen-length 0 temporary");
 my @test = $ts->cmd("display current-configuration");
 print @test;
 open(FILE, ">$dir/$cur_date/$nethost[$j].conf");
 print FILE "@test";
 close(FILE);
 $ts->close;
}
