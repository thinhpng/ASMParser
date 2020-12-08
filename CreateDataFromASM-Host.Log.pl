################################################################################
# This script is written by Thinh Nguyen @ASM
# It's used to extract fundamental predefined data (VID, CEID, ECID)
# Those data come from the tool via S1F12, S1F22, S1F24, S2F30
################################################################################
#!/usr/bin/perl
use strict;
#use Spreadsheet::Read;
#use Spreadsheet::ParseExcel;
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

my @ECIDBUCKET;
my @CEIDBUCKET;
my @VIDBUCKET;
my $softRevBlock = 0;
my $softRev = "Unknown";
my $fileName = "UD";
my $reportdHexVal = 0;
my $reportdDecVal = 0;
my @ceidLines;
my $ceidDecVal = 0;
my %reportsFullInfo;

my $scriptLog = "C:\\ASM-Host\\Log\\ScriptLog.txt";
open(LOG, ">:encoding(UTF-8)", $scriptLog) || die "ERROR! Can't open $scriptLog";
createRptDict();
extractSECSMessageFromLog(); #Extract data from ASM-Host.log to fill @BUCKET
createOutFile("CEID");
createOutFile("VID");
createOutFile("ECID");
close(LOG);

sub createRptDict {
    say("->createRptDict()");
#    my $tempfile = ".\\Info\\EventXp.txt";
    my $tempfile =  "C:\\Project\\UPC\\SystemFile\\CcuFiles\\Default\\EventXp.txt";
    if (!-e $tempfile) {
        die "$tempfile does not exist!";
    }
    open (INFILE, "$tempfile") || die "ERROR! Can't open $tempfile\n";
    my @fileContent = <INFILE>;
    close(INFILE) || die "ERROR! Can't close $tempfile\n";

    my $eventBegin = 0;
    my $reportBegin = 0;
    my $ceidHexVal = 0;
    my $ceidDecVal = 0;
    my $ceidDesc = "";
    my $reportdHexVal = 0;
    my $reportdDecVal = 0;
    my $reportDesc = "";
    my $vidHexVal = 0;
    my $vidDecVal = 0;
    my $vidDesc = "";
    my @ceidLines;

    foreach my $line (@fileContent) {
        #$line;
        next if (($line =~ /^#/) || ($line =~ /^$/));
        #say "line=$line";
        chomp($line);
        if ($line =~ /^[\t|\s]+E/i) {
            # with E notation is Event line
            $eventBegin = 1;
            $reportBegin = 0;
            if ($line =~ /\s+\$(\w+)\s+\d+\s+\#(.*)/i ||
                $line =~ /\s+\$(\w+)\s+\d+\s+(.*)/i) {
                #Identify CEIDs for ALD
                $ceidHexVal = $1;
                $ceidDesc = $2;
                $ceidDecVal = hex($ceidHexVal);
                if ($ceidDesc =~ /(.*)\s+\#Rev/i) {
                    $ceidDesc = $1;
                }
                $ceidDesc =~ s/\s|\#//g;
                $ceidDesc =~ s/"//g; #remove surrounding quotes " of the name
                # if($ceidDesc =~/^[^"]/i ){
                #     $ceidDesc = '"'.$ceidDesc.'"';
                # }

                if ($ceidDecVal == 81937 || $ceidDecVal == 85009 || $ceidDecVal == 82961 || $ceidDecVal == 79633 #for LimitAI
                    || $ceidDecVal == 83473 || $ceidDecVal == 85521 || $ceidDecVal == 80145                      #for LimitDI
                    || $ceidDecVal == 86289 || $ceidDecVal == 86545                                              #for WLLimitAI
                    || $ceidDecVal == 87057) {                                                                   #for WLLimitDI
                    $ceidDecVal--;
                }elsif($ceidDesc =~ /\@$/){ #this is the CEID needs a formula to calculate the whole series
                    next;
                }else {
                    push(@ceidLines, "CEID : \$$ceidHexVal : $ceidDecVal : $ceidDesc : \n");
                }
                #say "CEID : \$$ceidHexVal : $ceidDecVal : $ceidDesc : ";
            }else {
                say $line;
            }
        }
        elsif ($line =~ /^[\t|\s]+R/i) { #Identify RptIDs
            $eventBegin = 0;
            $reportBegin = 1;
            if ($line =~ /\s+\$(\w+)\s+\d+\s+\#(.*)/i) {
                $reportdHexVal = $1;
                $reportDesc = $2;
                $reportdDecVal = hex($reportdHexVal);
                #say "RPTID : \$$reportdHexVal : $reportdDecVal : $reportDesc : ";
                # if($reportDesc =~/^[^"]/i ){
                #     $reportDesc = '"'.$reportDesc.'"'; #add surrounding quotes
                push(@ceidLines, "RPTID : \$$reportdHexVal : $reportdDecVal : $reportDesc : \n");
                $reportsFullInfo{$reportdDecVal} = $reportDesc;
            }else {
                say $line;
            }
        }
        elsif ($eventBegin == 1 && $line =~ /\s+\$(\w+)/i) {
            #Gather Event with related Reports
            $reportdHexVal = $1;

            if ($reportdHexVal =~ /(.*?)\s+\#(.*)/i) {
                $reportdHexVal = $1;
                $reportdDecVal = hex($reportdHexVal);
            }else {
                $reportdDecVal = hex($reportdHexVal);
            }

            if ($reportdDecVal == 16) {
                next;
            }

            if ($ceidDecVal == 81936) { #Needs formula to calculate RCnLimitAIp(0-63)
                createCEIDseriesForRC(0, 63, "LimitAI", "first");
            }elsif ($ceidDecVal == 85008) { #Needs formula to calculate RCnLimitAIp(64-95)
                createCEIDseriesForRC(64, 95, "LimitAI", "second");
            }elsif ($ceidDecVal == 82960) { #Needs formula to calculate RCnLimitTIp(0-31)
                createCEIDseriesForRC(0, 31, "LimitTI", "first");
            }elsif ($ceidDecVal == 79632) { #Needs formula to calculate RCnLimitTIp(32-63)
                createCEIDseriesForRC(32, 63, "LimitTI", "second");
            }elsif ($ceidDecVal == 83472) { #Needs formula to calculate RCnLimitDIp(0-95)
                createCEIDseriesForRC(0, 95, "LimitDI", "first");
            }elsif ($ceidDecVal == 85520) { #Needs formula to calculate RCnLimitDIp(96-143)
                createCEIDseriesForRC(96, 143, "LimitDI", "second");
            }elsif ($ceidDecVal == 80144) { #Needs formula to calculate RCnLimitDIp(144-239)
                createCEIDseriesForRC(144, 239, "LimitDI", "second");
            }elsif ($ceidDecVal == 86288) { #Needs formula to calculate WLLimitAIp(0-15)
                createCEIDseries(0, 15, "WLLimitAI");
            }elsif ($ceidDecVal == 86544) { #Needs formula to calculate WLLimitSAIp(0-31)
                createCEIDseries(0, 31, "WLLimitSAI");
            }elsif ($ceidDecVal == 87056) { #Needs formula to calculate WLLimitDIp(0-191)
                createCEIDseries(0, 191, "WLLimitDI");
            }elsif ($ceidDesc =~ /\@$/) { #this is the CEID needs a formula to calculate the whole series
                pop @ceidLines; #throw away obsolete item due to the calculation made based on it already completed.
                next;
            }else {
                #say "\tRPID : \$$reportdHexVal : $reportdDecVal : ";
                push(@ceidLines, "\tRPID : \$$reportdHexVal : $reportdDecVal : \n");
            }
        }
        elsif ($reportBegin == 1 && $line =~ /\s+\$(\w+)\s+\#\_*(\w+)/i) {
            #Gather Vid with related Reports
            $vidHexVal = $1;
            $vidDesc = $2;
            $vidDecVal = hex($vidHexVal);
            #say "\tVID : \$$vidHexVal : $vidDecVal : $vidDesc : ";
            # if($vidDesc =~/^[^"]/i ){
            #     $vidDesc = '"'.$vidDesc.'"'; #add surrounding quotes
            # }
            push(@ceidLines, "\tVID : \$$vidHexVal : $vidDecVal : $vidDesc : \n");
        }
    }

    for(my $i = 0; $i < $#ceidLines; $i++){ # update @ceidLines with report's description
        my $element = ($ceidLines[$i] =~ /(\t+RPID : .* : (\d+) : ).*/) ? $2 : "" ;
        if ($element ne ""){
            #say "element: $element";
            if(defined $reportsFullInfo{$element}){
                my $replacement = $reportsFullInfo{$element};
                #say "$replacement";
                $ceidLines[$i] = $1 . $replacement . " : \n";
            }
        }
    }
    $softRev = getVersion();
    my $outFile = "C:\\ASM-Host\\Log\\ConvertedEventXp.txt";
    say("outFile: ", $outFile);
    open(OUTFILE, ">:encoding(UTF-8)", $outFile) || die "ERROR! Can't open $outFile";
    print OUTFILE VIDsHeader(), @ceidLines;
    close(OUTFILE) || die "ERROR! Can't close $outFile";
}

sub createCEIDseriesForRC{
    say "->createCEIDseriesForRC($_[3]:$_[0]-$_[1] $_[2])";
    my $min = $_[0];
    my $max = $_[1];
    my $name = $_[2];
    my $order = $_[3];
    for (my $n = 1; $n <= 5; $n++) {
        for (my $p = $min; $p <= $max; $p++) {
            my $name = "RC$n" . $name . $p;
            my $id = $ceidDecVal + 16 * $p + $n;
            if ($order eq "second"){
                $id = $ceidDecVal + 16 * ($p-$min) + $n;
            }
            my $hexVal = Math::BigInt->new($id)->as_hex();
            #say "$id : $name";
            $hexVal =~ s/^0x/\$0/;
            push(@ceidLines, "CEID : $hexVal : $id : $name : \n");
            push(@ceidLines, "\tRPID : \$$reportdHexVal : $reportdDecVal : \n");
        }
    }
}

sub createCEIDseries{
    say "->createCEIDseries($_[0]-$_[1] $_[2])";
    my $min = $_[0];
    my $max = $_[1];
    my $name = $_[2];

    for (my $p = $min; $p <= $max; $p++) {
        my $name = $name . $p;
        my $id = $ceidDecVal + 16 * $p;
        my $hexVal = Math::BigInt->new($id)->as_hex();
        #say "$id : $name";
        $hexVal =~ s/^0x/\$0/;
        push(@ceidLines, "CEID : $hexVal : $id : $name : \n");
        push(@ceidLines, "\tRPID : \$$reportdHexVal : $reportdDecVal : \n");
    }
}

sub extractSECSMessageFromLog{
    say "->extractSECSMessageFromLog";
    my $tempfile = "C:\\ASM-Host\\Log\\ASM-Host.log";
    if (!-e $tempfile) {
        die "$tempfile does not exist!";
    }
    open (INFILE, "$tempfile") || die "ERROR! Can't open $tempfile\n";
    my @fileContent = <INFILE>;
    close(INFILE) || die "ERROR! Can't close $tempfile\n";

    my $type = "";
    my $secsCmd = "";
    my $nextDataListBlock = 0;
    my $TotalDataBlock = -1;
    my $index = -1;
    foreach my $line (@fileContent){
        $index++;
        next if(($line =~ /^#/) || ($line =~ /^$/));
        #say "line=$line";
        chomp($line);
        #Only interested either S1F12 or S1F22 or S1F24 or S2F30
        if ($line =~/^.*?\s+<(S1F[1|2]2).*/ || $line =~/^.*?\s+<(S1F24).*/ || $line =~/^.*?\s+<(S2F30).*/) {
            $secsCmd = $1;
            $nextDataListBlock = 0;
            print LOG "-> extractFromLog: $1";
            say "extractFromLog: $1";
            $TotalDataBlock = ($fileContent[$index+1] =~ /<L\[(\d+)\/\d+\]/) ? $1 : 0;
            #say "TotalDataBlock: $TotalDataBlock";
        }elsif($index > $nextDataListBlock && $line =~ /<L\[[3|6]\/1\]/ && $TotalDataBlock > 0) {
            #say "i $index: $line";
            $TotalDataBlock--; #keep track until the last record of the CEID list
            my $decVal = ($fileContent[$index + 1] =~ /<U4\[1\/1\] (\d+)>/) ? $1 : 0;
            my $hexVal = Math::BigInt->new($decVal)->as_hex();
            my $desc = ($fileContent[$index + 2] =~ /<A\[\d+\/1\] "(.*)"/) ? $1 : $decVal;
            $desc =~ s/\/\/.*$//;
            #say "$hexVal : $decVal : $desc :";
            $hexVal =~ s/^0x/\$0/;
            if($secsCmd =~ /S1F[1|2]2/){
                push(@VIDBUCKET, "VID : $hexVal : $decVal : $desc : \n");
            }elsif($secsCmd eq "S1F24"){ #CEID
                my $rptListIndex = $index + 3;
                if ($fileContent[$index + 3] =~ /"(\w+)">/i) { #rare case when desc is more than 1 line
                    $desc = $desc . $1;
                    $rptListIndex = $index + 4;
                }
                push(@CEIDBUCKET, "CEID : $hexVal : $decVal : $desc : \n");
                my $totalReport = ($fileContent[$rptListIndex] =~ /<L\[(\d+)\/\d+\]/) ? $1 : 0;
                for (my $i = 1; $i <= $totalReport; $i++) {
                    my $rpid = ($fileContent[$rptListIndex + $i] =~ /<U4\[1\/1\] (\d+)>/) ? $1 : 0;
                    $hexVal = Math::BigInt->new($rpid)->as_hex();
                    $hexVal =~ s/^0x/\$0/;
                    push(@CEIDBUCKET, "\tRPID : $hexVal : $rpid : $reportsFullInfo{$rpid} : \n")
                }
                #say "totalReport: $totalReport";
                $nextDataListBlock = $index + 5 + $totalReport;
                #say "nextDataListBlock: $nextDataListBlock";
            }elsif($secsCmd eq "S2F30"){ #ECID
                push(@ECIDBUCKET, "ECID : $hexVal : $decVal : $desc : \n");
                $nextDataListBlock = $index + 7;
                #say "$index : $line : $nextDataListBlock";
            }
        }elsif($softRevBlock == 0){
            if ($line =~/^.*?\s+<S1F13.*/) {
                #say "SoftRevBlock";
                $softRevBlock = 1;
            }
        }elsif($softRev eq "Unknown"){
            #say "SoftRevBlock = $softRevBlock";
            if ($line =~/^.*?\s+<A\[\d+\/\d+\]\s+"(\d+.*)".*/) {
                $softRev = $1;
                print LOG "Got SoftRev: $1 \n";
            }
        }
    }
}

sub createOutFile{
    say "->createOutFile(", $_[0], ")";
    my $type = $_[0];
    my @data = ();
    if($type eq "VID"){
        @data = sort @VIDBUCKET;
    }elsif($type eq "CEID"){
        @data = @CEIDBUCKET;
    }elsif($type eq "ECID"){
        @data = @ECIDBUCKET;
    }
    if(@data){
        $fileName = $type . "sFromHostLog.txt";
        my $outFile = "C:\\ASM-Host\\Log\\" . $fileName;
        say("outFile: ", $outFile);
        open(OUTFILE, ">:encoding(UTF-8)", $outFile) || die "ERROR! Can't open $outFile";
        print OUTFILE VIDsHeader(), @data;
    }
}

sub getVersion{
    #say "->getVersion()";
    my $dir = "C:\\Project";
    my $version = "";
    if (!-e $dir) {
        return ($version);
    }
    opendir DIR, $dir;
    my @dirs = readdir(DIR);
    close DIR;
    foreach (@dirs) {
        if ($_ =~/^Project_\w+_(.*)_/i) { # Project version specific name file
            $version = $1;
        }
    }
    return ($version);
}

sub VIDsHeader{
    my $header = '///////////////////////////////////////////////////////////////
// Scripted by THINH NGUYEN
// File: '.$fileName.'
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