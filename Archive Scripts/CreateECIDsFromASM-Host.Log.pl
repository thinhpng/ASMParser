################################################################################
# This script is written by Thinh Nguyen @ASM
# It's used to analyze the mes log for Samsung customer
# due to the issue reported via OneComm# 300130350
# It computes the wafer & recipe complete time to locate event delay or missing
################################################################################
#!/usr/bin/perl
use strict;
#use Spreadsheet::Read;
use Spreadsheet::ParseExcel;
use Win32::File;
use File::Path;
use File::Find;
use Math::BigInt;
use warnings FATAL => 'all';
use Date::Parse;
use POSIX qw{strftime};
use feature qw(say);
binmode STDIN, ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";
$SIG{'INT'} = 'Terminate'; #'IGNORE'; #'Terminate';

my @VIDLines;
my @bucket;
my $softRevBlock = 0;
my $softRev = "Unknown";

my $scriptLog = ".\\Info\\ScriptLog.txt";
open(LOG, ">:encoding(UTF-8)", $scriptLog) || die "ERROR! Can't open $scriptLog";

my $tempfile = ".\\Info\\ASM-Host.log";

if (!-e $tempfile) {
    die "$tempfile does not exist!";
}else {
    extractSECSMessageFromLog();
}

my $begin = 0;
my $Vid;
my $Desc;

foreach my $line_str (@bucket){
    #$line_str;
    next if(($line_str =~ /^#/) || ($line_str =~ /^$/));
    #say "line_str=$line_str";
    chomp($line_str);
    if ($line_str =~/<L\[6\/1\]/i) {
        $begin = 1;
        #say $line_str;
    }elsif ($begin > 0){
        if($begin == 1){
            if ($line_str =~/<U4\[1\/1\]\s(\d+)/i){ #The ID number
                $Vid = $1;
                #say "alarmID = $1";
            }
        }elsif ($begin == 2){
            if ($line_str =~/<A\[\d+\/1\]\s"(.*?)"/i){ #The description
                $Desc = $1;
                #say "alarmDesc = $1";
                #if($alarmID && $alarmDesc){
                my $hexVid = Math::BigInt->new($Vid)->as_hex();
                $hexVid =~s/0x/\$0/;
                #my $hexVid = hex($Vid);
                #say "ECID : \$$hexVid : $Vid : $Desc :";
                push(@VIDLines, "ECID : $hexVid : $Vid : $Desc : \n");
                print LOG "ECID : $hexVid : $Vid : $Desc :\n";
            }
        }elsif ($begin > 2){
            $begin = 0;
            next;
        }
        $begin++;
    }
}

createOutFile();
close(LOG);

sub createOutFile{
    my $outFile = ".\\Info\\ECIDsOnlyFromHostLog.txt";
    say("outFile: ", $outFile);
    open(OUTFILE, ">:encoding(UTF-8)", $outFile) || die "ERROR! Can't open $outFile";
    print OUTFILE VIDsHeader(),@VIDLines;
    close(OUTFILE) || die "ERROR! Can't close $outFile";
}

sub extractSECSMessageFromLog{
    say "-> extractSECSMessageFromLog";
    open (INFILE, "$tempfile") || die "ERROR! Can't open $tempfile\n";
    my @tempBucket = <INFILE>;
    close(INFILE) || die "ERROR! Can't close $tempfile\n";
    my $begin = 0;
    my $EcidCount = 0;
    my $TotalECID = 0;
    my $BlockItem = 0;
    foreach my $line_str (@tempBucket){
        next if(($line_str =~ /^#/) || ($line_str =~ /^$/));
        #say "line_str=$line_str";
        chomp($line_str);
        if ($line_str =~/^.*?\s+<(S2F30).*/) { #Response of S2F29
            say "-> extractFromLog: $1";
            print LOG "-> extractFromLog: $1 : ";
            $begin++;
            #say $line_str;
            push(@bucket, $line_str);
        }elsif ($begin > 0){
            #say $line_str;
            push(@bucket, $line_str);
            if($line_str =~/^.*?<L\[(\d+)\/2\]/){
                $TotalECID = $1;
                print LOG "Total : $TotalECID \n";
                say "There're $TotalECID ECIDs reported";
                $EcidCount = 0;
            }elsif($line_str =~/^.*?<L\[6\/1\]/) {  #Begins ECID block
                $EcidCount++;
            }elsif($EcidCount == $TotalECID){
                $BlockItem++;
                if ($BlockItem > 6){
                    say "last: $line_str";
                    last;
                }
            }
        }elsif($softRevBlock == 0){
            if ($line_str =~/^.*?\s+<S1F13.*/) {
                say "SoftRevBlock";
                $softRevBlock = 1;
            }
        }elsif($softRev eq "Unknown"){
            #say "SoftRevBlock = $softRevBlock";
            if ($line_str =~/^.*?\s+<A\[\d+\/\d+\]\s+"(\d+.*)".*/) {
                $softRev = $1;
                say "Got SoftRev: $1";
                print LOG "Got SoftRev: $1 \n";
            }
        }
    }
}

sub VIDsHeader{
    my $header = '///////////////////////////////////////////////////////////////
// Scripted by THINH NGUYEN
// File: ECIDsOnlyFromHostLog.txt
// SoftRev: '.$softRev.'
// Date: '.gmtime().'
//
// This file is to configure all VIDs. WARNING!!!
// DO NOT_EDIT without reading first.
// All comments should follow the format being used and seen.
// The last line should be an empty line.
//
';
    return $header;
}

#################################################################################
# Terminate sub
# input = a string or message
# Obj : It's an error handling sub to wrap up the mess before exiting the program
sub Terminate() {
    say "$_[0]\n" if ($_[0]);
    say "Unexpected termination\n" if (!$_[0]);
    if ($_[0] eq "INT") {
        die "$_[0]\n" if ($_[0]);
        exit(0) if (!$_[0]);
        #  die "Unexpected termination\n" if (!$_[0]);
    }
}