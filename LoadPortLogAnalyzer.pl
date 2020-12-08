#!/usr/bin/perl
use strict;
use Win32::File;
use File::Path;
use File::Find;
use warnings FATAL => 'all';
use Date::Parse;
use POSIX qw{strftime};
use feature qw(say);

say"Start LoadPortLogAnalyzer...";
my $logDir = ".\\Logs\\"; #where the interested mes logs are stored to analyze

my @ReqHandlerInfo;
my %requestCodeInfo;
GetRequestCodeDefinition();
find (\&analyzeLog,$logDir);
my $tempfile = $logDir."ReqHandler.txt";
open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
print OUTFILE @ReqHandlerInfo;
close (OUTFILE) || die "ERROR! Can't close $tempfile\n";

sub analyzeLog{
    my $myfile = $_;
    if (-T $myfile && $myfile =~ /^LP\d+_.*\.csv/i) {
        say("myfile: ", $myfile);
        open(INFILE, "$myfile") || die "ERROR! Can't open $myfile\n";
        my @bucket = <INFILE>;
        close(INFILE) || die "ERROR! Can't close $myfile\n";
        foreach my $line_str (@bucket) {
            if ($line_str =~ /^(\[.*?\]),>>>>ReqHandler<.*?CTRL\[(\d+)\],REQ\[(\d+)\],P\[(\d+)\],ABT\[(\d+)\],ANS\[(\d+)\]/i){
                say("got: ", $line_str);
                my $time = $1;
                my $control = $2;
                my $req = $3;
                my $p = $4;
                my $abt = $5;
                my $ans = $6;

                my $requestInfo = $requestCodeInfo{$req} ;

                if($req == 23){
                    if($p == 0){
                        $p = " -> Manual Mode";
                    }else{
                        $p = " -> Auto Mode";
                    }
                    $requestInfo = $requestInfo . $p;
                }
                say("found: ", $1, " : ", $3, "-", $requestInfo);
                push(@ReqHandlerInfo, $3, "-", $requestInfo, "\n");
            }elsif ($line_str =~ /^(.*?)(\w+),\d+,\w+,\w+,(AMHSErr.*)/i){
                my $begin = $1;
                my $activity = $2;
                my $error = $3;
                if($activity ne "NONE"){
                    say("error: ", $begin, $activity, " : ", $error);
                    push(@ReqHandlerInfo, "\t", $begin, $activity, " : ", $error, "\n");
                }

            }elsif ($line_str =~ /^(.*?)(Unit:ERROR.*)/i){
                my $errorCode = $2;
                say("errorCode: ", $errorCode);
                push(@ReqHandlerInfo, "\t", $errorCode, "\n");
            }
        }
    }
}

sub GetRequestCodeDefinition {
    say("********** GetRequestCodeDefinition **********");
    $requestCodeInfo{1} = "Alarm Reset";
    $requestCodeInfo{2} = "Initialize LoadPort";
    $requestCodeInfo{3} = "Load Carrier";
    $requestCodeInfo{4} = "Unload Carrier";
    $requestCodeInfo{5} = "Cancel Loading Carrier";
    $requestCodeInfo{6} = "Cancel Unloading Carrier";
    $requestCodeInfo{7} = "MoveIn Carrier";
    $requestCodeInfo{8} = "MoveOut Carrier";
    $requestCodeInfo{9} = "Out or Eject Carrier";
    $requestCodeInfo{10} = "SlotMapping ";
    $requestCodeInfo{11} = "Re-SlotMapping";
    $requestCodeInfo{12} = "Clamp Carrier";
    $requestCodeInfo{13} = "Un-Clamp Carrier";
    $requestCodeInfo{14} = "Dock Carrier";
    $requestCodeInfo{15} = "Un-Dock Carrier";
    $requestCodeInfo{16} = "Open Carrier";
    $requestCodeInfo{17} = "Close Carrier";
    $requestCodeInfo{21} = "MMode Open Carrier";
    $requestCodeInfo{22} = "MMode Close Carrier";
    $requestCodeInfo{23} = "Change Access Mode";
    $requestCodeInfo{24} = "Change Service Mode";
    $requestCodeInfo{25} = "Change Host Mode";
    $requestCodeInfo{28} = "AMHS Recover";
    $requestCodeInfo{31} = "Reserve Load Port";
}


