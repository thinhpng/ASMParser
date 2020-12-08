################################################################################
# This script is written by Thinh Nguyen @ASM
# It's used to analyze the mes log for Samsung customer
# due to the issue reported via OneComm# 300130350
# It computes the wafer & recipe complete time to locate event delay or missing
################################################################################
#!/usr/bin/perl
use strict "vars";
use Win32::File;
use File::Path;
use File::Find;
use warnings FATAL => 'all';
use Date::Parse;
use POSIX qw{strftime};
use feature qw(say);
use Tk;
use Tk::DirSelect;
use Cwd;
my $libSource = 'C:\ASM-Host\Config\ALD\Archive\VIDsInCode.txt';
open (INFILE, "$libSource") || die "ERROR! Can't open $libSource\n";
my @libBucket = <INFILE>;
close(INFILE) || die "ERROR! Can't close $libSource\n";
foreach my $line_str (@libBucket) {
    #skip all the comments or blank lines
    next if (($line_str =~ /^[#|\/\/]/) || ($line_str =~ /^$/));
    #print "line_str=$line_str\n";
    #chomp($line_str);
    if ($line_str =~ /^(.*?)=\$(.*?);/i) {
        my $decNumb = hex($2);
        say "VID: \$$2 : $decNumb : $1 :";
        #        print"Ceid: $1\n";
        #        print"Name: $2\n";
    }else {
        say $line_str;
    }
}