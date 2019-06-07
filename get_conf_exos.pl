#!/usr/bin/perl -w 
use strict;

use Net::Telnet;
use POSIX qw(strftime);

my @nethost = ("........");
my $netport = "........";
my $h_log = "........";
my $h_pass = '........';

my $cur_date = strftime "%G%m%d", localtime;

my $prompt = '/\S+ # $/';

my $dir = "/home/ka";
my $d_perm = "0755";
my $f_perm = "644";

unless (-d "$dir/$cur_date") {
  mkdir "$dir/$cur_date", oct($d_perm);
}

for (my $j = 0; $j <= $#nethost; $j++) {
 unless (-d "$dir/$cur_date/$nethost[$j]"){
  mkdir "$dir/$cur_date/$nethost[$j]", oct($d_perm);
 }

 my $ts = Net::Telnet->new(Timeout => 60,  Prompt => $prompt);
 $ts->open(Host => $nethost[$j], Port => $netport);
 $ts->login($h_log,$h_pass);
 $ts->cmd("disable clipaging");
 my @cfg_all = $ts->cmd("show configuration");
 open(FILE, ">$dir/$cur_date/$nethost[$j]/$nethost[$j].conf");
 print FILE "@cfg_all";
 close(FILE);

 my @p_a = $ts->cmd("show policy");
 splice(@p_a,0,3);
 chomp (@p_a);
 for (my $i = 0; $i <= $#p_a; $i++) {
  my $p_n = substr $p_a[$i], 0, index($p_a[$i], " ");
  my @tmp_p = $ts->cmd("show policy $p_n"); 
  open(FILE, ">$dir/$cur_date/$nethost[$j]/$p_n.pol");
  print FILE "@tmp_p";
  close(FILE);
 }

 $ts->close;
}
