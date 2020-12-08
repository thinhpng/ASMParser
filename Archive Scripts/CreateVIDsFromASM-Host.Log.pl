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
my $vidCount = 0;

foreach my $line_str (@bucket){
    #$line_str;
    next if(($line_str =~ /^#/) || ($line_str =~ /^$/));
    #say "line_str=$line_str";
    chomp($line_str);
    if ($line_str =~/<L\[3\/1\]/i) {
        $begin = 1;
        #say $line_str;
    }elsif ($begin > 0){
        if($begin == 1){
            if ($line_str =~/<U4\[1\/1\]\s(\d+)/i){
                $Vid = $1;
                #say "alarmID = $1";
            }
        }elsif ($begin == 2){
            if ($line_str =~/<A\[\d+\/1\]\s"(.*?)"/i){
                $Desc = $1;
                #say "alarmDesc = $1";
                #if($alarmID && $alarmDesc){
                #my $hexVid = hex($Vid);
                my $hexVid = Math::BigInt->new($Vid)->as_hex();
                $hexVid =~s/0x/\$0/;
                push(@VIDLines, "VID : $hexVid : $Vid : $Desc : \n");
                $vidCount++;
                print LOG "VID : $hexVid : $Vid : $Desc :\n";
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
    my $outFile = ".\\Info\\VIDsOnlyFromHostLog.txt";
    say("outFile: ", $outFile);
    open(OUTFILE, ">:encoding(UTF-8)", $outFile) || die "ERROR! Can't open $outFile";
    my @sortedVIDs = sort(@VIDLines);
    print OUTFILE VIDsHeader(),@sortedVIDs;
    close(OUTFILE) || die "ERROR! Can't close $outFile";
}

sub extractSECSMessageFromLog{
    say "-> extractSECSMessageFromLog";
    open (INFILE, "$tempfile") || die "ERROR! Can't open $tempfile\n";
    my @tempBucket = <INFILE>;
    close(INFILE) || die "ERROR! Can't close $tempfile\n";
    my $begin = 0;
    my $count = 0;
    foreach my $line_str (@tempBucket){
        next if(($line_str =~ /^#/) || ($line_str =~ /^$/));
        #say "line_str=$line_str";
        chomp($line_str);
        if ($line_str =~/^.*?\s+<(S1F[1|2]2).*/) {
            #Either S1F12 or S1F22
            print LOG "-> extractFromLog: $1 : ";
            $begin++;
            $vidCount = 0;
            #say $line_str;
            push(@bucket, $line_str);
        }elsif ($begin > 0){
            push(@bucket, $line_str);
            if ($line_str =~/^.*?>$/) {
                if($begin == 1){
                    next;
                }else{
                    say "last";
                    last;
                }
            }elsif ($count == 0 && $begin == 1 && $line_str =~/<L\[(\d+).*$/) {
                $count = $1;
                print LOG "Total : $count \n";
            }
        }elsif($softRevBlock == 0){
            if ($line_str =~/^.*?\s+<S1F13.*/) {
                #say "SoftRevBlock";
                $softRevBlock = 1;
            }
        }elsif($softRev eq "Unknown"){
            #say "SoftRevBlock = $softRevBlock";
            if ($line_str =~/^.*?\s+<A\[\d+\/\d+\]\s+"(\d+.*)".*/) {
                $softRev = $1;
                print LOG "Got SoftRev: $1 \n";
            }
        }
    }
}

sub VIDsHeader{
    my $header = '///////////////////////////////////////////////////////////////
// Scripted by THINH NGUYEN
// File: VIDsOnlyFromHostLog.txt
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