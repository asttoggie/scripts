#!/usr/bin/perl
######################################################################################
# XML parser from Liebert air conditioner internal web server(local conditioner lan) #
######################################################################################

use strict;
use XML::LibXML;
use open ':encoding(utf8)';

my $conf_file = '.............';

my $color_temp = "clear";
my $color_hum = "clear";

my $type_check;
my $line;
my $msg;
my $date = localtime();

# Air Conditioner parameters
my $cur_state;
my $cur_temp;
my $cur_hum;
my $cur_status;

my $i = 0;
my %hash;

# Read configuration file
open(cfg,"<", $conf_file) or die "Could not open file '$conf_file'.$!";
flock(cfg,2);
while(<cfg>)
{
	if (!/^#/)
	{
		chomp $_;
		my @a = split(/ /,$_);

		@{$hash{$i}} = @a;
		
		$i += 1;
	}
}
flock(cfg,8);
close(cfg);

foreach (sort keys(%hash)) {
	my @liebert_ip = $hash{$_}[0];
	my @liebert_name = $hash{$_}[1];
        my $min_cr_t = $hash{$_}[2];
        my $min_warn_t = $hash{$_}[3];
        my $max_warn_t = $hash{$_}[4];
        my $max_cr_t = $hash{$_}[5];
        my $min_cr_h = $hash{$_}[6];
        my $min_warn_h = $hash{$_}[7];
        my $max_warn_h = $hash{$_}[8];
        my $max_cr_h = $hash{$_}[9];
	foreach (@liebert_ip){
		($cur_state, $cur_temp, $cur_hum, $cur_status) = read_xml(@liebert_ip);
		# Check temp
		if (($cur_temp < $min_cr_t) || ($cur_temp > $max_cr_t)) {$color_temp = "red"; $type_check = "tempcheck";}
		elsif (($cur_temp < $min_warn_t) || ($cur_temp > $max_warn_t)) {$color_temp = "yellow"; $type_check = "tempcheck";}
		elsif (($cur_temp > $min_warn_t) || ($cur_temp < $max_warn_t)) {$color_temp = "green"; $type_check = "tempcheck";}
		else {$color_temp = "clear"; $type_check = "tempcheck";}
		gen_report(@liebert_name,$cur_state,$min_cr_t,$min_warn_t,$cur_temp,$max_warn_t,$max_cr_t,$color_temp,$type_check,@liebert_ip,$cur_status);
		# Check humidity
		if (($cur_hum < $min_cr_h) || ($cur_hum > $max_cr_h)) {$color_hum = "red"; $type_check = "humcheck";}
		elsif (($cur_hum < $min_warn_h) || ($cur_hum > $max_warn_h)) {$color_hum = "yellow"; $type_check = "humcheck";}
		elsif (($cur_hum > $min_warn_h) || ($cur_hum < $max_warn_h)) {$color_hum = "green"; $type_check = "humcheck";}
		else {$color_hum = "clear"; $type_check = "humcheck";}
		$color_hum = "green"; 
		$type_check = "humcheck";
		gen_report(@liebert_name,$cur_state,$min_cr_h,$min_warn_h,$cur_hum,$max_warn_h,$max_cr_h,$color_hum,$type_check,@liebert_ip,$cur_status);
		# TODO
		# Check air conditioner alarm
		# Input last logs here
       }
}

sub gen_report () {
	$line = "status $_[0].$_[8] $_[7] Check at $date\n";
	$msg  = "Air conditioner state - $_[1]\n";
	$msg .= "Maintenance Status - $_[10]\n";
	$msg .= "Current : $_[4] \n";
	$msg .= "Warning : $_[3]  - $_[5] \n";
	$msg .= "Critical : $_[2]  - $_[6] \n";
	$msg .= "You can see last logs <b><a href=\"http://$_[9]/tmp/statusreport.xml\">Here</a></b>";
	my $cmd = "$ENV{XYMON} $ENV{XYMSRV} \"$line\n$msg\"\n";
	
	print "$cmd";
	
	system($cmd);
}


sub read_xml() {
	# Read parameters
	my $liebert_param = XML::LibXML->load_xml(location => "http://$_[0]");
	$cur_state = $liebert_param->findvalue('*/Item[@id="354"]/Value');	
	$cur_temp = $liebert_param->findvalue('*/Item[@id="361"]/Value'); 
        $cur_hum = $liebert_param->findvalue('*/Item[@id="379"]/Value'); 
	$cur_status = $liebert_param->findvalue('*/Item[@id="1118"]/Value');
	return ($cur_state, $cur_temp, $cur_hum, $cur_status);
}
