use strict;
use warnings FATAL => 'all';
use feature qw(say);

use File::stat;
use Time::Local;
use Time::localtime;
use Win32::File;
use File::Path;
use File::Find;

say "INFO! Start ASMParser ...";
my $myfile = "c:\\Scripts\\EventXp.txt";
my $data = "c:\\Scripts\\Meslog20-23.txt";
say "myfile is $myfile";
open (INFILE, "$myfile") || die "ERROR! Can't open $myfile";
my @bucket = <INFILE>;
close(INFILE) || die "ERROR! Can't close $myfile";
open (INFILE, "$data") || die "ERROR! Can't open $myfile";
my @dataBucket = <INFILE>;
close(INFILE) || die "ERROR! Can't close $myfile";
my $find_str = "";
my %ceid;
my $line = 0;
my @out;
foreach my $line_str (@bucket)
{
    #skip all the comments or blank lines
    next if(($line_str =~ /^#/) || ($line_str =~ /^$/));
    #say "line_str=$line_str";
    chomp($line_str);
    if ($line_str =~/^\s+E.*\$(\w+)\s+.*#(.*)$/i)
    {
        $line++;
        #say "$line found event $line_str";
        my $hex = hex("0x".$1);
        say "$1 = $hex $2";
        #my $out =
        push(@out,$hex.",".$2."");
        #	say "CEID: hex($hex)";

    }
}

# foreach $line_str (@dataBucket)
# {
# #skip all the comments or blank lines
# next if(($line_str =~ /^#/) || ($line_str =~ /^$/));
# #say "line_str=$line_str";
# #  chomp($line_str);
# #  $line_str =s/(S6F11\s+(\d+))/$1 $ceid{$2}/i);
# #  \s+(\d+)\s+
# #if ($line_str =~/(S6F11\s+(\d+))/i)
# if ($line_str =~/\s+(\d+)\s+/i)
# {
# #S6F11	105299
# #say "found ceid $1 ";
# #$ceid{$1} = $2;
# if(exists $ceid{$1})
# {
# #say "found $1 is $ceid{$1}";
# my $newStr = "\tCEID:".$1." ".$ceid{$1}."\t";
# say "$newStr";
# $line_str =~s/\s+(\d+)\s+/$newStr/i;
# say "line_str=$line_str";
# }
# }
# }

my $tempfile = 'temp.txt';
open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile";
say OUTFILE @out;
close (OUTFILE) || die "ERROR! Can't close $tempfile";
