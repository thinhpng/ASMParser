################################################################################
# This script is written by Thinh Nguyen @ASM
# It's used to analyze the mes log for Samsung customer
# due to the issue reported via OneComm# 300130350
# It computes the wafer & recipe complete time to locate event delay or missing
################################################################################
#!/usr/bin/perl
use strict;
#use Spreadsheet::Read;
#use Spreadsheet::ParseExcel;
use Win32::File;
use File::Path;
use File::Find;
use warnings FATAL => 'all';
#use Date::Parse;
use POSIX qw{strftime};
use feature qw(say);
binmode STDIN, ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";
$SIG{'INT'} = 'Terminate'; #'IGNORE'; #'Terminate';
#local $\ = "\n";
#my $logDir = ".\\Logs\\"; #where the interested mes logs are stored to analyze
#my $datestring = gmtime();
#
#say "Start Tester... $datestring";
#my $one = " ";
#my $two = "  ";
#if ($one eq $two){
#    say"same";
#}else{
#    say"no";
#}

#my $libDir = ".\\Lib\\";
#my $vidFile = "";
#find(sub {
#    if ($_ =~ /Online SECS ID List.csv/ig) {
#        $vidFile = $_; #$File::Find::name; #$_;
#    }
#}, $libDir);
#if ($vidFile eq "") {
#    die "Missing the Online SECS ID List.csv file";
#}
#say "Resource file is $vidFile";
#open(INFILE, $libDir . $vidFile) || die "ERROR! Can't open $vidFile";
#my @vidBucket = <INFILE>;
#close(INFILE) || die "ERROR! Can't close $vidFile";
#
#my $lineNumber = 0;
#my $lastVidLineNumber = 0;
#my @update;
#my $temp = "";

#foreach my $line_str (@vidBucket) {
#    $lineNumber++;
#    #my $test = "line:".$lineNumber."->".$line_str;
#    #push(@update, $test);
#    if ($line_str =~/[^[:ascii:]]+/g){
#        say$line_str;
##        my $remark = $vidBucket[$lineNumber+1];
##        $remark =~s/[^[:ascii:]]+/=/g;
##        say$remark;
##        $remark = $vidBucket[$lineNumber+2];
##        $remark =~s/[^[:ascii:]]+/=/g;
##        say$remark;
##        $remark = $vidBucket[$lineNumber+3];
##        $remark =~s/[^[:ascii:]]+/=/g;
##        say$remark;
##        $remark = $vidBucket[$lineNumber+4];
##        $remark =~s/[^[:ascii:]]+/=/g;
##        say$remark;
#    }
#}

#foreach my $line_str (@vidBucket) {
#    if ($line_str eq "" || $line_str =~/^["|(]/i){
#        next;
#    }
#    $lineNumber++;
#
#    $line_str =~s/[^[:ascii:]]+/=/g;
#
#    if ($line_str =~/EquipmentType/i){
#        say $line_str;
#    }
#    if($line_str =~/^,.*?,SV,/i){
#        $lastVidLineNumber = $lineNumber;
#        chomp($line_str);
#        if ($temp ne ""){
#
#            if($temp =~/=/ig){
#                $line_str = $line_str.$temp."\n";
#                say"temp1 = $temp";
#            }
#            $temp = "";
#        }
#        push(@update, $line_str);
#        #say$line_str;
#        #say$temp;
#    }elsif($lineNumber == $lastVidLineNumber + 1){
#        chomp($line_str);
#        $lastVidLineNumber = $lineNumber;
#        $temp = $line_str.",";
#    }else{
#        say"temp2 = $temp";
#        push(@update, $line_str);
#        $temp = "";
#    }
#}
#
#my $tempfile = $logDir."tester1.txt";
#open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
#print OUTFILE @update;
#close (OUTFILE) || die "ERROR! Can't close $tempfile\n";


#foreach my $line_str (@update) {
#    $lineNumber++;
#
#    #$line_str =~s/[\r | \n]//gm;
#    chomp($line_str);
#
#    if($line_str =~/,(\d+),SV,/i){
#        #say "VID:$1";
#        #say$line_str;
#
#        if ($lastVidLineNumber){
#            my $diff = $lineNumber - $lastVidLineNumber;
#            #say"line difference = ", $diff;
#            if ($diff > 1){
#                for(my $i = 0; $i < $diff-1; $i++ ){
#                    my $previous = $vidBucket[$lastVidLineNumber + $i];
#                    #chomp($previous);
#                    if($previous =~/=| - /ig){
#                        say"$diff : traverse back: $i : $previous";
#                    }
#                }
#            }
#        }
#        $lastVidLineNumber = $lineNumber
#    }
#}

#my $book  = ReadData (".\\Lib\\ALD Online SECS ID List.xls");
#my $book = Spreadsheet::Read->new (".\\Lib\\ALD Online SECS ID List.xls");
#my $sheet = $book->sheet (1);
#my $cell  = $sheet->cell ("G15878");
##say $cell;
#my $rowCount = $sheet->maxrow;
##say "rowCount: $rowCount";
#my @out;
#
#for(my $i = 0; $i < $rowCount; $i++){
#    my $vidCell = $sheet->cell("C".$i);
#    my $vidClass = $sheet->cell("D".$i);
#    my $vidRemark = $sheet->cell("G".$i);
#
#    $vidRemark =~s/[^[:ascii:]]+//g;
#    chop($vidRemark);
#    chomp($vidRemark);
#    if ($vidClass eq "SV") {
#        say "VID: $vidCell remark: $vidRemark";
#        #push(@out, $vidCell);
#
#        if ($vidRemark =~ /[=| - ]/ig) {
#            say "VID: $vidCell remark: $vidRemark";
#            push(@out, $vidCell, " ", $vidRemark, "\n");
#        }else{
#            say "VID: $vidCell";
#        }
#    }
#}
#
#my $tempfile = $logDir."tester.txt";
#open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
#print OUTFILE @out;
#close (OUTFILE) || die "ERROR! Can't close $tempfile\n";

#foreach my $row (@rows){
#    say $row;
#}
#my $parser = Spreadsheet::ParseExcel->new();
#my $workbook = $parser->parse(".\\Lib\\ALD Online SECS ID List.xls");
#
#if (!defined $workbook) {
#    die $parser->error(), ".\n";
#}
#
#for my $worksheet ($workbook->worksheets()) {
#    my ($row_min, $row_max) = $worksheet->row_range();
#    for my $row ($row_min .. $row_max) {
#        my $svid = $worksheet->get_cell($row, 3);
#        next unless $svid->value() eq "SV";
#
#        my $vid = $worksheet->get_cell($row, 2)->value();
#        my $vidName = $worksheet->get_cell($row, 5)->value();
#        my $remark = $worksheet->get_cell($row, 6)->value();
#
#        $vidName =~ s/[\n]+//g;
#        $vidName =~ s/\s+//g;
#        #say "VID:  $vid $vidName";
#
#        $remark =~ s/[\n]+/!!!/g;
#
#        if ($remark =~ /(!!!.*)$/ig) {
#            #say "Remark: ", $remark;
#            #say "VID:  ",$vid." ".$vidName." ".$1;
#            my $t = $1;
#            if ($t !~ /!!!\d+.*?!!!/ig) {
#                #say"Not used: $t";
#                say $vid . " " . $vidName . " NA";
#            }
#            else {
#                $t =~ s/\s+//ig;
#                $t =~ s/!.*?(\d+)/ $1/ig;
#                $t =~ s/!!!.*?//ig;
##                $t =~ s/ 1$//ig;
#                $t =~ s/\d+.*?:ASMA\s//ig;
#                $t =~ s/\$FFFF.*$//ig;
##                $t =~ s/(\d+)[^[:ascii:]](\w+)/$1=$2/ig;
#                $t =~ s/(\d+)-(\w+)/$1=$2/ig;
#                $t =~ s/\d+-\d+\s0.*full/0=FULL/ig;
#                $t =~ s/\s?\d?\.+$//ig;
#                $t =~ s/\s/,/ig;
#                $t =~ s/^,/ /ig;
#                say $vid . " " . $vidName . $t;
#            }
#        }
#    }
#}
#my $libSource = ".\\Lib\\Ceids.txt"; #must have the ceid:name pairs library text file
#my $logDir = ".\\Logs\\"; #must have the saved cvs mes log as a text file
#say"libSource: $libSource, and logDir: $logDir";
#my @mesLogs;
#find (\&parseLogs,$logDir);
#@mesLogs = sort {$b cmp $a} @mesLogs;
#my @logData;
#foreach my $logFile (@mesLogs){
#    say"sorted : $logDir$logFile";
#    open (INFILE, "$logDir$logFile") || die "ERROR! Can't open $logFile\n";
#    my @bucket = <INFILE>;
#    close(INFILE) || die "ERROR! Can't close $logFile\n";
#    push(@logData,@bucket);
#}
#foreach my $line (@logData){
#    say$line;
#}
#
#my $tempfile = '.\\Logs\updatedCsv.txt';
#open (OUTFILE, ">$tempfile") || die "ERROR! Can't open $tempfile\n";
#print OUTFILE @logData;
#close (OUTFILE) || die "ERROR! Can't close $tempfile\n";
#
#sub parseLogs() {
#    my $currfname = $_ ; #$File::Find::name; #$_;
#    if($currfname =~/Meslog.ml_\d+(.csv)/i){
#        push(@mesLogs,$currfname);
#    }
#}

#sub mergeLogs(){
#    my $file = $_ ;
#    say"sorted : $file";
#    open (INFILE, "$file") || die "ERROR! Can't open $file\n";
#    my @bucket = <INFILE>;
#    close(INFILE) || die "ERROR! Can't close $file\n";
#    push(@logData,@bucket);
#}
#my $libSource = ".\\Lib\\Ceids.txt"; #must have the ceid:name pairs library text file
#my $logFile = ".\\Logs\\Meslog.ml_25.csv"; #must have the saved cvs mes log as a text file
#say"logFile: $logFile";
##We need to build CEID dictionary to transform the ids to names
#open (INFILE, "$logFile") || die "ERROR! Can't open $logFile\n";
#my @bucket = <INFILE>;
#close(INFILE) || die "ERROR! Can't close $logFile\n";
#foreach my $line (@bucket){
#    say$line;
#}

my $tempfile = ".\\Info\\EventXp.txt";
open (INFILE, "$tempfile") || die "ERROR! Can't open $tempfile\n";
my @bucket = <INFILE>;
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
my $line = "";

foreach my $line_str (@bucket){
    #$line_str;
    next if(($line_str =~ /^#/) || ($line_str =~ /^$/));
    #say "line_str=$line_str";
    chomp($line_str);
    if ($line_str =~/^[\t|\s]+E/i) {
        $eventBegin = 1;
        $reportBegin = 0;
        if ($line_str =~/\s+\$(\w+)\s+\d+\s+\#(.*)/i) { #Identify CEIDs
            $ceidHexVal = $1;
            $ceidDesc = $2;
            $ceidDecVal = hex($ceidHexVal);
            if ($ceidDesc =~/(.*)\s+\#Rev/i){
                $ceidDesc = $1;
            }
            $ceidDesc =~ s/\s|\#//g;
            #say "CEID : \$$ceidHexVal : $ceidDecVal : $ceidDesc : ";
            $line = "CEID : \$$ceidHexVal : $ceidDecVal : $ceidDesc : \n";
            push(@ceidLines, $line);
        }else{
            say $line_str;
        }
    }elsif ($line_str =~/^[\t|\s]+R/i) { #Identify RptIDs
        $eventBegin = 0;
        $reportBegin = 1;
        if ($line_str =~/\s+\$(\w+)\s+\d+\s+\#(.*)/i) {
            $reportdHexVal = $1;
            $reportDesc = $2;
            $reportdDecVal = hex($reportdHexVal);
            $line = "RPTID : \$$reportdHexVal : $reportdDecVal : $reportDesc : \n";
            push(@ceidLines, $line);
        }else{
            say $line_str;
        }
    }elsif ($eventBegin == 1 && $line_str =~/\s+\$(\w+)/i){ #Gather Event with related Reports
        $reportdHexVal = $1;
        if ($reportdHexVal =~/(.*?)\s+\#(.*)/i) {
            $reportdHexVal = $1;
            $reportdDecVal = hex($reportdHexVal);
            $line = "\tReportID : \$$reportdHexVal : $reportdDecVal : \n";
            push(@ceidLines, $line);
        }else{
            $reportdDecVal = hex($reportdHexVal);
            $line = "\tReportID : \$$reportdHexVal : $reportdDecVal : \n";
            push(@ceidLines, $line);
        }
    }elsif ($reportBegin == 1 && $line_str =~/\s+\$(\w+)\s+\#\_*(\w+)/i){ #Gather Vid with related Reports
        $vidHexVal = $1;
        $vidDesc = $2;
        $vidDecVal = hex($vidHexVal);
        $line = "\tVID : \$$vidHexVal : $vidDecVal : $vidDesc : \n";
        push(@ceidLines, $line);
    }
}

my $outFile = ".\\Info\\ConvertedEventXp.txt";
say("outFile: ", $outFile);
open(OUTFILE, ">:encoding(UTF-8)", $outFile) || die "ERROR! Can't open $outFile";
print OUTFILE ConvertedEventXpHeader(),@ceidLines;
close(OUTFILE) || die "ERROR! Can't close $outFile";

sub ConvertedEventXpHeader{
    my $header = '///////////////////////////////////////////////////////////////
// Scripted by THINH NGUYEN
// File: ConvertedEventXp.txt
// Version: 1.0
// Date: '.gmtime().'
//
// This file is to configure all ECIDs, RPTIDs, VIDs. WARNING!!!
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