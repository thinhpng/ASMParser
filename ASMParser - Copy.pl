use strict;
use warnings FATAL => 'all';

use File::stat;
use Time::Local;
use Time::localtime;
use Win32::File;
use File::Path;
use File::Find;

print "INFO! Start Get_Info_F_File()\n";
my $myfile = "c:\\Scripts\\EventXp.txt";
my $data = "c:\\Scripts\\Meslog20-23.txt";
print "myfile is $myfile\n";
open (INFILE, "$myfile") || die "ERROR! Can't open $myfile\n";
my @bucket = <INFILE>;
close(INFILE) || die "ERROR! Can't close $myfile\n";
open (INFILE, "$data") || die "ERROR! Can't open $myfile\n";
my @dataBucket = <INFILE>;
close(INFILE) || die "ERROR! Can't close $myfile\n";
my $find_str = "";
my %ceid;
my $line = 0;
my @out;
foreach my $line_str (@bucket)
{
    #skip all the comments or blank lines
    next if(($line_str =~ /^#/) || ($line_str =~ /^$/));
    #print "line_str=$line_str\n";
    chomp($line_str);
    if ($line_str =~/^\s+E.*\$(\w+)\s+.*#(.*)$/i)
    {
        $line++;
        #print "$line found event $line_str\n";
        my $hex = hex("0x".$1);
        print "$1 = $hex $2\n";
        #my $out =
        push(@out,$hex.",".$2."\n");
        #	print "CEID: hex($hex)";

    }
}

# foreach $line_str (@dataBucket)
# {
# #skip all the comments or blank lines
# next if(($line_str =~ /^#/) || ($line_str =~ /^$/));
# #print "line_str=$line_str\n";
# #  chomp($line_str);
# #  $line_str =s/(S6F11\s+(\d+))/$1 $ceid{$2}/i);
# #  \s+(\d+)\s+
# #if ($line_str =~/(S6F11\s+(\d+))/i)
# if ($line_str =~/\s+(\d+)\s+/i)
# {
# #S6F11	105299
# #print "found ceid $1 \n";
# #$ceid{$1} = $2;
# if(exists $ceid{$1})
# {
# #print "found $1 is $ceid{$1}\n";
# my $newStr = "\tCEID:".$1." ".$ceid{$1}."\t";
# print "$newStr\n";
# $line_str =~s/\s+(\d+)\s+/$newStr/i;
# print "line_str=$line_str\n";
# }
# }
# }

my $tempfile = 'temp.txt';
open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
print OUTFILE @out;
close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
