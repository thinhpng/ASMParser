################################################################################
# This script is written by Thinh Nguyen @ASM
# It's used to analyze the mes log for Samsung customer
# due to the issue reported via OneComm# 300130350
# It computes the wafer & recipe complete time to locate event delay or missing
################################################################################
#!/usr/bin/perl
use strict;
use Math::BigInt;
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

my $tempfile = "C:\\Project\\UPC\\SystemFile\\CcuFiles\\Default\\EventXp.txt";
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
my %reportsFullInfo;

foreach my $line (@fileContent){
    #$line;
    next if(($line =~ /^#/) || ($line =~ /^$/));
    #say "line=$line";
    chomp($line);
    if ($line =~/^[\t|\s]+E/i) { # with E notation is Event line
        $eventBegin = 1;
        $reportBegin = 0;
        if ($line =~/\s+\$(\w+)\s+\d+\s+\#(.*)/i ||
            $line =~/\s+\$(\w+)\s+\d+\s+(.*)/i ) { #Identify CEIDs for ALD
            $ceidHexVal = $1;
            $ceidDesc = $2;
            $ceidDecVal = hex($ceidHexVal);
            if ($ceidDesc =~/(.*)\s+\#Rev/i){
                $ceidDesc = $1;
            }
            $ceidDesc =~ s/\s|\#//g;
            $ceidDesc =~ s/"//g; #remove surrounding quotes " of the name
            # if($ceidDesc =~/^[^"]/i ){
            #     $ceidDesc = '"'.$ceidDesc.'"';
            # }

            if ($ceidDecVal == 81937 || $ceidDecVal == 85009 || $ceidDecVal == 82961 || $ceidDecVal == 79633 #for LimitAI
                || $ceidDecVal == 83473 || $ceidDecVal == 85521 || $ceidDecVal == 80145 #for LimitDI
                || $ceidDecVal == 86289 || $ceidDecVal == 86545 #for WLLimitAI
                || $ceidDecVal == 87057 ) { #for WLLimitDI
                $ceidDecVal--;
            }elsif($ceidDesc =~ /\@$/){ #this is the CEID needs a formula to calculate the whole series
                next;
            }else{
                push(@ceidLines, "CEID : \$$ceidHexVal : $ceidDecVal : $ceidDesc : \n");
            }
            #say "CEID : \$$ceidHexVal : $ceidDecVal : $ceidDesc : ";
        }else{
            say $line;
        }
    }elsif ($line =~/^[\t|\s]+R/i) { #Identify RptIDs
        $eventBegin = 0;
        $reportBegin = 1;
        if ($line =~/\s+\$(\w+)\s+\d+\s+\#(.*)/i) {
            $reportdHexVal = $1;
            $reportDesc = $2;
            $reportdDecVal = hex($reportdHexVal);
            #say "RPTID : \$$reportdHexVal : $reportdDecVal : $reportDesc : ";
            # if($reportDesc =~/^[^"]/i ){
            #     $reportDesc = '"'.$reportDesc.'"'; #add surrounding quotes
            push(@ceidLines, "RPTID : \$$reportdHexVal : $reportdDecVal : $reportDesc : \n");
            $reportsFullInfo{$reportdDecVal} = $reportDesc;
        }else{
            say $line;
        }
    }elsif ($eventBegin == 1 && $line =~/\s+\$(\w+)/i){ #Gather Event with related Reports
        $reportdHexVal = $1;

        if ($reportdHexVal =~/(.*?)\s+\#(.*)/i) {
            $reportdHexVal = $1;
            $reportdDecVal = hex($reportdHexVal);
        }else{
            $reportdDecVal = hex($reportdHexVal);
        }

        if ($reportdDecVal == 16){
            next;
        }

        if ($ceidDecVal == 81936) { #Needs formula to calculate RCnLimitAIp(0-63)
            createCEIDseriesForRC(0, 63, "LimitAI", "first");
        }elsif($ceidDecVal == 85008){ #Needs formula to calculate RCnLimitAIp(64-95)
            createCEIDseriesForRC(64, 95, "LimitAI", "second");
        }elsif($ceidDecVal == 82960){ #Needs formula to calculate RCnLimitTIp(0-31)
            createCEIDseriesForRC(0, 31, "LimitTI", "first");
        }elsif($ceidDecVal == 79632) { #Needs formula to calculate RCnLimitTIp(32-63)
            createCEIDseriesForRC(32, 63, "LimitTI", "second");
        }elsif($ceidDecVal == 83472) { #Needs formula to calculate RCnLimitDIp(0-95)
            createCEIDseriesForRC(0, 95, "LimitDI", "first");
        }elsif($ceidDecVal == 85520) { #Needs formula to calculate RCnLimitDIp(96-143)
            createCEIDseriesForRC(96, 143, "LimitDI", "second");
        }elsif($ceidDecVal == 80144) { #Needs formula to calculate RCnLimitDIp(144-239)
            createCEIDseriesForRC(144, 239, "LimitDI", "second");
        }elsif($ceidDecVal == 86288) { #Needs formula to calculate WLLimitAIp(0-15)
            createCEIDseries(0, 15, "WLLimitAI");
        }elsif($ceidDecVal == 86544) { #Needs formula to calculate WLLimitSAIp(0-31)
            createCEIDseries(0, 31, "WLLimitSAI");
        }elsif($ceidDecVal == 87056) { #Needs formula to calculate WLLimitDIp(0-191)
            createCEIDseries(0, 191, "WLLimitDI");
        }elsif($ceidDesc =~ /\@$/){ #this is the CEID needs a formula to calculate the whole series
            pop @ceidLines; #throw away obsolete item due to the calculation made based on it already completed.
            next;
        }
        else{
            #say "\tRPID : \$$reportdHexVal : $reportdDecVal : ";
            push(@ceidLines, "\tRPID : \$$reportdHexVal : $reportdDecVal : \n");
        }
    }elsif ($reportBegin == 1 && $line =~/\s+\$(\w+)\s+\#\_*(\w+)/i){ #Gather Vid with related Reports
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

my $outFile = "C:\\Project\\UPC\\SystemFile\\CcuFiles\\Default\\ConvertedEventXp.txt";
say("outFile: ", $outFile);
open(OUTFILE, ">:encoding(UTF-8)", $outFile) || die "ERROR! Can't open $outFile";
print OUTFILE EventsHeader(),@ceidLines;
close(OUTFILE) || die "ERROR! Can't close $outFile";

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
            $hexVal =~ s/^0x/\$0/;
            #say "$id : $name";
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
        $hexVal =~ s/^0x/\$0/;
        #say "$id : $name";
        push(@ceidLines, "CEID : $hexVal : $id : $name : \n");
        push(@ceidLines, "\tRPID : \$$reportdHexVal : $reportdDecVal : \n");
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

sub EventsHeader{
    my $header = '///////////////////////////////////////////////////////////////
// Scripted by THINH NGUYEN
// File: ConvertedEventXp.txt
// Version: '.getVersion().'
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