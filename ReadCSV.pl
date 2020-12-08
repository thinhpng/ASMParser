#!/usr/bin/perl

use warnings FATAL => 'all';

my $item = 'D:\Escalation\Intel\0Test\Project\UPC\Work\CollectLog\LogMC\PMC1\PmSus_0127_225808.CSV';


open(INFH, '<', $item) or die "Could not open '$item' $!\n";

my $timeStamp = "";
my $timePattern = '\[(\d+\/\d+-\d+:\d+:\d+.\d+)\]';
#my $first = "";
#my $last = "";

my @fileContent = <INFH>;
close INFH;

my $first = shift(@fileContent);
my $last = pop(@fileContent);

print $first;
print $last;

if ($first =~ /$timePattern/) {

    print "From: ", $1;
}

if ($last =~ /$timePattern/) {
    $timeStamp = $1;
    print " ---> ", $timeStamp, "\n";
}

print " ---> ", $timeStamp, "\n";





